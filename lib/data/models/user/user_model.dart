import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  /// Age group: 1 = ages 8–10, 2 = ages 11–14, 3 = ages 15–18
  final int ageGroup;
  final bool parentalConsentGiven;
  final String? parentEmail;
  final String? parishId;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.ageGroup,
    required this.parentalConsentGiven,
    this.parentEmail,
    this.parishId,
    required this.createdAt,
    required this.lastActiveAt,
  }) : assert(ageGroup >= 1 && ageGroup <= 3, 'ageGroup must be 1, 2, or 3');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      ageGroup: json['age_group'] as int,
      parentalConsentGiven: json['parental_consent_given'] as bool? ?? false,
      parentEmail: json['parent_email'] as String?,
      parishId: json['parish_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'age_group': ageGroup,
      'parental_consent_given': parentalConsentGiven,
      'parent_email': parentEmail,
      'parish_id': parishId,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? ageGroup,
    bool? parentalConsentGiven,
    String? parentEmail,
    String? parishId,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ageGroup: ageGroup ?? this.ageGroup,
      parentalConsentGiven: parentalConsentGiven ?? this.parentalConsentGiven,
      parentEmail: parentEmail ?? this.parentEmail,
      parishId: parishId ?? this.parishId,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        avatarUrl,
        ageGroup,
        parentalConsentGiven,
        parentEmail,
        parishId,
        createdAt,
        lastActiveAt,
      ];
}
