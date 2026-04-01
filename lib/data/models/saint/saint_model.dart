import 'package:equatable/equatable.dart';

class SaintAbility extends Equatable {
  final String name;
  final String description;

  /// e.g. "holyPointsMultiplier", "faithCoinsMultiplier", "streakShield",
  /// "questXpBonus", "graceCostReduction"
  final String abilityType;

  /// Multiplicative bonus (e.g. 1.5 = +50%).
  final double multiplier;

  /// How long the ability remains active after activation.
  final int durationHours;

  /// Grace required to activate the ability.
  final int graceCost;

  const SaintAbility({
    required this.name,
    required this.description,
    required this.abilityType,
    required this.multiplier,
    required this.durationHours,
    required this.graceCost,
  });

  factory SaintAbility.fromJson(Map<String, dynamic> json) {
    return SaintAbility(
      name: json['name'] as String,
      description: json['description'] as String,
      abilityType: json['ability_type'] as String,
      multiplier: (json['multiplier'] as num).toDouble(),
      durationHours: json['duration_hours'] as int,
      graceCost: json['grace_cost'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'ability_type': abilityType,
      'multiplier': multiplier,
      'duration_hours': durationHours,
      'grace_cost': graceCost,
    };
  }

  @override
  List<Object?> get props => [
        name,
        description,
        abilityType,
        multiplier,
        durationHours,
        graceCost,
      ];
}

class SaintModel extends Equatable {
  final String id;
  final String name;
  final String latinName;

  /// ISO date string "MM-DD" representing the feast day (e.g. "10-04").
  final String feastDay;

  final String patronage;
  final String shortBio;
  final String longBio;

  /// Historical era (e.g. "Early Church", "Medieval", "Modern").
  final String era;

  /// Country or region of origin.
  final String origin;

  final String portraitAssetPath;
  final String cardAssetPath;

  /// Rarity tier: "common", "uncommon", "rare", "epic", "legendary".
  final String rarity;

  /// Minimum monastery level required to unlock this Saint.
  final int requiredMonasteryLevel;

  /// Holy Points cost to unlock this Saint.
  final int holyPointsCost;

  /// A short prayer associated with this Saint.
  final String prayerText;

  /// IDs of Bible verses related to this Saint's life or patronage.
  final List<String> relatedVerseIds;

  final List<SaintAbility> abilities;
  final bool isActive;
  final int sortOrder;

