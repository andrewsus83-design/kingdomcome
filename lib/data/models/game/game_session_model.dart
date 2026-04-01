import 'package:equatable/equatable.dart';

// ── Game type enum ────────────────────────────────────────────────────────────

enum GameType {
  saintDefender,
  scriptureBuilder,
  rosaryRunner,
  virtueForge,
  bibleTrivialDuel,
  liturgyCalendar;

  String get displayName {
    return switch (this) {
      GameType.saintDefender => 'Saint Defender',
      GameType.scriptureBuilder => 'Scripture Builder',
      GameType.rosaryRunner => 'Rosary Runner',
      GameType.virtueForge => 'Virtue Forge',
      GameType.bibleTrivialDuel => 'Bible Trivia Duel',
      GameType.liturgyCalendar => 'Liturgy Calendar',
    };
  }

  String get iconAssetPath {
    return switch (this) {
      GameType.saintDefender => 'assets/images/games/saint_defender.png',
      GameType.scriptureBuilder => 'assets/images/games/scripture_builder.png',
      GameType.rosaryRunner => 'assets/images/games/rosary_runner.png',
      GameType.virtueForge => 'assets/images/games/virtue_forge.png',
      GameType.bibleTrivialDuel => 'assets/images/games/bible_trivia_duel.png',
      GameType.liturgyCalendar => 'assets/images/games/liturgy_calendar.png',
    };
  }
}

// ── GameSessionModel ──────────────────────────────────────────────────────────

class GameSessionModel extends Equatable {
  const GameSessionModel({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.score,
    required this.maxScore,
    required this.durationSeconds,
    required this.holyPointsEarned,
    required this.faithCoinsEarned,
    required this.graceEarned,
    required this.completedAt,
    this.metaData = const {},
  });

  /// Unique session identifier (UUID).
  final String id;

  /// Supabase user UUID.
  final String userId;

  /// Which mini-game was played.
  final GameType gameType;

  /// Points scored in this session.
  final int score;

  /// Maximum possible score for the session (for percentage display).
  final int maxScore;

  /// How long the session lasted in seconds.
  final int durationSeconds;

  /// Holy Points awarded at session end.
  final int holyPointsEarned;

  /// Faith Coins awarded at session end.
  final int faithCoinsEarned;

  /// Grace resource awarded at session end.
  final int graceEarned;

  /// Game-specific metadata (e.g., waves survived, verses completed, etc.).
  final Map<String, dynamic> metaData;

  /// When the session was completed / saved.
  final DateTime completedAt;

  // ── Computed ──────────────────────────────────────────────────────────────────

  double get scorePercent => maxScore > 0 ? score / maxScore : 0.0;
  bool get isPerfectScore => score >= maxScore && maxScore > 0;

  // ── Serialisation ─────────────────────────────────────────────────────────────

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gameType: GameType.values.byName(json['game_type'] as String),
      score: json['score'] as int? ?? 0,
      maxScore: json['max_score'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      holyPointsEarned: json['holy_points_earned'] as int? ?? 0,
      faithCoinsEarned: json['faith_coins_earned'] as int? ?? 0,
      graceEarned: json['grace_earned'] as int? ?? 0,
      metaData: (json['meta_data'] as Map<String, dynamic>?) ?? {},
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_type': gameType.name,
      'score': score,
      'max_score': maxScore,
      'duration_seconds': durationSeconds,
      'holy_points_earned': holyPointsEarned,
      'faith_coins_earned': faithCoinsEarned,
      'grace_earned': graceEarned,
      'meta_data': metaData,
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
  }

  GameSessionModel copyWith({
    String? id,
    String? userId,
    GameType? gameType,
    int? score,
    int? maxScore,
    int? durationSeconds,
    int? holyPointsEarned,
    int? faithCoinsEarned,
    int? graceEarned,
    Map<String, dynamic>? metaData,
    DateTime? completedAt,
  }) {
    return GameSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      holyPointsEarned: holyPointsEarned ?? this.holyPointsEarned,
      faithCoinsEarned: faithCoinsEarned ?? this.faithCoinsEarned,
      graceEarned: graceEarned ?? this.graceEarned,
      metaData: metaData ?? this.metaData,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        gameType,
        score,
        maxScore,
        durationSeconds,
        holyPointsEarned,
        faithCoinsEarned,
        graceEarned,
        metaData,
        completedAt,
      ];
}
