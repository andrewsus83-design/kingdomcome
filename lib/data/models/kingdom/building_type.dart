enum BuildingType {
  cathedral,
  monastery,
  school,
  artStudio,
  confessional,
  bellTower,
  townSquare,
  scriptorium,
  shrine,
  fortressWall,
}

extension BuildingTypeX on BuildingType {
  String get displayName {
    switch (this) {
      case BuildingType.cathedral:
        return 'Cathedral';
      case BuildingType.monastery:
        return 'Monastery';
      case BuildingType.school:
        return 'School';
      case BuildingType.artStudio:
        return 'Art Studio';
      case BuildingType.confessional:
        return 'Confessional';
      case BuildingType.bellTower:
        return 'Bell Tower';
      case BuildingType.townSquare:
        return 'Town Square';
      case BuildingType.scriptorium:
        return 'Scriptorium';
      case BuildingType.shrine:
        return 'Shrine';
      case BuildingType.fortressWall:
        return 'Fortress Wall';
    }
  }

  String get iconPath {
    switch (this) {
      case BuildingType.cathedral:
        return 'assets/images/buildings/cathedral.png';
      case BuildingType.monastery:
        return 'assets/images/buildings/monastery.png';
      case BuildingType.school:
        return 'assets/images/buildings/school.png';
      case BuildingType.artStudio:
        return 'assets/images/buildings/art_studio.png';
      case BuildingType.confessional:
        return 'assets/images/buildings/confessional.png';
      case BuildingType.bellTower:
        return 'assets/images/buildings/bell_tower.png';
      case BuildingType.townSquare:
        return 'assets/images/buildings/town_square.png';
      case BuildingType.scriptorium:
        return 'assets/images/buildings/scriptorium.png';
      case BuildingType.shrine:
        return 'assets/images/buildings/shrine.png';
      case BuildingType.fortressWall:
        return 'assets/images/buildings/fortress_wall.png';
    }
  }

  String get description {
    switch (this) {
      case BuildingType.cathedral:
        return 'The heart of your kingdom. Unlocks Mass quests and liturgical events. '
            'Each upgrade increases Holy Point rewards for all prayer activities.';
      case BuildingType.monastery:
        return 'A place of contemplation and prayer. Unlocks Saints and enables '
            'saint ability activation. Higher levels unlock rarer Saints.';
      case BuildingType.school:
        return 'Educate your citizens in the faith. Unlocks quizzes and catechism '
            'challenges. Improves Faith Coin rewards for learning activities.';
      case BuildingType.artStudio:
        return 'A creative space for sacred art. Unlocks stained glass, manuscript, '
            'mosaic, and banner creation. Artwork can be displayed in your kingdom.';
      case BuildingType.confessional:
        return 'A sacred space for reconciliation. Unlocks confession and examination '
            'of conscience quests. Provides Grace bonuses on completion.';
      case BuildingType.bellTower:
        return 'Ring the bells to call the faithful. Enables daily reminder '
            'notifications and streak multiplier bonuses for consistent activity.';
      case BuildingType.townSquare:
        return 'A gathering place for the community. Unlocks parish leaderboards, '
            'social sharing features, and community challenges.';
      case BuildingType.scriptorium:
        return 'Where sacred texts are copied and studied. Unlocks Bible story '
            'chapters and in-depth reading quests with enhanced Holy Point rewards.';
      case BuildingType.shrine:
        return 'A place of personal devotion. Unlocks rosary and litany quests. '
            'Provides Blessings bonuses and activates feast-day special events.';
      case BuildingType.fortressWall:
        return 'Protects your kingdom of faith. Unlocks fasting and spiritual '
            'warfare quests. Provides streak shield bonuses to protect streaks.';
    }
  }

  /// Returns the feature identifier unlocked by this building type.
  String get unlocksFeature {
    switch (this) {
      case BuildingType.cathedral:
        return 'feature_mass_quests';
      case BuildingType.monastery:
        return 'feature_saints';
      case BuildingType.school:
        return 'feature_quizzes';
      case BuildingType.artStudio:
        return 'feature_arts_crafts';
      case BuildingType.confessional:
        return 'feature_confession_quests';
      case BuildingType.bellTower:
        return 'feature_streak_bonuses';
      case BuildingType.townSquare:
        return 'feature_parish_leaderboard';
      case BuildingType.scriptorium:
        return 'feature_bible_stories';
      case BuildingType.shrine:
        return 'feature_rosary_quests';
      case BuildingType.fortressWall:
        return 'feature_streak_shield';
    }
  }
}
