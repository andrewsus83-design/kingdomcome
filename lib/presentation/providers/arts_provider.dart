import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'package:kingdomcome/data/models/arts/artwork_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'arts_provider.g.dart';

final _supabase = Supabase.instance.client;
const _uuid = Uuid();

const String _aiGatewayBase = String.fromEnvironment(
  'AI_GATEWAY_URL',
  defaultValue: 'https://kingdom-come-ai-gateway.andrewsus83.workers.dev',
);

@riverpod
class ArtsNotifier extends _$ArtsNotifier {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60),
  ));

  @override
  Future<List<ArtworkModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return _fetchArtworks(user.id);
  }

  /// Saves a manually drawn artwork to Supabase.
  Future<ArtworkModel> saveArtwork({
    required ArtworkType type,
    required Map<String, dynamic> canvasData,
    String? title,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');

    final now = DateTime.now().toIso8601String();
    final artworkTitle = title ??
        '${type.displayName} — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    final data = await _supabase
        .from('artworks')
        .insert({
          'user_id': user.id,
          'title': artworkTitle,
          'artwork_type': type.databaseKey,
          'canvas_data': canvasData,
          'is_displayed_in_kingdom': false,
          'holy_points_earned': _holyPointsForArtwork(type),
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    final artwork = ArtworkModel.fromJson(data);

    // Add to local state
    final current = state.valueOrNull ?? [];
    state = AsyncData([artwork, ...current]);

    return artwork;
  }

  /// Generates an AI artwork via Flux Schnell through the Cloudflare Worker.
  ///
  /// Returns the saved [ArtworkModel] on success.
  Future<ArtworkModel> generateAiArtwork({
    required String prompt,
    required ArtworkType type,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw StateError('No active session');

    // Enrich prompt with art-type style guidance
    final styledPrompt = _enrichPrompt(prompt, type);

    final response = await _dio.post(
      '$_aiGatewayBase/generate-image',
      options: Options(headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      }),
      data: {
        'prompt': styledPrompt,
        'artworkType': type.name,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final imageUrl = responseData['url'] as String? ??
        (responseData['images'] as List?)?.first?['url'] as String? ?? '';

    // Save AI-generated artwork to Supabase
    final now = DateTime.now().toIso8601String();
    final data = await _supabase
        .from('artworks')
        .insert({
          'user_id': user.id,
          'title': 'AI ${type.displayName} — ${prompt.substring(0, prompt.length.clamp(0, 30))}',
          'artwork_type': type.databaseKey,
          'canvas_data': {'ai_generated': true, 'prompt': prompt},
          'thumbnail_url': imageUrl,
          'is_displayed_in_kingdom': false,
          'holy_points_earned': _holyPointsForArtwork(type),
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    final artwork = ArtworkModel.fromJson(data);
    final current = state.valueOrNull ?? [];
    state = AsyncData([artwork, ...current]);
    return artwork;
  }

  /// Toggles an artwork's display in the kingdom at [location].
  Future<void> displayInKingdom(
    String artworkId, {
    Map<String, dynamic>? location,
  }) async {
    final current = state.valueOrNull ?? [];
    final artwork = current.firstWhere((a) => a.id == artworkId);

    final nowDisplayed = !artwork.isDisplayedInKingdom;

    await _supabase.from('artworks').update({
      'is_displayed_in_kingdom': nowDisplayed,
      if (location != null) 'kingdom_location': location,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', artworkId);

    // Optimistic update
    state = AsyncData(
      current
          .map((a) => a.id == artworkId
              ? a.copyWith(
                  isDisplayedInKingdom: nowDisplayed,
                  kingdomLocation: location ?? a.kingdomLocation,
                )
              : a)
          .toList(),
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<ArtworkModel>> _fetchArtworks(String userId) async {
    final data = await _supabase
        .from('artworks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50) as List<dynamic>;

    return data
        .map((e) => ArtworkModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _enrichPrompt(String prompt, ArtworkType type) {
    switch (type) {
      case ArtworkType.stainedGlass:
        return '$prompt, stained glass window, vibrant colors, leading, Gothic cathedral style, Catholic sacred art';
      case ArtworkType.manuscript:
        return '$prompt, illuminated manuscript, gold leaf, Celtic knotwork borders, medieval calligraphy, parchment background';
      case ArtworkType.mosaic:
        return '$prompt, Byzantine mosaic, tesserae tiles, gold background, Ravenna style, Catholic sacred art';
      case ArtworkType.banner:
        return '$prompt, medieval heraldic banner, Catholic symbols, cross, fleur-de-lis, rich fabric texture';
    }
  }

  int _holyPointsForArtwork(ArtworkType type) {
    switch (type) {
      case ArtworkType.stainedGlass:
        return 25;
      case ArtworkType.manuscript:
        return 30;
      case ArtworkType.mosaic:
        return 20;
      case ArtworkType.banner:
        return 15;
    }
  }
}
