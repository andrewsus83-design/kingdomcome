import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../data/models/bible/verse_model.dart';
import '../../../data/repositories/bible_repository.dart';

/// Fetches the verse of the day from [BibleRepository].
///
/// The repository handles caching internally (Hive). This use case adds a
/// secondary fallback: if the repository returns a network failure and the
/// Hive cache is unavailable, it returns a hardcoded default verse so the
/// UI is never left without content.
class GetVerseOfDayUseCase {
  const GetVerseOfDayUseCase({
    required BibleRepository bibleRepository,
  }) : _bibleRepository = bibleRepository;

  final BibleRepository _bibleRepository;

  /// A small set of hardcoded fallback verses used when the device is fully
  /// offline and no cache exists yet.
  static const List<Map<String, dynamic>> _fallbackVerses = [
    {
      'id': 'JN.3.16',
      'book_abbrev': 'JN',
      'book_name': 'John',
      'chapter_number': 3,
      'verse_number': 16,
      'text':
          'For God so loved the world that he gave his only Son, so that '
          'everyone who believes in him might not perish but might have eternal life.',
      'thematic_tags': ['love', 'salvation', 'faith'],
      'is_verse_of_day_candidate': true,
    },
    {
      'id': 'PS.23.1',
      'book_abbrev': 'PS',
      'book_name': 'Psalms',
      'chapter_number': 23,
      'verse_number': 1,
      'text': 'The Lord is my shepherd; there is nothing I lack.',
      'thematic_tags': ['trust', 'providence'],
      'is_verse_of_day_candidate': true,
    },
    {
      'id': 'PHIL.4.13',
      'book_abbrev': 'PHIL',
      'book_name': 'Philippians',
      'chapter_number': 4,
      'verse_number': 13,
      'text': 'I can do all things through him who strengthens me.',
      'thematic_tags': ['strength', 'faith', 'courage'],
      'is_verse_of_day_candidate': true,
    },
  ];

  Future<Either<Failure, VerseModel>> call() async {
    final result = await _bibleRepository.getVerseOfDay();

    return result.fold(
      (failure) {
        // Network / server failure: attempt local Hive fallback.
        return _tryLocalFallback(failure);
      },
      (verse) => Right(verse),
    );
  }

  Either<Failure, VerseModel> _tryLocalFallback(Failure originalFailure) {
    try {
      // Try reading from Hive directly as a secondary fallback if the
      // repository's own cache attempt failed for some reason.
      if (Hive.isBoxOpen('verse_of_day')) {
        final box = Hive.box<Map>('verse_of_day');
        if (box.isNotEmpty) {
          final cached = box.values.last;
          return Right(
            VerseModel.fromJson(Map<String, dynamic>.from(cached)),
          );
        }
      }
    } catch (_) {
      // Ignore cache errors and fall through.
    }

    // Final fallback: a deterministic verse chosen by day-of-year.
    final dayOfYear = _dayOfYear(DateTime.now());
    final fallbackJson = _fallbackVerses[dayOfYear % _fallbackVerses.length];
    return Right(VerseModel.fromJson(fallbackJson));
  }

  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays;
  }
}
