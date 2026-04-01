import 'package:equatable/equatable.dart';

/// The type of content contained in an Ark journey node.
enum ArkNodeType {
  /// A Bible story node — HeyGen video or Suno audio narrative.
  story,

  /// A single Bible verse to read or memorize.
  verse,

  /// A short 3-question quiz on the topic.
  quiz,

  /// The special daily verse highlighted on the current day.
  dailyBread,

  /// A full Bible chapter interactive reading session.
  chapter,

  /// A node that has not yet been unlocked (requires a prerequisite).
  locked,
}

/// The ten themed sections of the Ark Bible journey.
enum ArkSection {
  /// Genesis stories — Creation, Fall, Flood, Patriarchs.
  inTheBeginning,

  /// Exodus — Moses, Plagues, Red Sea, Sinai.
  outOfEgypt,

  /// Joshua & Judges — Conquest of Canaan, Judges era.
  promisedLand,

  /// 1 & 2 Kings / Psalms — David, Solomon, the divided Kingdom.
  kingdomOfIsrael,

  /// Isaiah, Jeremiah, Ezekiel, Daniel — Major prophets.
  wordsOfProphets,

  /// Gospels — Nativity of Christ, Annunciation, Epiphany.
  birthOfKing,

  /// Miracles, parables, Sermon on the Mount.
  ministryOfJesus,

  /// Palm Sunday through Easter Sunday.
  passionAndResurrection,

  /// Acts of the Apostles — Pentecost and the early Church.
  earlyChurch,

  /// Pauline and Catholic epistles — Romans through Revelation.
  lettersOfFaith,
}

extension ArkSectionX on ArkSection {
  String get displayName {
    switch (this) {
      case ArkSection.inTheBeginning:
        return 'In the Beginning';
      case ArkSection.outOfEgypt:
        return 'Out of Egypt';
      case ArkSection.promisedLand:
        return 'Promised Land';
      case ArkSection.kingdomOfIsrael:
        return 'Kingdom of Israel';
      case ArkSection.wordsOfProphets:
        return 'Words of the Prophets';
      case ArkSection.birthOfKing:
        return 'Birth of the King';
      case ArkSection.ministryOfJesus:
        return 'Ministry of Jesus';
      case ArkSection.passionAndResurrection:
        return 'Passion & Resurrection';
      case ArkSection.earlyChurch:
        return 'The Early Church';
      case ArkSection.lettersOfFaith:
        return 'Letters of Faith';
    }
  }

  String get shortDescription {
    switch (this) {
      case ArkSection.inTheBeginning:
        return 'Genesis stories';
      case ArkSection.outOfEgypt:
        return 'Exodus';
      case ArkSection.promisedLand:
        return 'Joshua & Judges';
      case ArkSection.kingdomOfIsrael:
        return 'Kings & Psalms';
      case ArkSection.wordsOfProphets:
        return 'Isaiah & Jeremiah';
      case ArkSection.birthOfKing:
        return 'Gospels — Nativity';
      case ArkSection.ministryOfJesus:
        return 'Miracles & Parables';
      case ArkSection.passionAndResurrection:
        return 'Holy Week';
      case ArkSection.earlyChurch:
        return 'Acts of the Apostles';
      case ArkSection.lettersOfFaith:
        return 'Epistles';
    }
  }

  /// Icon representing the section checkpoint landmark.
  String get landmarkEmoji {
    switch (this) {
      case ArkSection.inTheBeginning:
        return '🌍';
      case ArkSection.outOfEgypt:
        return '🏔️';
      case ArkSection.promisedLand:
        return '🏕️';
      case ArkSection.kingdomOfIsrael:
        return '👑';
      case ArkSection.wordsOfProphets:
        return '📜';
      case ArkSection.birthOfKing:
        return '⭐';
      case ArkSection.ministryOfJesus:
        return '🐟';
      case ArkSection.passionAndResurrection:
        return '✝️';
      case ArkSection.earlyChurch:
        return '🕊️';
      case ArkSection.lettersOfFaith:
        return '✉️';
    }
  }
}

extension ArkNodeTypeX on ArkNodeType {
  String get displayName {
    switch (this) {
      case ArkNodeType.story:
        return 'Story';
      case ArkNodeType.verse:
        return 'Verse';
      case ArkNodeType.quiz:
        return 'Quiz';
      case ArkNodeType.dailyBread:
        return 'Daily Bread';
      case ArkNodeType.chapter:
        return 'Chapter';
      case ArkNodeType.locked:
        return 'Locked';
    }
  }

  String get emoji {
    switch (this) {
      case ArkNodeType.story:
        return '📖';
      case ArkNodeType.verse:
        return '✨';
      case ArkNodeType.quiz:
        return '🎯';
      case ArkNodeType.dailyBread:
        return '🍞';
      case ArkNodeType.chapter:
        return '📜';
      case ArkNodeType.locked:
        return '🔒';
    }
  }
}

/// A single node on The Ark Bible journey map.
///
/// Nodes are arranged in sections representing different parts of the Bible.
/// All nodes are visible in the open world — completed nodes show a checkmark,
/// locked nodes show unlock conditions.
class ArkNodeModel extends Equatable {
  /// Unique identifier for this node.
  final String id;

  /// Human-readable title (e.g. "The Creation Story").
  final String title;

