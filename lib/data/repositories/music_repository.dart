import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failure.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class MusicRepository {
  /// Narrates a Bible verse using ElevenLabs TTS and returns the audio URL.
  ///
  /// [saintVoiceId] is optional; when provided the Worker maps it to the
  /// corresponding ElevenLabs voice ID for that saint narrator.
  Future<Either<Failure, String>> narrateVerse(
    String verseText,
    String verseRef, {
    String? saintVoiceId,
  });

  /// Narrates text with a specific saint's ElevenLabs voice and returns the
  /// audio URL.
  Future<Either<Failure, String>> narrateWithSaintVoice(
    String saintName,
    String text,
  );

  /// Fetches (or generates via MusicGen) ambient music for the given
  /// liturgical [season]. Returns the audio URL.
  Future<Either<Failure, String>> getSeasonAmbient(String season);

  /// Generates a short MusicGen victory jingle for the given quest [category].
  /// Returns the audio URL.
  Future<Either<Failure, String>> getVictoryJingle(String questCategory);
}

// ── Model returned by audio endpoints ────────────────────────────────────────

/// Represents a narration or music track returned by the Cloudflare Worker.
class AudioTrack {
  final String audioUrl;
  final double durationSeconds;
  final String? title;

  const AudioTrack({
    required this.audioUrl,
    required this.durationSeconds,
    this.title,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      audioUrl: json['audioUrl'] as String? ?? '',
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String?,
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

  // ── narrateVerse ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> narrateVerse(
    String verseText,
    String verseRef, {
    String? saintVoiceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/audio/narrate-verse',
        data: {
          'text': verseText,
          'verseRef': verseRef,
          if (saintVoiceId != null) 'saintNarratorId': saintVoiceId,
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
          message: 'Verse narration returned no data.',
          serviceName: 'ElevenLabs',
        ));
      }

      final url = data['audioUrl'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No audio URL returned from verse narration.',
          serviceName: 'ElevenLabs',
        ));
      }

      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'ElevenLabs'));
    }
  }

  // ── narrateWithSaintVoice ────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> narrateWithSaintVoice(
    String saintName,
    String text,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/audio/saint-voice',
        data: {
          'saintName': saintName,
          'text': text,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _generateTimeout,
          sendTimeout: _sendTimeout,
        ),
      );

      final url = response.data?['audioUrl'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No audio URL returned for saint voice narration.',
          serviceName: 'ElevenLabs',
        ));
      }
      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'ElevenLabs'));
    }
  }

  // ── getSeasonAmbient ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> getSeasonAmbient(String season) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/music/ambient',
        data: {
          'season': season,
          'duration': 60,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _generateTimeout,
          sendTimeout: _sendTimeout,
        ),
      );

      final url = response.data?['audioUrl'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No ambient audio URL returned.',
          serviceName: 'MusicGen',
        ));
      }
      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'MusicGen'));
    }
  }

  // ── getVictoryJingle ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> getVictoryJingle(
    String questCategory,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/music/victory-jingle',
        data: {'questCategory': questCategory},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _generateTimeout,
          sendTimeout: _sendTimeout,
        ),
      );

      final url = response.data?['audioUrl'] as String?;
      if (url == null || url.isEmpty) {
        return const Left(AiServiceFailure(
          message: 'No victory jingle URL returned.',
          serviceName: 'MusicGen',
        ));
      }
      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(AiServiceFailure(message: e.toString(), serviceName: 'MusicGen'));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure(
        message: 'Audio generation timed out. Please try again.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NoConnectionFailure();
    }
    if (e.response?.statusCode == 429) {
      return const AiServiceFailure(
        message: 'Too many audio requests. Please wait a moment.',
        serviceName: 'ElevenLabs',
        code: 'rate_limited',
      );
    }
    if (e.response?.statusCode == 502) {
      return const AiServiceFailure(
        message: 'Audio service is temporarily unavailable.',
        serviceName: 'ElevenLabs',
      );
    }
    final errMsg = e.response?.data?.toString() ?? e.message ?? e.toString();
    return AiServiceFailure(message: errMsg, serviceName: 'ElevenLabs');
  }
}
