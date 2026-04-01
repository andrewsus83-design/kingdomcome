enum BuildingType {
  chapel,
  scriptorium,
  monastery,
  garden,
  bellTower,
  cathedral,
  school,
  workshop,
  parishHall,
  oratory;

  /// The snake_case value stored in the Supabase `building_type` enum.
  String get databaseValue {
    switch (this) {
      case BuildingType.bellTower:
        return 'bell_tower';
      case BuildingType.parishHall:
        return 'parish_hall';
      default:
        return name;
    }
  }

  /// Parse from the database snake_case value.
  static BuildingType fromDatabaseValue(String value) {
    switch (value) {
      case 'bell_tower':
        return BuildingType.bellTower;
      case 'parish_hall':
        return BuildingType.parishHall;
      default:
        return BuildingType.values.firstWhere(
          (t) => t.name == value,
          orElse: () => BuildingType.chapel,
        );
    }
  }
}

extension BuildingTypeX on BuildingType {
  String get displayName {
    switch (this) {
      case BuildingType.chapel:
        return 'Chapel';
      case BuildingType.scriptorium:
        return 'Scriptorium';
      case BuildingType.monastery:
        return 'Monastery';
      case BuildingType.garden:
        return 'Garden';
      case BuildingType.bellTower:
        return 'Bell Tower';
      case BuildingType.cathedral:
        return 'Cathedral';
      case BuildingType.school:
        return 'School';
      case BuildingType.workshop:
        return 'Workshop';
      case BuildingType.parishHall:
        return 'Parish Hall';
      case BuildingType.oratory:
        return 'Oratory';
    }
  }

  String get emoji {
    switch (this) {
      case BuildingType.chapel:
        return '⛪';
      case BuildingType.scriptorium:
        return '📜';
      case BuildingType.monastery:
        return '🏯';
      case BuildingType.garden:
        return '🌿';
      case BuildingType.bellTower:
        return '🔔';
      case BuildingType.cathedral:
        return '🕌';
      case BuildingType.school:
        return '🏫';
      case BuildingType.workshop:
        return '🔨';
      case BuildingType.parishHall:
        return '🏛️';
      case BuildingType.oratory:
        return '📿';
    }
  }

  String get description {
    switch (this) {
      case BuildingType.chapel:
        return 'A place of prayer and daily Mass. Unlocks prayer quests and rosary challenges.';
      case BuildingType.scriptorium:
        return 'Where sacred texts are copied and studied. Unlocks Bible story chapters and reading quests.';
      case BuildingType.monastery:
        return 'A place of contemplation. Unlocks Saints and enables saint ability activation.';
      case BuildingType.garden:
        return 'A peaceful garden for reflection. Unlocks nature-themed quests and Ordinary Time bonuses.';
      case BuildingType.bellTower:
        return 'Ring the bells to call the faithful. Enables daily reminders and streak bonuses.';
      case BuildingType.cathedral:
        return 'The heart of your kingdom. Unlocks Mass quests and liturgical events.';
      case BuildingType.school:
        return 'Educate citizens in the faith. Unlocks quizzes and catechism challenges.';
      case BuildingType.workshop:
        return 'A creative space for sacred art. Unlocks stained glass, manuscript, and banner creation.';
      case BuildingType.parishHall:
        return 'A gathering place. Unlocks parish leaderboards and community challenges.';
      case BuildingType.oratory:
        return 'A place of personal devotion. Unlocks examination of conscience and confession quests.';
    }
  }

  String get unlocksFeature {
    switch (this) {
      case BuildingType.chapel:
        return 'feature_prayer_quests';
      case BuildingType.scriptorium:
        return 'feature_bible_stories';
      case BuildingType.monastery:
        return 'feature_saints';
      case BuildingType.garden:
        return 'feature_nature_quests';
      case BuildingType.bellTower:
        return 'feature_streak_bonuses';
      case BuildingType.cathedral:
        return 'feature_mass_quests';
      case BuildingType.school:
        return 'feature_quizzes';
      case BuildingType.workshop:
        return 'feature_arts_crafts';
      case BuildingType.parishHall:
        return 'feature_parish_leaderboard';
      case BuildingType.oratory:
        return 'feature_confession_quests';
    }
  }
}
