import 'package:equatable/equatable.dart';

class ParishModel extends Equatable {
  final String id;
  final String name;
  final String diocese;
  final String city;
  final String country;
  final String? logoUrl;
  final int memberCount;
  final int totalHolyPoints;
  final bool isVerified;

  /// True when this record is a family group rather than a real parish.
  final bool isFamilyGroup;

  /// Short invite code for joining (e.g. "FMLY-1234").
  final String inviteCode;

  final String createdByUserId;
  final DateTime createdAt;

  const ParishModel({
    required this.id,
    required this.name,
    required this.diocese,
    required this.city,
    required this.country,
    this.logoUrl,
    this.memberCount = 0,
    this.totalHolyPoints = 0,
    this.isVerified = false,
    this.isFamilyGroup = false,
    required this.inviteCode,
    required this.createdByUserId,
    required this.createdAt,
  });

  factory ParishModel.fromJson(Map<String, dynamic> json) {
    return ParishModel(
      id: json['id'] as String,
      name: json['name'] as String,
      diocese: json['diocese'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      totalHolyPoints: json['total_holy_points'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isFamilyGroup: json['is_family_group'] as bool? ?? false,
      inviteCode: json['invite_code'] as String,
      createdByUserId: json['created_by_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'diocese': diocese,
      'city': city,
      'country': country,
      'logo_url': logoUrl,
      'member_count': memberCount,
      'total_holy_points': totalHolyPoints,
      'is_verified': isVerified,
      'is_family_group': isFamilyGroup,
      'invite_code': inviteCode,
      'created_by_user_id': createdByUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ParishModel copyWith({
    String? id,
    String? name,
    String? diocese,
    String? city,
    String? country,
    String? logoUrl,
    int? memberCount,
    int? totalHolyPoints,
    bool? isVerified,
    bool? isFamilyGroup,
    String? inviteCode,
    String? createdByUserId,
    DateTime? createdAt,
  }) {
    return ParishModel(
      id: id ?? this.id,
      name: name ?? this.name,
      diocese: diocese ?? this.diocese,
      city: city ?? this.city,
      country: country ?? this.country,
      logoUrl: logoUrl ?? this.logoUrl,
      memberCount: memberCount ?? this.memberCount,
      totalHolyPoints: totalHolyPoints ?? this.totalHolyPoints,
      isVerified: isVerified ?? this.isVerified,
      isFamilyGroup: isFamilyGroup ?? this.isFamilyGroup,
      inviteCode: inviteCode ?? this.inviteCode,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        diocese,
        city,
        country,
        logoUrl,
        memberCount,
        totalHolyPoints,
        isVerified,
        isFamilyGroup,
        inviteCode,
        createdByUserId,
        createdAt,
      ];
}
