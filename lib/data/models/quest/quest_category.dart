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
}