  /// Short description shown in the node detail sheet.
  final String description;

  /// Type of content: story, verse, quiz, dailyBread, chapter, locked.
  final ArkNodeType nodeType;

  /// Which section of the Bible journey this node belongs to.
  final ArkSection section;

  /// Ordering within the section (lower = earlier on the path).
  final int orderInSection;

  /// Bible verse ID for verse and dailyBread nodes.
  final String? verseId;

  /// Bible chapter reference string (e.g. "Genesis 1") for chapter nodes.
  final String? chapterRef;

  /// Quiz ID for quiz nodes.
  final String? quizId;

  /// HeyGen video URL for story nodes.
  final String? heygenVideoUrl;

  /// Suno audio URL for story/verse/chapter nodes.
  final String? sunoAudioUrl;

  /// Thumbnail image URL shown on the node and in detail sheets.
  final String? thumbnailUrl;

  /// HolyPoints awarded upon completion.
  final int holyPointsReward;

  /// FaithCoins awarded upon completion.
  final int faithCoinsReward;

  /// Grace awarded upon completion.
  final int graceReward;

  /// Whether this node has been completed by the current user.
  final bool isCompleted;

  /// When the node was completed, null if not yet completed.
  final DateTime? completedAt;

  /// Human-readable description of what must be done to unlock this node.
  /// Only meaningful when [nodeType] is [ArkNodeType.locked].
  final String? unlockCondition;

  const ArkNodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.nodeType,
    required this.section,
    required this.orderInSection,
    this.verseId,
    this.chapterRef,
    this.quizId,
    this.heygenVideoUrl,
    this.sunoAudioUrl,
    this.thumbnailUrl,
    this.holyPointsReward = 10,
    this.faithCoinsReward = 5,
    this.graceReward = 2,
    this.isCompleted = false,
    this.completedAt,
    this.unlockCondition,
  });

  factory ArkNodeModel.fromJson(Map<String, dynamic> json) {
    return ArkNodeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      nodeType: ArkNodeType.values.firstWhere(
        (e) => e.name == (json['node_type'] as String? ?? 'story'),
        orElse: () => ArkNodeType.story,
      ),
      section: ArkSection.values.firstWhere(
        (e) => e.name == (json['section'] as String? ?? 'inTheBeginning'),
        orElse: () => ArkSection.inTheBeginning,
      ),
      orderInSection: json['order_in_section'] as int? ?? 0,
      verseId: json['verse_id'] as String?,
      chapterRef: json['chapter_ref'] as String?,
      quizId: json['quiz_id'] as String?,
      heygenVideoUrl: json['heygen_video_url'] as String?,
      sunoAudioUrl: json['suno_audio_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      holyPointsReward: json['holy_points_reward'] as int? ?? 10,
      faithCoinsReward: json['faith_coins_reward'] as int? ?? 5,
      graceReward: json['grace_reward'] as int? ?? 2,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      unlockCondition: json['unlock_condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'node_type': nodeType.name,
      'section': section.name,
      'order_in_section': orderInSection,
      if (verseId != null) 'verse_id': verseId,
      if (chapterRef != null) 'chapter_ref': chapterRef,
      if (quizId != null) 'quiz_id': quizId,
      if (heygenVideoUrl != null) 'heygen_video_url': heygenVideoUrl,
      if (sunoAudioUrl != null) 'suno_audio_url': sunoAudioUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'holy_points_reward': holyPointsReward,
      'faith_coins_reward': faithCoinsReward,
      'grace_reward': graceReward,
      'is_completed': isCompleted,
      if (completedAt != null)
        'completed_at': completedAt!.toIso8601String(),
      if (unlockCondition != null) 'unlock_condition': unlockCondition,
    };
  }

  ArkNodeModel copyWith({
    String? id,
    String? title,
    String? description,
    ArkNodeType? nodeType,
    ArkSection? section,
    int? orderInSection,
    String? verseId,
    String? chapterRef,
    String? quizId,
    String? heygenVideoUrl,
    String? sunoAudioUrl,
    String? thumbnailUrl,
    int? holyPointsReward,
    int? faithCoinsReward,
    int? graceReward,
    bool? isCompleted,
    DateTime? completedAt,
    String? unlockCondition,
  }) {
    return ArkNodeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      nodeType: nodeType ?? this.nodeType,
      section: section ?? this.section,
      orderInSection: orderInSection ?? this.orderInSection,
      verseId: verseId ?? this.verseId,
      chapterRef: chapterRef ?? this.chapterRef,
      quizId: quizId ?? this.quizId,
      heygenVideoUrl: heygenVideoUrl ?? this.heygenVideoUrl,
      sunoAudioUrl: sunoAudioUrl ?? this.sunoAudioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      holyPointsReward: holyPointsReward ?? this.holyPointsReward,
      faithCoinsReward: faithCoinsReward ?? this.faithCoinsReward,
      graceReward: graceReward ?? this.graceReward,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      unlockCondition: unlockCondition ?? this.unlockCondition,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        nodeType,
        section,
        orderInSection,
        verseId,
        chapterRef,
        quizId,
        heygenVideoUrl,
        sunoAudioUrl,
        thumbnailUrl,
        holyPointsReward,
        faithCoinsReward,
        graceReward,
        isCompleted,
        completedAt,
        unlockCondition,
      ];
}