  const SaintModel({
    required this.id,
    required this.name,
    required this.latinName,
    required this.feastDay,
    required this.patronage,
    required this.shortBio,
    required this.longBio,
    required this.era,
    required this.origin,
    required this.portraitAssetPath,
    required this.cardAssetPath,
    required this.rarity,
    required this.requiredMonasteryLevel,
    required this.holyPointsCost,
    required this.prayerText,
    this.relatedVerseIds = const [],
    this.abilities = const [],
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory SaintModel.fromJson(Map<String, dynamic> json) {
    // DB column names differ from original model — support both
    final patronageRaw = json['patronage'];
    final patronageStr = patronageRaw is List
        ? (patronageRaw as List<dynamic>).join(', ')
        : patronageRaw as String? ?? '';

    final abilitiesRaw = json['abilities'];
    List<SaintAbility> abilities = [];
    if (abilitiesRaw is Map<String, dynamic>) {
      // DB stores abilities as {passive: {...}, active: {...}} — wrap as list
      try {
        if (abilitiesRaw['passive'] != null) {
          abilities.add(SaintAbility.fromJson({
            'name': 'Passive',
            'description': '',
            'ability_type': abilitiesRaw['passive']['type'] as String? ?? 'multiplier',
            'multiplier': (abilitiesRaw['passive']['value'] as num?)?.toDouble() ?? 1.0,
            'duration_hours': 0,
            'grace_cost': 0,
          }));
        }
        if (abilitiesRaw['active'] != null) {
          abilities.add(SaintAbility.fromJson({
            'name': 'Active',
            'description': '',
            'ability_type': abilitiesRaw['active']['type'] as String? ?? 'multiplier',
            'multiplier': (abilitiesRaw['active']['value'] as num?)?.toDouble() ?? 1.0,
            'duration_hours': abilitiesRaw['active']['duration_hours'] as int? ?? 4,
            'grace_cost': 50,
          }));
        }
      } catch (_) {}
    } else if (abilitiesRaw is List) {
      abilities = (abilitiesRaw as List<dynamic>)
          .map((a) => SaintAbility.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return SaintModel(
      id: json['id'] as String,
      name: json['display_name'] as String? ?? json['name'] as String? ?? '',
      latinName: json['latin_name'] as String? ?? json['slug'] as String? ?? '',
      feastDay: json['feast_day'] as String? ?? '',
      patronage: patronageStr,
      shortBio: json['short_bio'] as String? ?? '',
      longBio: json['full_bio'] as String? ?? json['long_bio'] as String? ?? '',
      era: json['era'] as String? ?? '',
      origin: json['origin'] as String? ?? json['era'] as String? ?? '',
      portraitAssetPath: json['avatar_url'] as String? ??
          json['portrait_asset_path'] as String? ?? '',
      cardAssetPath: json['card_art_url'] as String? ??
          json['card_asset_path'] as String? ?? '',
      rarity: json['rarity'] as String? ?? 'common',
      requiredMonasteryLevel: json['required_monastery_level'] as int? ?? 1,
      holyPointsCost: json['unlock_cost_holy_points'] as int? ??
          json['holy_points_cost'] as int? ?? 0,
      prayerText: json['prayer_text'] as String? ?? '',
      relatedVerseIds: (json['related_verse_ids'] as List<dynamic>?)
              ?.map((v) => v as String)
              .toList() ??
          [],
      abilities: abilities,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latin_name': latinName,
      'feast_day': feastDay,
      'patronage': patronage,
      'short_bio': shortBio,
      'long_bio': longBio,
      'era': era,
      'origin': origin,
      'portrait_asset_path': portraitAssetPath,
      'card_asset_path': cardAssetPath,
      'rarity': rarity,
      'required_monastery_level': requiredMonasteryLevel,
      'holy_points_cost': holyPointsCost,
      'prayer_text': prayerText,
      'related_verse_ids': relatedVerseIds,
      'abilities': abilities.map((a) => a.toJson()).toList(),
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  SaintModel copyWith({
    String? id,
    String? name,
    String? latinName,
    String? feastDay,
    String? patronage,
    String? shortBio,
    String? longBio,
    String? era,
    String? origin,
    String? portraitAssetPath,
    String? cardAssetPath,
    String? rarity,
    int? requiredMonasteryLevel,
    int? holyPointsCost,
    String? prayerText,
    List<String>? relatedVerseIds,
    List<SaintAbility>? abilities,
    bool? isActive,
    int? sortOrder,
  }) {
    return SaintModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latinName: latinName ?? this.latinName,
      feastDay: feastDay ?? this.feastDay,
      patronage: patronage ?? this.patronage,
      shortBio: shortBio ?? this.shortBio,
      longBio: longBio ?? this.longBio,
      era: era ?? this.era,
      origin: origin ?? this.origin,
      portraitAssetPath: portraitAssetPath ?? this.portraitAssetPath,
      cardAssetPath: cardAssetPath ?? this.cardAssetPath,
      rarity: rarity ?? this.rarity,
      requiredMonasteryLevel:
          requiredMonasteryLevel ?? this.requiredMonasteryLevel,
      holyPointsCost: holyPointsCost ?? this.holyPointsCost,
      prayerText: prayerText ?? this.prayerText,
      relatedVerseIds: relatedVerseIds ?? this.relatedVerseIds,
      abilities: abilities ?? this.abilities,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        latinName,
        feastDay,
        patronage,
        shortBio,
        longBio,
        era,
        origin,
        portraitAssetPath,
        cardAssetPath,
        rarity,
        requiredMonasteryLevel,
        holyPointsCost,
        prayerText,
        relatedVerseIds,
        abilities,
        isActive,
        sortOrder,
      ];
}
