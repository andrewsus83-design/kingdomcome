import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:kingdomcome/data/models/kingdom/kingdom_model.dart';
import 'package:kingdomcome/data/models/kingdom/building_model.dart';
import 'package:kingdomcome/data/models/kingdom/building_type.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'kingdom_provider.g.dart';

final _supabase = Supabase.instance.client;
const _uuid = Uuid();

@riverpod
class KingdomNotifier extends _$KingdomNotifier {
  @override
  Future<KingdomModel> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');
    return _fetchKingdom(user.id);
  }

  /// Places a new building on the kingdom grid at [x], [y].
  Future<void> buildStructure(BuildingType type, int x, int y) async {
    final kingdom = state.valueOrNull;
    if (kingdom == null) return;

    // Optimistic: add a placeholder building under construction
    final tempId = _uuid.v4();
    final constructionDuration = _constructionDuration(type, 1);
    final completesAt = DateTime.now().add(constructionDuration);

    final newBuilding = BuildingModel(
      id: tempId,
      kingdomId: kingdom.id,
      type: type,
      level: 1,
      gridX: x,
      gridY: y,
      isUnderConstruction: true,
      constructionCompletesAt: completesAt,
    );

    state = AsyncData(
      kingdom.copyWith(buildings: [...kingdom.buildings, newBuilding]),
    );

    try {
      final result = await _supabase.rpc('start_construction', params: {
        'p_kingdom_id': kingdom.id,
        'p_building_type': type.name,
        'p_grid_x': x,
        'p_grid_y': y,
      }) as Map<String, dynamic>;

      // Replace temp building with server-confirmed one
      final confirmedBuilding = BuildingModel.fromJson(result);
      final updatedBuildings = kingdom.buildings
          .where((b) => b.id != tempId)
          .toList()
        ..add(confirmedBuilding);

      state = AsyncData(kingdom.copyWith(buildings: updatedBuildings));
    } catch (e) {
      // Rollback on error
      state = AsyncData(
        kingdom.copyWith(
          buildings: kingdom.buildings.where((b) => b.id != tempId).toList(),
        ),
      );
      rethrow;
    }
  }

  /// Upgrades [buildingId] to the next level.
  Future<void> upgradeBuilding(String buildingId) async {
    final kingdom = state.valueOrNull;
    if (kingdom == null) return;

    final building = kingdom.buildings.firstWhere((b) => b.id == buildingId);
    final nextLevel = building.level + 1;
    if (nextLevel > 5) return;

    final constructionDuration = _constructionDuration(building.type, nextLevel);
    final completesAt = DateTime.now().add(constructionDuration);

    // Optimistic update
    final updatedBuilding = building.copyWith(
      isUnderConstruction: true,
      constructionCompletesAt: completesAt,
    );
    final optimisticBuildings = kingdom.buildings
        .map((b) => b.id == buildingId ? updatedBuilding : b)
        .toList();
    state = AsyncData(kingdom.copyWith(buildings: optimisticBuildings));

    try {
      await _supabase.rpc('start_construction', params: {
        'p_building_id': buildingId,
        'p_upgrade': true,
      });
    } catch (e) {
      // Rollback
      final revertedBuildings = kingdom.buildings
          .map((b) => b.id == buildingId ? building : b)
          .toList();
      state = AsyncData(kingdom.copyWith(buildings: revertedBuildings));
      rethrow;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<KingdomModel> _fetchKingdom(String userId) async {
    final data = await _supabase
        .from('kingdoms')
        .select('*, kingdom_buildings(*)')
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) {
      // Create a new kingdom for first-time players
      return _createKingdom(userId);
    }
    return KingdomModel.fromJson(data);
  }

  Future<KingdomModel> _createKingdom(String userId) async {
    final data = await _supabase
        .from('kingdoms')
        .insert({
          'user_id': userId,
          'name': 'My Kingdom',
          'level': 1,
          'land_size': 25,
          'founded_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return KingdomModel.fromJson({...data, 'buildings': []});
  }

  Duration _constructionDuration(BuildingType type, int level) {
    // Base: 30 min * level, capped at 8 hours
    final minutes = (30 * level).clamp(30, 480);
    return Duration(minutes: minutes);
  }
}
