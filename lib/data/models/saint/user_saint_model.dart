import 'package:equatable/equatable.dart';

class UserSaintModel extends Equatable {
  final String userId;
  final String saintId;
  final DateTime unlockedAt;
  final bool isActive;
  final DateTime? abilityActivatedAt;
  final DateTime? abilityExpiresAt;
  final int timesActivated;

  const UserSaintModel({
    required this.userId,
    required this.saintId,
    required this.unlockedAt,
    this.isActive = false,
    this.abilityActivatedAt,
    this.abilityExpiresAt,
    this.timesActivated = 0,
  });

  /// Returns true when a saint ability is currently active and not yet expired.
  bool get isAbilityCurrentlyActive {
    if (abilityActivatedAt == null || abilityExpiresAt == null) return false;
    final now = DateTime.now();
    return now.isAfter(abilityActivatedAt!) && now.isBefore(abilityExpiresAt!);
  }

  factory UserSaintModel.fromJson(Map<String, dynamic> json) {
    return UserSaintModel(
      userId: json['user_id'] as String,
      saintId: json['saint_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      isActive: json['is_active'] as bool? ?? false,
      abilityActivatedAt: json['ability_activated_at'] != null
          ? DateTime.parse(json['ability_activated_at'] as String)
          : null,
      abilityExpiresAt: json['ability_expires_at'] != null
          ? DateTime.parse(json['ability_expires_at'] as String)
          : null,
      timesActivated: json['times_activated'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'saint_id': saintId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'is_active': isActive,
      'ability_activated_at': abilityActivatedAt?.toIso8601String(),
      'ability_expires_at': abilityExpiresAt?.toIso8601String(),
      'times_activated': timesActivated,
    };
  }

  UserSaintModel copyWith({
    String? userId,
    String? saintId,
    DateTime? unlockedAt,
    bool? isActive,
    DateTime? abilityActivatedAt,
    DateTime? abilityExpiresAt,
    int? timesActivated,
  }) {
    return UserSaintModel(
      userId: userId ?? this.userId,
      saintId: saintId ?? this.saintId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isActive: isActive ?? this.isActive,
      abilityActivatedAt: abilityActivatedAt ?? this.abilityActivatedAt,
      abilityExpiresAt: abilityExpiresAt ?? this.abilityExpiresAt,
      timesActivated: timesActivated ?? this.timesActivated,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        saintId,
        unlockedAt,
        isActive,
        abilityActivatedAt,
        abilityExpiresAt,
        timesActivated,
      ];
}
