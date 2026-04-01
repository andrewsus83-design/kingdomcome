import 'package:equatable/equatable.dart';

class QuestCompletionModel extends Equatable {
  final String id;
  final String userId;
  final String questId;
  final DateTime completedAt;
  final int holyPointsGranted;
  final int faithCoinsGranted;
  final int graceGranted;
  final int blessingsGranted;
  final String? proofUrl;
  final Map<String, dynamic> metadata;

  const QuestCompletionModel({
    required this.id,
    required this.userId,
    required this.questId,
    required this.completedAt,
    required this.holyPointsGranted,
    this.faithCoinsGranted = 0,
    this.graceGranted = 0,
    this.blessingsGranted = 0,
    this.proofUrl,
    this.metadata = const {},
  });

  factory QuestCompletionModel.fromJson(Map<String, dynamic> json) {
    return QuestCompletionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questId: json['quest_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      holyPointsGranted: json['holy_points_granted'] as int? ?? 0,
      faithCoinsGranted: json['faith_coins_granted'] as int? ?? 0,
      graceGranted: json['grace_granted'] as int? ?? 0,
      blessingsGranted: json['blessings_granted'] as int? ?? 0,
      proofUrl: json['proof_url'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quest_id': questId,
      'completed_at': completedAt.toIso8601String(),
      'holy_points_granted': holyPointsGranted,
      'faith_coins_granted': faithCoinsGranted,
      'grace_granted': graceGranted,
      'blessings_granted': blessingsGranted,
      'proof_url': proofUrl,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questId,
        completedAt,
        holyPointsGranted,
        faithCoinsGranted,
        graceGranted,
        blessingsGranted,
        proofUrl,
        metadata,
      ];
}
