import 'package:equatable/equatable.dart';

class ParishMemberModel extends Equatable {
  final String parishId;
  final String userId;

  /// Role within the parish: "member", "leader", "admin".
  final String role;

  final DateTime joinedAt;

  // Denormalised user fields for leaderboard display.
  final String username;
  final String? avatarUrl;
  final int currentLevel;
  final int weeklyHolyPoints;

  const ParishMemberModel({
    required this.parishId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.username,
    this.avatarUrl,
    required this.currentLevel,
    this.weeklyHolyPoints = 0,
  });

  bool get isLeader => role == 'leader' || role == 'admin';

  factory ParishMemberModel.fromJson(Map<String, dynamic> json) {
    return ParishMemberModel(
      parishId: json['parish_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      currentLevel: json['current_level'] as int? ?? 1,
      weeklyHolyPoints: json['weekly_holy_points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parish_id': parishId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'username': username,
      'avatar_url': avatarUrl,
      'current_level': currentLevel,
      'weekly_holy_points': weeklyHolyPoints,
    };
  }

  @override
  List<Object?> get props => [
        parishId,
        userId,
        role,
        joinedAt,
        username,
        avatarUrl,
        currentLevel,
        weeklyHolyPoints,
      ];
}
