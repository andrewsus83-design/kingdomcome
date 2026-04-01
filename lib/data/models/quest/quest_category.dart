enum QuestCategory {
  dailyPrayer,
  rosary,
  bibleReading,
  goodDeed,
  massAttendance,
  confession,
  fasting,
  volunteering,
  quiz,
  artsCrafts,
  liturgicalEvent,
  socialShare,
  community,
}

enum QuestDifficulty {
  easy,
  medium,
  hard,
  legendary,
}

enum QuestVerificationType {
  honorSystem,
  timedSession,
  quizCompletion,
  photoUpload,
  streakRequired,
}

enum QuestRepeatFrequency {
  daily,
  weekly,
  monthly,
  once,
}

extension QuestCategoryX on QuestCategory {
  String get displayName {
    switch (this) {
      case QuestCategory.dailyPrayer:
        return 'Daily Prayer';
      case QuestCategory.rosary:
        return 'Rosary';
      case QuestCategory.bibleReading:
        return 'Bible Reading';
      case QuestCategory.goodDeed:
        return 'Good Deed';
      case QuestCategory.massAttendance:
        return 'Mass Attendance';
      case QuestCategory.confession:
        return 'Confession';
      case QuestCategory.fasting:
        return 'Fasting';
      case QuestCategory.volunteering:
        return 'Volunteering';
      case QuestCategory.quiz:
        return 'Quiz';
      case QuestCategory.artsCrafts:
        return 'Arts & Crafts';
      case QuestCategory.liturgicalEvent:
        return 'Liturgical Event';
      case QuestCategory.socialShare:
        return 'Social Share';
      case QuestCategory.community:
        return 'Community';
    }
  }

  String get databaseKey {
    switch (this) {
      case QuestCategory.dailyPrayer:
        return 'prayer';
      case QuestCategory.rosary:
        return 'rosary';
      case QuestCategory.bibleReading:
        return 'bible_reading';
      case QuestCategory.goodDeed:
        return 'good_deed';
      case QuestCategory.massAttendance:
        return 'mass_attendance';
      case QuestCategory.confession:
        return 'confession';
      case QuestCategory.quiz:
        return 'quiz';
      case QuestCategory.artsCrafts:
        return 'arts_crafts';
      case QuestCategory.liturgicalEvent:
        return 'liturgical_event';
      case QuestCategory.community:
        return 'community';
      // No DB equivalent — map to closest
      case QuestCategory.fasting:
        return 'prayer';
      case QuestCategory.volunteering:
        return 'good_deed';
      case QuestCategory.socialShare:
        return 'community';
    }
  }

  static QuestCategory fromDatabaseValue(String value) {
    switch (value) {
      case 'prayer':
        return QuestCategory.dailyPrayer;
      case 'rosary':
        return QuestCategory.rosary;
      case 'bible_reading':
        return QuestCategory.bibleReading;
      case 'good_deed':
        return QuestCategory.goodDeed;
      case 'mass_attendance':
        return QuestCategory.massAttendance;
      case 'confession':
        return QuestCategory.confession;
      case 'quiz':
        return QuestCategory.quiz;
      case 'arts_crafts':
        return QuestCategory.artsCrafts;
      case 'liturgical_event':
        return QuestCategory.liturgicalEvent;
      case 'community':
        return QuestCategory.community;
      default:
        return QuestCategory.dailyPrayer;
    }
  }
}

extension QuestDifficultyX on QuestDifficulty {
  String get displayName {
    switch (this) {
      case QuestDifficulty.easy:
        return 'Easy';
      case QuestDifficulty.medium:
        return 'Medium';
      case QuestDifficulty.hard:
        return 'Hard';
      case QuestDifficulty.legendary:
        return 'Legendary';
    }
  }

  String get databaseKey {
    if (this == QuestDifficulty.legendary) return 'heroic';
    return name;
  }

  static QuestDifficulty fromDatabaseValue(String value) {
    if (value == 'heroic') return QuestDifficulty.legendary;
    return QuestDifficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => QuestDifficulty.easy,
    );
  }
}

extension QuestVerificationTypeX on QuestVerificationType {
  String get databaseKey {
    switch (this) {
      case QuestVerificationType.honorSystem:
        return 'self_report';
      case QuestVerificationType.timedSession:
        return 'time_based';
      case QuestVerificationType.quizCompletion:
        return 'quiz_completion';
      case QuestVerificationType.photoUpload:
        return 'photo_proof';
      case QuestVerificationType.streakRequired:
        return 'self_report';
    }
  }

  static QuestVerificationType fromDatabaseValue(String value) {
    switch (value) {
      case 'self_report':
        return QuestVerificationType.honorSystem;
      case 'time_based':
        return QuestVerificationType.timedSession;
      case 'quiz_completion':
        return QuestVerificationType.quizCompletion;
      case 'photo_proof':
        return QuestVerificationType.photoUpload;
      default:
        return QuestVerificationType.honorSystem;
    }
  }
}

extension QuestRepeatFrequencyX on QuestRepeatFrequency {
  String get databaseKey => name;

  static QuestRepeatFrequency? fromDatabaseValue(String? value) {
    if (value == null || value == 'liturgical_season') return null;
    return QuestRepeatFrequency.values.firstWhere(
      (r) => r.name == value,
      orElse: () => QuestRepeatFrequency.once,
    );
  }
}
