import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/constants/game_constants.dart';
import 'package:kingdomcome/data/models/ark/ark_node_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';

part 'ark_provider.g.dart';

final _supabase = Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────────────────
// Ark Notifier — manages the full list of Bible journey nodes
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class ArkNotifier extends _$ArkNotifier {
  @override
  Future<List<ArkNodeModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return _mockNodes();

    return _fetchNodesWithCompletion(user.id);
  }

  /// Marks a node as complete and awards its resources to the user.
  ///
  /// Updates local state optimistically, then persists to Supabase.
  Future<void> completeNode(String nodeId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final nodes = state.valueOrNull;
    if (nodes == null) return;

    final nodeIndex = nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex == -1) return;

    final node = nodes[nodeIndex];
    if (node.isCompleted) return;

    // Optimistic update
    final updated = node.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    final updatedNodes = [...nodes];
    updatedNodes[nodeIndex] = updated;
    state = AsyncData(updatedNodes);

    // Award resources optimistically
    ref.read(resourceNotifierProvider.notifier).optimisticAdd(
          ResourceReward(
            holyPoints: node.holyPointsReward,
            faithCoins: node.faithCoinsReward,
            grace: node.graceReward,
            blessings: 0,
          ),
        );

    try {
      await _supabase.from('ark_node_completions').upsert({
        'user_id': user.id,
        'node_id': nodeId,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Award via RPC so server validates and records
      await _supabase.rpc('complete_ark_node', params: {
        'p_user_id': user.id,
        'p_node_id': nodeId,
      });
    } catch (_) {
      // Rollback optimistic update
      updatedNodes[nodeIndex] = node;
      state = AsyncData(List.unmodifiable(updatedNodes));
    }
  }

  /// Returns all nodes belonging to a specific [section].
  List<ArkNodeModel> getNodesBySection(
    ArkSection section, {
    List<ArkNodeModel>? from,
  }) {
    final nodes = from ?? state.valueOrNull ?? [];
    return nodes
        .where((n) => n.section == section)
        .toList()
      ..sort((a, b) => a.orderInSection.compareTo(b.orderInSection));
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<ArkNodeModel>> _fetchNodesWithCompletion(String userId) async {
    final nodesData = await _supabase
        .from('ark_nodes')
        .select()
        .order('section')
        .order('order_in_section') as List<dynamic>;

    final completionsData = await _supabase
        .from('ark_node_completions')
        .select('node_id, completed_at')
        .eq('user_id', userId) as List<dynamic>;

    final completedMap = {
      for (final c in completionsData)
        (c as Map<String, dynamic>)['node_id'] as String:
            DateTime.parse(c['completed_at'] as String),
    };

    return nodesData.map((raw) {
      final json = raw as Map<String, dynamic>;
      final nodeId = json['id'] as String;
      final completedAt = completedMap[nodeId];
      return ArkNodeModel.fromJson({
        ...json,
        'is_completed': completedAt != null,
        if (completedAt != null)
          'completed_at': completedAt.toIso8601String(),
      });
    }).toList();
  }

  /// Returns hard-coded seed nodes for development / when unauthenticated.
  List<ArkNodeModel> _mockNodes() {
    const sections = ArkSection.values;
    final nodes = <ArkNodeModel>[];
    int globalOrder = 0;

    for (final section in sections) {
      // 5 nodes per section as seed data
      for (int i = 0; i < 5; i++) {
        final types = [
          ArkNodeType.story,
          ArkNodeType.verse,
          ArkNodeType.quiz,
          ArkNodeType.chapter,
          i == 2 ? ArkNodeType.dailyBread : ArkNodeType.verse,
        ];
        nodes.add(ArkNodeModel(
          id: '${section.name}_$i',
          title: _sectionNodeTitle(section, i),
          description: _sectionNodeDescription(section, i),
          nodeType: types[i % types.length],
          section: section,
          orderInSection: i,
          holyPointsReward: 10 + (i * 5),
          faithCoinsReward: 5 + (i * 2),
          graceReward: 2 + i,
          isCompleted: globalOrder < 3,
        ));
        globalOrder++;
      }
    }
    return nodes;
  }

  String _sectionNodeTitle(ArkSection section, int index) {
    final titles = <ArkSection, List<String>>{
      ArkSection.inTheBeginning: [
        'The Creation Story',
        'In the Beginning was Light',
        'Adam and Eve in the Garden',
        'The Fall of Man',
        'Noah and the Great Flood',
      ],
      ArkSection.outOfEgypt: [
        'Moses in the Bulrushes',
        'The Burning Bush',
        'The Ten Plagues of Egypt',
        'Crossing the Red Sea',
        'The Ten Commandments',
      ],
      ArkSection.promisedLand: [
        'Joshua Crosses the Jordan',
        'The Walls of Jericho',
        'Gideon\'s Three Hundred',
        'Samson and Delilah',
        'Ruth and Naomi',
      ],
      ArkSection.kingdomOfIsrael: [
        'David and Goliath',
        'The Psalms of David',
        'Solomon\'s Wisdom',
        'Elijah and the Prophets of Baal',
        'The Exile to Babylon',
      ],
      ArkSection.wordsOfProphets: [
        'Isaiah\'s Prophecy of the Messiah',
        'Jeremiah\'s Lament',
        'Ezekiel\'s Vision of Dry Bones',
        'Daniel in the Lions\' Den',
        'Jonah and the Whale',
      ],
      ArkSection.birthOfKing: [
        'The Annunciation to Mary',
        'Joseph\'s Dream',
        'The Journey to Bethlehem',
        'The Nativity of Christ',
        'The Visit of the Magi',
      ],
      ArkSection.ministryOfJesus: [
        'The Baptism of Jesus',
        'The Wedding at Cana',
        'The Sermon on the Mount',
        'The Parable of the Prodigal Son',
        'The Feeding of the Five Thousand',
      ],
      ArkSection.passionAndResurrection: [
        'Palm Sunday Entry',
        'The Last Supper',
        'The Agony in the Garden',
        'The Crucifixion',
        'The Resurrection',
      ],
      ArkSection.earlyChurch: [
        'Pentecost and the Holy Spirit',
        'Peter Heals the Lame Man',
        'The Conversion of Paul',
        'Paul\'s Missionary Journeys',
        'Paul and Silas in Prison',
      ],
      ArkSection.lettersOfFaith: [
        'Love is Patient — 1 Corinthians 13',
        'The Armour of God — Ephesians 6',
        'Faith and Works — James 2',
        'The Greatest Commandment',
        'The Book of Revelation',
      ],
    };

    return titles[section]?[index] ?? '${section.displayName} — Day ${index + 1}';
  }

  String _sectionNodeDescription(ArkSection section, int index) {
    return 'Explore this passage from ${section.displayName} and earn rewards for completing it.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Bread provider — today's verse
// ─────────────────────────────────────────────────────────────────────────────

/// A lightweight model representing today's daily verse.
class DailyBreadVerse {
  final String id;
  final String verseText;
  final String reference;
  final String reflectionPrompt;

  /// Name of the Saint narrating today's verse.
  final String narratorSaintName;

  /// Asset path for the narrator saint portrait.
  final String narratorPortraitPath;

  /// Suno audio URL for the verse reading.
  final String? audioUrl;

  final DateTime date;

  const DailyBreadVerse({
    required this.id,
    required this.verseText,
    required this.reference,
    required this.reflectionPrompt,
    required this.narratorSaintName,
    required this.narratorPortraitPath,
    this.audioUrl,
    required this.date,
  });

  factory DailyBreadVerse.fromJson(Map<String, dynamic> json) {
    return DailyBreadVerse(
      id: json['id'] as String,
      verseText: json['verse_text'] as String,
      reference: json['reference'] as String,
      reflectionPrompt:
          json['reflection_prompt'] as String? ?? 'What does this verse mean to you today?',
      narratorSaintName:
          json['narrator_saint_name'] as String? ?? 'Saint Francis',
      narratorPortraitPath:
          json['narrator_portrait_path'] as String? ?? 'assets/images/saints/default.png',
      audioUrl: json['audio_url'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

@riverpod
Future<DailyBreadVerse> dailyBread(Ref ref) async {
  final today = DateTime.now();
  final dateKey =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  try {
    final data = await _supabase
        .from('daily_bread')
        .select()
        .eq('date', dateKey)
        .maybeSingle();

    if (data != null) {
      return DailyBreadVerse.fromJson(data as Map<String, dynamic>);
    }
  } catch (_) {
    // Fall through to mock
  }

  // Fallback daily bread — rotates by day of year
  final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
  return _mockDailyBread(dayOfYear, today);
}

DailyBreadVerse _mockDailyBread(int dayOfYear, DateTime today) {
  final verses = [
    (
      'For God so loved the world that he gave his only Son, so that everyone who believes in him might not perish but might have eternal life.',
      'John 3:16',
      'How does knowing God loves you this much change how you see today?',
    ),
    (
      'I can do all things through him who strengthens me.',
      'Philippians 4:13',
      'What challenge are you facing today that God can help you with?',
    ),
    (
      'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures.',
      'Psalm 23:1-2',
      'In what ways does God shepherd you through difficult times?',
    ),
    (
      'Ask and it will be given to you; seek and you will find; knock and the door will be opened to you.',
      'Matthew 7:7',
      'What have you been praying for? How does this verse encourage you?',
    ),
    (
      'Love is patient, love is kind. It is not jealous, it is not pompous, it is not inflated.',
      '1 Corinthians 13:4',
      'Who in your life are you called to love more patiently today?',
    ),
    (
      'Be strong and courageous. Do not be frightened or dismayed, for the Lord, your God, is with you wherever you go.',
      'Joshua 1:9',
      'Where do you need God\'s courage in your life right now?',
    ),
    (
      'Trust in the Lord with all your heart, on your own intelligence rely not.',
      'Proverbs 3:5',
      'Are there areas of your life where you are relying on yourself instead of God?',
    ),
  ];

  final saints = [
    ('Saint Francis of Assisi', 'assets/images/saints/st_francis.png'),
    ('Saint Thérèse of Lisieux', 'assets/images/saints/st_therese.png'),
    ('Saint John Paul II', 'assets/images/saints/st_john_paul_ii.png'),
    ('Saint Thomas Aquinas', 'assets/images/saints/st_thomas_aquinas.png'),
    ('Saint Mary Magdalene', 'assets/images/saints/st_mary_magdalene.png'),
    ('Saint Peter the Apostle', 'assets/images/saints/st_peter.png'),
    ('Saint Augustine of Hippo', 'assets/images/saints/st_augustine.png'),
  ];

  final verseIndex = dayOfYear % verses.length;
  final saintIndex = dayOfYear % saints.length;
  final (text, ref, prompt) = verses[verseIndex];
  final (saintName, portrait) = saints[saintIndex];

  return DailyBreadVerse(
    id: 'daily_$dayOfYear',
    verseText: text,
    reference: ref,
    reflectionPrompt: prompt,
    narratorSaintName: saintName,
    narratorPortraitPath: portrait,
    date: today,
  );
}
