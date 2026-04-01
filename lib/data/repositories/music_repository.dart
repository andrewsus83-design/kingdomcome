import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failure.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class MusicRepository {
  /// Generates a hymn based on a Bible verse and returns the audio URL.
  Future<Either<Failure, String>> generateVerseHymn(
    String verseText,
    String verseRef,
    String style, // 'gregorian' | 'hymn' | 'contemporary' | 'kids'
  );

  /// Generates a feast day song for a saint and returns the audio URL.
  Future<Either<Failure, String>> generateFeastDaySong(
    String saintName,
    String patronage,
    String era,
  );

  /// Fetches (or generates) ambient music for the given liturgical [season].
  /// Returns the audio URL.
  Future<Either<Failure, String>> getSeasonAmbient(String season);

  /// Generates a short victory jingle for the given quest [category].
  /// Returns the audio URL.
  Future<Either<Failure, String>> generateQuestVictoryJingle(String questCategory);
}

// ── Model returned by Suno endpoints ─────────────────────────────────────────

class SunoTrack {
  final String audioUrl;
  final String videoUrl;
  final String title;
  final double durationSeconds;

  const SunoTrack({
    required this.audioUrl,
    required this.videoUrl,
    required this.title,
    required this.durationSeconds,
  });

  factory SunoTrack.fromJson(Map<String, dynamic> json) {
    return SunoTrack(
      audioUrl: json['audio_url'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ── Implementation ────────────────────────────────────────────────────────────

class MusicRepositoryImpl implements MusicRepository {
  MusicRepositoryImpl({
    required Dio dio,
    required String cloudflareWorkerUrl,
  })  : _dio = dio,
        _workerUrl = cloudflareWorkerUrl;

  final Dio _dio;
  final String _workerUrl;

  static const Duration _generateTimeout = Duration(seconds: 120);
  static const Duration _sendTimeout = Duration(seconds: 30);

  // ── generateVerseHymn ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> generateVerseHymn(
    String verseText,
    String verseRef,
    String style,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/music/generate-from-verse',
        data: {
          'verseText': verseText,
          'verseRef': verseRef,
          'style': style,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _generateTimeout,
          sendTimeout: _sendTimeout,
        ),
      );

      final data = response.data;
      if (data == null) {
        return const Left(AiServiceFailure(
          message: 'Hymn generation returned no data.',
          serviceName: 'Suno',
        ));
      }

      final url = data['audio_url'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No audio URL returned from hymn generation.',
          serviceName: 'Suno',
        ));
      }

      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'Suno'));
    }
  }

  // ── generateFeastDaySong ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> generateFeastDaySong(
    String saintName,
    String patronage,
    String era,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/music/feast-day-song',
        data: {
          'saintName': saintName,
          'patronage': patronage,
          'era': era,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _generateTimeout,
          sendTimeout: _sendTimeout,
        ),
      );

      final url = response.data?['audio_url'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No audio URL returned for feast day song.',
          serviceName: 'Suno',
        ));
      }
      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'Suno'));
    }
  }

  // ── getSeasonAmbient ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> getSeasonAmbient(String season) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_workerUrl/music/kingdom-ambient/$season',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _generateTimeout,
          sendTimeout: _sendTimeout,
        ),
      );

      final url = response.data?['audio_url'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No ambient audio URL returned.',
          serviceName: 'Suno',
        ));
      }
      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'Suno'));
    }
  }

  // ── generateQuestVictoryJingle ───────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> generateQuestVictoryJingle(
    String questCategory,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/music/quest-victory/$questCategory',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _generateTimeout,
          sendTimeout: _sendTimeout,
        ),
      );

      final url = response.data?['audio_url'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No victory jingle URL returned.',
          serviceName: 'Suno',
        ));
      }
      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'Suno'));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure(
        message: 'Music generation timed out. Please try again.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NoConnectionFailure();
    }
    if (e.response?.statusCode == 429) {
      return const AiServiceFailure(
        message: 'Too many music requests. Please wait a moment.',
        serviceName: 'Suno',
        code: 'rate_limited',
      );
    }
    if (e.response?.statusCode == 502) {
      return const AiServiceFailure(
        message: 'Music generation service is temporarily unavailable.',
        serviceName: 'Suno',
      );
    }
    final errMsg = e.response?.data?.toString() ?? e.message ?? e.toString();
    return AiServiceFailure(message: errMsg, serviceName: 'Suno');
  }
}
