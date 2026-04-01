import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../models/bible/book_model.dart';
import '../models/bible/chapter_model.dart';
import '../models/bible/reading_progress_model.dart';
import '../models/bible/verse_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class BibleRepository {
  /// Returns all 73 books of the Catholic Bible in canonical order.
  Future<Either<Failure, List<BookModel>>> getAllBooks();

  /// Returns a full chapter with all its verses.
  /// Results are cached locally with Hive for offline use.
  Future<Either<Failure, ChapterModel>> getChapter(
    String bookAbbrev,
    int chapterNum,
  );

  /// Returns the verse of the day. Falls back to local cache if offline.
  Future<Either<Failure, VerseModel>> getVerseOfDay();

  /// Searches for verses matching [query] (full-text search).
  Future<Either<Failure, List<VerseModel>>> searchVerses(String query);

  /// Records that [userId] has read up to [chapter]:[verse] in [bookAbbrev].
  Future<Either<Failure, void>> updateReadingProgress(
    String userId,
    String bookAbbrev,
    int chapter,
    int verse,
  );

  /// Returns all reading progress records for [userId].
  Future<Either<Failure, List<ReadingProgressModel>>> getReadingProgress(
    String userId,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

const _chapterBoxName = 'bible_chapters';
const _verseOfDayBoxName = 'verse_of_day';

class BibleRepositoryImpl implements BibleRepository {
  BibleRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  Box<Map>? _chapterBox;
  Box<Map>? _verseOfDayBox;

  Future<Box<Map>> _getChapterBox() async {
    _chapterBox ??= await Hive.openBox<Map>(_chapterBoxName);
    return _chapterBox!;
  }

  Future<Box<Map>> _getVerseOfDayBox() async {
    _verseOfDayBox ??= await Hive.openBox<Map>(_verseOfDayBoxName);
    return _verseOfDayBox!;
  }

  @override
  Future<Either<Failure, List<BookModel>>> getAllBooks() async {
    try {
      final data = await _client
          .from('bible_books')
          .select()
          .order('book_order');

      final books = (data as List<dynamic>)
          .map((b) => BookModel.fromJson(b as Map<String, dynamic>))
          .toList();
      return Right(books);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChapterModel>> getChapter(
    String bookAbbrev,
    int chapterNum,
  ) async {
    final cacheKey = '${bookAbbrev}_$chapterNum';

    // Try local Hive cache first.
    try {
      final box = await _getChapterBox();
      final cached = box.get(cacheKey);
      if (cached != null) {
        final chapterJson = Map<String, dynamic>.from(cached);
        return Right(ChapterModel.fromJson(chapterJson));
      }
    } catch (_) {
      // Cache miss or corruption; continue to network fetch.
    }

    // Fetch from Supabase.
    try {
      final data = await _client
          .from('bible_verses')
          .select()
          .eq('book_abbrev', bookAbbrev)
          .eq('chapter_number', chapterNum)
          .order('verse_number');

      if ((data as List).isEmpty) {
        return Left(
          NotFoundFailure(
            message: 'Chapter $bookAbbrev $chapterNum not found.',
          ),
        );
      }

      final verses = data
          .map((v) => VerseModel.fromJson(v as Map<String, dynamic>))
          .toList();

      // Derive book name from first verse.
      final bookName = verses.first.bookName;

      final chapter = ChapterModel(
        bookAbbrev: bookAbbrev,
        bookName: bookName,
        chapterNumber: chapterNum,
        verses: verses,
      );

      // Persist to Hive for offline use.
      try {
        final box = await _getChapterBox();
        await box.put(cacheKey, chapter.toJson());
      } catch (_) {
        // Non-fatal caching failure.
      }

      return Right(chapter);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      // Try to return stale cache as last resort.
      try {
        final box = await _getChapterBox();
        final stale = box.get(cacheKey);
        if (stale != null) {
          return Right(ChapterModel.fromJson(Map<String, dynamic>.from(stale)));
        }
      } catch (_) {}
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VerseModel>> getVerseOfDay() async {
    final today = _todayKey();

    // Check Hive cache.
    try {
      final box = await _getVerseOfDayBox();
      final cached = box.get(today);
      if (cached != null) {
        return Right(VerseModel.fromJson(Map<String, dynamic>.from(cached)));
      }
    } catch (_) {}

    // Fetch from edge function (deterministic daily verse selection).
    try {
      final result = await _client.functions.invoke('verse-of-day');

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Verse of day returned no data.'),
        );
      }

      final verse = VerseModel.fromJson(result.data as Map<String, dynamic>);

      // Cache today's verse.
      try {
        final box = await _getVerseOfDayBox();
        await box.put(today, verse.toJson());
      } catch (_) {}

      return Right(verse);
    } on FunctionException catch (e) {
      // Fall back to any cached verse if network fails.
      try {
        final box = await _getVerseOfDayBox();
        if (box.isNotEmpty) {
          final fallback = box.values.last;
          return Right(VerseModel.fromJson(Map<String, dynamic>.from(fallback)));
        }
      } catch (_) {}
      return Left(
        NetworkFailure(
          message: e.details?.toString() ?? 'Could not fetch verse of day.',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VerseModel>>> searchVerses(
    String query,
  ) async {
    try {
      final data = await _client
          .from('bible_verses')
          .select()
          .textSearch('text', query, config: 'english')
          .limit(50);

      final verses = (data as List<dynamic>)
          .map((v) => VerseModel.fromJson(v as Map<String, dynamic>))
          .toList();
      return Right(verses);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateReadingProgress(
    String userId,
    String bookAbbrev,
    int chapter,
    int verse,
  ) async {
    try {
      await _client.functions.invoke(
        'update-reading-progress',
        body: {
          'user_id': userId,
          'book_abbrev': bookAbbrev,
          'chapter': chapter,
          'verse': verse,
        },
      );
      return const Right(null);
    } on FunctionException catch (e) {
      return Left(
        GameFailure(
          message: e.details?.toString() ?? 'Update reading progress failed.',
        ),
      );
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReadingProgressModel>>> getReadingProgress(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('bible_reading_progress')
          .select()
          .eq('user_id', userId);

      final progress = (data as List<dynamic>)
          .map((p) =>
              ReadingProgressModel.fromJson(p as Map<String, dynamic>))
          .toList();
      return Right(progress);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
