import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';

import 'package:kingdomcome/data/models/bible/book_model.dart';
import 'package:kingdomcome/data/models/bible/chapter_model.dart';
import 'package:kingdomcome/data/models/bible/verse_model.dart';
import 'package:kingdomcome/data/models/bible/reading_progress_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'bible_provider.g.dart';

final _supabase = Supabase.instance.client;

// Bible API Worker base URL — injected via dart-define in production
const String _bibleApiBase = String.fromEnvironment(
  'BIBLE_API_URL',
  defaultValue: 'https://kingdom-come-bible-api.andrewsus83.workers.dev',
);

final _dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: _bibleApiBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
});

// ── Book list ─────────────────────────────────────────────────────────────────

@riverpod
class BibleNotifier extends _$BibleNotifier {
  @override
  Future<List<BookModel>> build() async {
    final data = await _supabase
        .from('bible_books')
        .select()
        .order('book_order') as List<dynamic>;

    return data
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Chapter ───────────────────────────────────────────────────────────────────

@riverpod
Future<ChapterModel> chapter(Ref ref, String bookAbbrev, int chapterNum) async {
  final dio = ref.read(_dioProvider);

  try {
    final response = await dio.get('/chapter/$bookAbbrev/$chapterNum');
    final data = response.data as Map<String, dynamic>;

    // Worker returns {book_abbrev, chapter, verses:[{id, book, book_abbrev, chapter, verse, text}]}
    final verses = (data['verses'] as List<dynamic>)
        .map((v) => VerseModel.fromJson(_normalizeVerseJson(v as Map<String, dynamic>)))
        .toList();

    return ChapterModel(
      bookAbbrev: bookAbbrev.toUpperCase(),
      bookName: verses.isNotEmpty ? verses.first.bookName : bookAbbrev,
      chapterNumber: chapterNum,
      verses: verses,
    );
  } on DioException catch (e) {
    throw Exception('Failed to load chapter: ${e.message}');
  }
}

// ── Verse of day ──────────────────────────────────────────────────────────────

@riverpod
Future<VerseModel> verseOfDay(Ref ref) async {
  final dio = ref.read(_dioProvider);

  try {
    final response = await dio.get('/verse-of-day');
    final data = response.data as Map<String, dynamic>;
    final verseJson = data['verse'] as Map<String, dynamic>;
    return VerseModel.fromJson(_normalizeVerseJson(verseJson));
  } on DioException catch (e) {
    throw Exception('Failed to load verse of the day: ${e.message}');
  }
}

// ── Reading progress ──────────────────────────────────────────────────────────

@riverpod
class ReadingProgressNotifier extends _$ReadingProgressNotifier {
  @override
  Future<List<ReadingProgressModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final data = await _supabase
        .from('user_reading_progress')
        .select()
        .eq('user_id', user.id)
        .order('last_read_at', ascending: false) as List<dynamic>;

    return data
        .map((e) => ReadingProgressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates reading progress for a given book and chapter/verse.
  Future<void> updateProgress(
    String bookAbbrev,
    int chapter,
    int verse,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final now = DateTime.now().toIso8601String();
    await _supabase.from('user_reading_progress').upsert({
      'user_id': user.id,
      'book_abbrev': bookAbbrev,
      'last_chapter_read': chapter,
      'last_verse_read': verse,
      'last_read_at': now,
    }, onConflict: 'user_id,book_abbrev');

    // Update local state
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((p) => p.bookAbbrev == bookAbbrev);
    final updated = ReadingProgressModel(
      userId: user.id,
      bookAbbrev: bookAbbrev,
      lastChapterRead: chapter,
      lastVerseRead: verse,
      lastReadAt: DateTime.now(),
      completionPercent: idx >= 0 ? current[idx].completionPercent : 0.0,
    );

    final newList = [...current];
    if (idx >= 0) {
      newList[idx] = updated;
    } else {
      newList.insert(0, updated);
    }
    state = AsyncData(newList);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Normalises the Worker JSON shape into the [VerseModel] JSON shape.
Map<String, dynamic> _normalizeVerseJson(Map<String, dynamic> json) {
  return {
    'id': json['id'] ?? '',
    'book_abbrev': json['book_abbrev'] ?? json['book'] ?? '',
    'book_name': json['book'] ?? json['book_abbrev'] ?? '',
    'chapter_number': json['chapter'] ?? 0,
    'verse_number': json['verse'] ?? 0,
    'text': json['text'] ?? '',
    'thematic_tags': json['thematic_tags'] ?? [],
    'is_verse_of_day_candidate': json['is_verse_of_day_candidate'] ?? false,
  };
}
