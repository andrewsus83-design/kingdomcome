import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Status enum
// ---------------------------------------------------------------------------

enum CompletionStatus {
  pendingValidation,
  validated,
  rejected,
}

extension CompletionStatusX on CompletionStatus {
  String get displayName {
    switch (this) {
      case CompletionStatus.pendingValidation:
        return 'Waiting for Approval';
      case CompletionStatus.validated:
        return 'Approved';
      case CompletionStatus.rejected:
        return 'Not Yet';
    }
  }

  String get emoji {
    switch (this) {
      case CompletionStatus.pendingValidation:
        return '⏳';
      case CompletionStatus.validated:
        return '✅';
      case CompletionStatus.rejected:
        return '❌';
    }
  }
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class RealWorldCompletionModel extends Equatable {
  final String id;
  final String userId;
  final String questId;
  final CompletionStatus status;
  final String? childNote;
  final String? proofPhotoUrl;
  final String? parentNote;
  final DateTime completedAt;
  final DateTime? validatedAt;
  final String? validatedByParentId;

  const RealWorldCompletionModel({
    required this.id,
    required this.userId,
    required this.questId,
    required this.status,
    this.childNote,
    this.proofPhotoUrl,
    this.parentNote,
    required this.completedAt,
    this.validatedAt,
    this.validatedByParentId,
  });

  factory RealWorldCompletionModel.fromJson(Map<String, dynamic> json) {
    return RealWorldCompletionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questId: json['quest_id'] as String,
      status: _statusFromString(json['status'] as String? ?? 'pendingValidation'),
      childNote: json['child_note'] as String?,
      proofPhotoUrl: json['proof_photo_url'] as String?,
      parentNote: json['parent_note'] as String?,
      completedAt: DateTime.parse(json['completed_at'] as String),
      validatedAt: json['validated_at'] != null
          ? DateTime.parse(json['validated_at'] as String)
          : null,
      validatedByParentId: json['validated_by_parent_id'] as String?,
    );
  }

  static CompletionStatus _statusFromString(String value) {
    // Handle snake_case from DB as well as camelCase
    switch (value) {
      case 'pending_validation':
      case 'pendingValidation':
        return CompletionStatus.pendingValidation;
      case 'validated':
        return CompletionStatus.validated;
      case 'rejected':
        return CompletionStatus.rejected;
      default:
        return CompletionStatus.pendingValidation;
    }
  }

  static String _statusToString(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.pendingValidation:
        return 'pending_validation';
      case CompletionStatus.validated:
        return 'validated';
      case CompletionStatus.rejected:
        return 'rejected';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quest_id': questId,
      'status': _statusToString(status),
      'child_note': childNote,
      'proof_photo_url': proofPhotoUrl,
      'parent_note': parentNote,
      'completed_at': completedAt.toIso8601String(),
      'validated_at': validatedAt?.toIso8601String(),
      'validated_by_parent_id': validatedByParentId,
    };
  }

  RealWorldCompletionModel copyWith({
    String? id,
    String? userId,
    String? questId,
    CompletionStatus? status,
    String? childNote,
    String? proofPhotoUrl,
    String? parentNote,
    DateTime? completedAt,
    DateTime? validatedAt,
    String? validatedByParentId,
  }) {
    return RealWorldCompletionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questId: questId ?? this.questId,
      status: status ?? this.status,
      childNote: childNote ?? this.childNote,
      proofPhotoUrl: proofPhotoUrl ?? this.proofPhotoUrl,
      parentNote: parentNote ?? this.parentNote,
      completedAt: completedAt ?? this.completedAt,
      validatedAt: validatedAt ?? this.validatedAt,
      validatedByParentId: validatedByParentId ?? this.validatedByParentId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questId,
        status,
        childNote,
        proofPhotoUrl,
        parentNote,
        completedAt,
        validatedAt,
        validatedByParentId,
      ];
}
