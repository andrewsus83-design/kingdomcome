import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failure.dart';
import '../models/arts/artwork_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class ArtsRepository {
  /// Saves a new artwork created by [userId] with the provided [canvasData].
  Future<Either<Failure, ArtworkModel>> saveArtwork(
    String userId,
    ArtworkType artworkType,
    Map<String, dynamic> canvasData,
  );

  /// Returns all artworks created by [userId], newest first.
  Future<Either<Failure, List<ArtworkModel>>> getUserArtworks(String userId);

  /// Generates AI artwork via Flux (Modal.com) proxied through Cloudflare Worker.
  /// [prompt] describes the desired sacred artwork.
  /// Returns the URL of the generated image.
  Future<Either<Failure, String>> generateAiArtwork(
    String userId,
    String prompt,
    ArtworkType artworkType,
  );

  /// Displays [artworkId] in the kingdom at [location].
  /// [location] contains grid coordinates and any display metadata.
  Future<Either<Failure, void>> displayInKingdom(
    String artworkId,
    Map<String, dynamic> location,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ArtsRepositoryImpl implements ArtsRepository {
  ArtsRepositoryImpl({
    required SupabaseClient supabaseClient,
    required Dio dio,
    required String cloudflareWorkerUrl,
  })  : _client = supabaseClient,
        _dio = dio,
        _workerUrl = cloudflareWorkerUrl;

  final SupabaseClient _client;
  final Dio _dio;
  final String _workerUrl;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, ArtworkModel>> saveArtwork(
    String userId,
    ArtworkType artworkType,
    Map<String, dynamic> canvasData,
  ) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toUtc().toIso8601String();

      final inserted = await _client
          .from('artworks')
          .insert({
            'id': id,
            'user_id': userId,
            'title': 'My ${artworkType.displayName}',
            'artwork_type': artworkType.name,
            'canvas_data': canvasData,
            'is_displayed_in_kingdom': false,
            'holy_points_earned': 0,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return Right(ArtworkModel.fromJson(inserted));
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArtworkModel>>> getUserArtworks(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('artworks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final artworks = (data as List<dynamic>)
          .map((a) => ArtworkModel.fromJson(a as Map<String, dynamic>))
          .toList();
      return Right(artworks);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateAiArtwork(
    String userId,
    String prompt,
    ArtworkType artworkType,
  ) async {
    try {
      // Cloudflare Worker proxies the request to Flux via Modal.com.
      // It also enforces content filtering for age-appropriate imagery.
      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/generate-artwork',
        data: {
          'user_id': userId,
          'prompt': prompt,
          'artwork_type': artworkType.name,
          'style': _styleForType(artworkType),
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      if (data == null) {
        return const Left(
          GameFailure(message: 'AI artwork generation returned no data.'),
        );
      }

      final imageUrl = data['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        return const Left(
          GameFailure(
            message: 'AI artwork generation: no image URL in response.',
          ),
        );
      }

      return Right(imageUrl);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Left(TimeoutFailure());
      }
      if (e.type == DioExceptionType.connectionError) {
        return const Left(NoConnectionFailure());
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 429) {
        return const Left(
          GameFailure(
            message: 'Too many artwork requests. Please wait a moment.',
            code: 'rate_limited',
          ),
        );
      }
      final errMsg = e.response?.data?.toString() ?? e.message ?? e.toString();
      return Left(GameFailure(message: 'Artwork generation error: $errMsg'));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> displayInKingdom(
    String artworkId,
    Map<String, dynamic> location,
  ) async {
    try {
      await _client
          .from('artworks')
          .update({
            'is_displayed_in_kingdom': true,
            'kingdom_location': location,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', artworkId);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _styleForType(ArtworkType type) {
    switch (type) {
      case ArtworkType.stainedGlass:
        return 'medieval stained glass window, vibrant colors, lead lines, '
            'Catholic cathedral, sacred art';
      case ArtworkType.manuscript:
        return 'illuminated manuscript, gold leaf, Celtic knotwork borders, '
            'medieval parchment, ornate calligraphy';
      case ArtworkType.mosaic:
        return 'Byzantine mosaic, gold tesserae, sacred iconography, '
            'rich jewel tones, flat stylized figures';
      case ArtworkType.banner:
        return 'medieval heraldic banner, bold colors, religious symbolism, '
            'Catholic emblems, flat graphic style';
    }
  }
}
