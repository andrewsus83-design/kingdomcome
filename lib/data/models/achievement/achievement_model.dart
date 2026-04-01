import 'package:equatable/equatable.dart';

// ── Category enum ─────────────────────────────────────────────────────────────

enum AchievementCategory {
  prayer,
  knowledge,
  kingdom,
  social,
  virtue,
  arts,
  games;

  String get displayName => switch (this) {
        AchievementCategory.prayer => 'Prayer',
        AchievementCategory.knowledge => 'Knowledge',
        AchievementCategory.kingdom => 'Kingdom Builder',
        AchievementCategory.social => 'Social',
        AchievementCategory.virtue => 'Virtue',
        AchievementCategory.arts => 'Arts',
        AchievementCategory.games => 'Games',
      };

  String get emoji => switch (this) {
        AchievementCategory.prayer => '🙏',
        AchievementCategory.knowledge => '📖',
        AchievementCategory.kingdom => '🏰',
        AchievementCategory.social => '👥',
        AchievementCategory.virtue => '❤️',
        AchievementCategory.arts => '🎨',
        AchievementCategory.games => '🎮',
      };
}

// ── Achievement model ─────────────────────────────────────────────────────────

class AchievementModel extends Equatable {
  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconAssetPath,
    required this.holyPointsReward,
    required this.requiredCount,
    this.isSecret = false,
    this.shareImageTemplate,
  });

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;

  /// Path to icon asset, e.g. `assets/images/achievements/first_rosary.png`
  final String iconAssetPath;

  /// Holy Points rewarded when this achievement is unlocked.
  final int holyPointsReward;

  /// How many times the triggering action must be done (e.g., 7 for 7-day streak).
  final int requiredCount;

  /// Secret achievements are hidden until unlocked.
  final bool isSecret;

  /// Optional template key for generating a shareable image.
  final String? shareImageTemplate;

  // ── Serialisation ─────────────────────────────────────────────────────────────

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: AchievementCategory.values.byName(json['category'] as String),
      iconAssetPath: json['icon_asset_path'] as String? ??
          'assets/images/achievements/default.png',
      holyPointsReward: json['holy_points_reward'] as int? ?? 0,
      requiredCount: json['required_count'] as int? ?? 1,
      isSecret: json['is_secret'] as bool? ?? false,
      shareImageTemplate: json['share_image_template'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'icon_asset_path': iconAssetPath,
      'holy_points_reward': holyPointsReward,
      'required_count': requiredCount,
      'is_secret': isSecret,
      'share_image_template': shareImageTemplate,
    };
  }

  @override
  List<Object?> get props => [
        id, title, description, category, iconAssetPath,
        holyPointsReward, requiredCount, isSecret, shareImageTemplate,
      ];
}

// ── User achievement model ────────────────────────────────────────────────────

class UserAchievementModel extends Equatable {
  const UserAchievementModel({
    required this.userId,
    required this.achievementId,
    required this.currentProgress,
    required this.targetCount,
    required this.isCompleted,
    this.completedAt,
  });

  final String userId;
  final String achievementId;
  final int currentProgress;
  final int targetCount;
  final bool isCompleted;
  final DateTime? completedAt;

  // ── Computed ──────────────────────────────────────────────────────────────────

  double get progressPercent =>
      targetCount > 0 ? (currentProgress / targetCount).clamp(0.0, 1.0) : 0.0;

  // ── Serialisation ─────────────────────────────────────────────────────────────

  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    return UserAchievementModel(
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      currentProgress: json['current_progress'] as int? ?? 0,
      targetCount: json['target_count'] as int? ?? 1,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'achievement_id': achievementId,
      'current_progress': currentProgress,
      'target_count': targetCount,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toUtc().toIso8601String(),
    };
  }

  UserAchievementModel copyWith({
    String? userId,
    String? achievementId,
    int? currentProgress,
    int? targetCount,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return UserAchievementModel(
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetCount: targetCount ?? this.targetCount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId, achievementId, currentProgress, targetCount, isCompleted, completedAt,
      ];
}
