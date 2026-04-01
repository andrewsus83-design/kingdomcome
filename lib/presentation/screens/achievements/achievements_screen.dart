import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/achievement/achievement_model.dart';

// ── Static achievement definitions ────────────────────────────────────────────

final List<AchievementModel> _allAchievements = [
  // Prayer
  const AchievementModel(id: 'first_prayer', title: 'First Steps', description: 'Complete your first prayer quest', category: AchievementCategory.prayer, iconAssetPath: 'assets/images/achievements/prayer_1.png', holyPointsReward: 20, requiredCount: 1),
  const AchievementModel(id: 'prayer_streak_7', title: 'Prayer Warrior', description: 'Pray 7 days in a row', category: AchievementCategory.prayer, iconAssetPath: 'assets/images/achievements/prayer_2.png', holyPointsReward: 50, requiredCount: 7),
  const AchievementModel(id: 'prayer_streak_30', title: 'Devoted Soul', description: 'Pray 30 days in a row', category: AchievementCategory.prayer, iconAssetPath: 'assets/images/achievements/prayer_3.png', holyPointsReward: 200, requiredCount: 30),
  const AchievementModel(id: 'first_rosary', title: 'Rosary Champion', description: 'Complete your first Rosary', category: AchievementCategory.prayer, iconAssetPath: 'assets/images/achievements/rosary.png', holyPointsReward: 40, requiredCount: 1),
  const AchievementModel(id: 'rosary_5', title: 'Hail Mary Hero', description: 'Complete 5 Rosaries', category: AchievementCategory.prayer, iconAssetPath: 'assets/images/achievements/rosary_5.png', holyPointsReward: 100, requiredCount: 5),
  const AchievementModel(id: 'divine_mercy', title: 'Mercy Seeker', description: 'Complete the Divine Mercy Chaplet', category: AchievementCategory.prayer, iconAssetPath: 'assets/images/achievements/mercy.png', holyPointsReward: 30, requiredCount: 1),

  // Knowledge
  const AchievementModel(id: 'first_quiz', title: 'First Quiz', description: 'Complete your first Bible quiz', category: AchievementCategory.knowledge, iconAssetPath: 'assets/images/achievements/quiz_1.png', holyPointsReward: 15, requiredCount: 1),
  const AchievementModel(id: 'quiz_master', title: 'Quiz Master', description: 'Score 100% on 10 quizzes', category: AchievementCategory.knowledge, iconAssetPath: 'assets/images/achievements/quiz_master.png', holyPointsReward: 150, requiredCount: 10),
  const AchievementModel(id: 'scripture_scholar', title: 'Scripture Scholar', description: 'Master 50 Bible verses', category: AchievementCategory.knowledge, iconAssetPath: 'assets/images/achievements/scripture.png', holyPointsReward: 200, requiredCount: 50),
  const AchievementModel(id: 'saints_expert', title: 'Saints Expert', description: 'Learn about 20 different saints', category: AchievementCategory.knowledge, iconAssetPath: 'assets/images/achievements/saints.png', holyPointsReward: 100, requiredCount: 20),
  const AchievementModel(id: 'catechism_student', title: 'Catechism Student', description: 'Answer 100 Catholic doctrine questions correctly', category: AchievementCategory.knowledge, iconAssetPath: 'assets/images/achievements/catechism.png', holyPointsReward: 175, requiredCount: 100),

  // Kingdom
  const AchievementModel(id: 'first_building', title: 'Foundation Stone', description: 'Build your first structure', category: AchievementCategory.kingdom, iconAssetPath: 'assets/images/achievements/build_1.png', holyPointsReward: 25, requiredCount: 1),
  const AchievementModel(id: 'level_5_cathedral', title: 'Great Cathedral', description: 'Upgrade Cathedral to Level 5', category: AchievementCategory.kingdom, iconAssetPath: 'assets/images/achievements/cathedral.png', holyPointsReward: 300, requiredCount: 5),
  const AchievementModel(id: 'kingdom_builder', title: 'Master Builder', description: 'Construct 10 buildings', category: AchievementCategory.kingdom, iconAssetPath: 'assets/images/achievements/builder.png', holyPointsReward: 200, requiredCount: 10),
  const AchievementModel(id: 'full_kingdom', title: 'Holy Kingdom', description: 'Fill every grid space in your kingdom', category: AchievementCategory.kingdom, iconAssetPath: 'assets/images/achievements/kingdom.png', holyPointsReward: 500, requiredCount: 1),

  // Social
  const AchievementModel(id: 'join_parish', title: 'Parish Member', description: 'Join your first parish group', category: AchievementCategory.social, iconAssetPath: 'assets/images/achievements/parish.png', holyPointsReward: 30, requiredCount: 1),
  const AchievementModel(id: 'invite_friend', title: 'Good Shepherd', description: 'Invite a friend to Kingdom Come', category: AchievementCategory.social, iconAssetPath: 'assets/images/achievements/invite.png', holyPointsReward: 50, requiredCount: 1),
  const AchievementModel(id: 'family_mission', title: 'Family Blessing', description: 'Complete 3 family missions', category: AchievementCategory.social, iconAssetPath: 'assets/images/achievements/family.png', holyPointsReward: 100, requiredCount: 3),
  const AchievementModel(id: 'class_top', title: 'Class Leader', description: 'Reach #1 on your class leaderboard', category: AchievementCategory.social, iconAssetPath: 'assets/images/achievements/class_top.png', holyPointsReward: 150, requiredCount: 1),

  // Virtue
  const AchievementModel(id: 'good_deed_10', title: 'Virtue Hero', description: 'Complete 10 Good Deed quests', category: AchievementCategory.virtue, iconAssetPath: 'assets/images/achievements/virtue.png', holyPointsReward: 100, requiredCount: 10),
  const AchievementModel(id: 'confession_5', title: 'Reconciled Soul', description: 'Complete 5 Confession quests', category: AchievementCategory.virtue, iconAssetPath: 'assets/images/achievements/confession.png', holyPointsReward: 75, requiredCount: 5),
  const AchievementModel(id: 'fasting_quest', title: 'Fasting Champion', description: 'Complete 3 Fasting quests', category: AchievementCategory.virtue, iconAssetPath: 'assets/images/achievements/fasting.png', holyPointsReward: 60, requiredCount: 3),
  const AchievementModel(id: 'first_virtue_relic', title: 'Relic Forger', description: 'Forge your first virtue relic', category: AchievementCategory.virtue, iconAssetPath: 'assets/images/achievements/relic.png', holyPointsReward: 80, requiredCount: 1),
  const AchievementModel(id: 'all_relics', title: 'Saint\'s Treasury', description: 'Discover all 15 relics in Virtue Forge', category: AchievementCategory.virtue, iconAssetPath: 'assets/images/achievements/treasury.png', holyPointsReward: 500, requiredCount: 15, isSecret: true),

  // Arts
  const AchievementModel(id: 'first_artwork', title: 'Art Creator', description: 'Create your first artwork', category: AchievementCategory.arts, iconAssetPath: 'assets/images/achievements/art_1.png', holyPointsReward: 25, requiredCount: 1),
  const AchievementModel(id: 'artworks_10', title: 'Sacred Artist', description: 'Create 10 artworks', category: AchievementCategory.arts, iconAssetPath: 'assets/images/achievements/art_10.png', holyPointsReward: 100, requiredCount: 10),
  const AchievementModel(id: 'ai_art', title: 'AI Illuminator', description: 'Generate your first AI artwork', category: AchievementCategory.arts, iconAssetPath: 'assets/images/achievements/ai_art.png', holyPointsReward: 50, requiredCount: 1),
  const AchievementModel(id: 'stained_glass', title: 'Glassmaker', description: 'Create all 3 stained glass templates', category: AchievementCategory.arts, iconAssetPath: 'assets/images/achievements/glass.png', holyPointsReward: 75, requiredCount: 3),
  const AchievementModel(id: 'kingdom_display', title: 'Gallery Owner', description: 'Display 5 artworks in your kingdom', category: AchievementCategory.arts, iconAssetPath: 'assets/images/achievements/gallery.png', holyPointsReward: 80, requiredCount: 5),

  // Games
  const AchievementModel(id: 'first_game', title: 'Game On!', description: 'Play your first mini-game', category: AchievementCategory.games, iconAssetPath: 'assets/images/achievements/game_1.png', holyPointsReward: 20, requiredCount: 1),
  const AchievementModel(id: 'game_high_score', title: 'High Scorer', description: 'Achieve a personal best score in any game', category: AchievementCategory.games, iconAssetPath: 'assets/images/achievements/high_score.png', holyPointsReward: 50, requiredCount: 1),
  const AchievementModel(id: 'daily_game_7', title: 'Daily Challenger', description: 'Complete daily game challenge 7 days in a row', category: AchievementCategory.games, iconAssetPath: 'assets/images/achievements/daily_game.png', holyPointsReward: 100, requiredCount: 7),
  const AchievementModel(id: 'all_games', title: 'Game Master', description: 'Play all 6 mini-games at least once', category: AchievementCategory.games, iconAssetPath: 'assets/images/achievements/game_master.png', holyPointsReward: 150, requiredCount: 6),
  const AchievementModel(id: 'full_rosary_runner', title: 'Rosary Complete!', description: 'Collect all 50 beads in Rosary Runner', category: AchievementCategory.games, iconAssetPath: 'assets/images/achievements/rosary_runner.png', holyPointsReward: 75, requiredCount: 1),
  const AchievementModel(id: 'trivia_streak', title: 'Bible Expert', description: 'Win 5 Bible Trivia Duels in a row', category: AchievementCategory.games, iconAssetPath: 'assets/images/achievements/trivia.png', holyPointsReward: 200, requiredCount: 5, isSecret: true),

  // Additional to reach 40
  const AchievementModel(id: 'mass_10', title: 'Mass Goer', description: 'Log attending Mass 10 times', category: AchievementCategory.prayer, iconAssetPath: 'assets/images/achievements/mass.png', holyPointsReward: 120, requiredCount: 10),
  const AchievementModel(id: 'hymn_generated', title: 'Hymn Composer', description: 'Generate your first AI hymn', category: AchievementCategory.arts, iconAssetPath: 'assets/images/achievements/hymn.png', holyPointsReward: 40, requiredCount: 1),
  const AchievementModel(id: 'calendar_expert', title: 'Liturgical Scholar', description: 'Complete the Liturgy Calendar puzzle on Hard mode', category: AchievementCategory.knowledge, iconAssetPath: 'assets/images/achievements/calendar.png', holyPointsReward: 120, requiredCount: 1),
  const AchievementModel(id: 'saint_defender_wave15', title: 'Virtue Defender', description: 'Survive all 15 waves in Saint Defender', category: AchievementCategory.games, iconAssetPath: 'assets/images/achievements/defender.png', holyPointsReward: 250, requiredCount: 15, isSecret: true),
];

// ── Mock user progress (in production from Supabase) ──────────────────────────

final Map<String, UserAchievementModel> _mockProgress = {
  'first_prayer': UserAchievementModel(userId: 'me', achievementId: 'first_prayer', currentProgress: 1, targetCount: 1, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 14))),
  'prayer_streak_7': UserAchievementModel(userId: 'me', achievementId: 'prayer_streak_7', currentProgress: 7, targetCount: 7, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 7))),
  'prayer_streak_30': UserAchievementModel(userId: 'me', achievementId: 'prayer_streak_30', currentProgress: 14, targetCount: 30, isCompleted: false),
  'first_rosary': UserAchievementModel(userId: 'me', achievementId: 'first_rosary', currentProgress: 1, targetCount: 1, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 5))),
  'first_building': UserAchievementModel(userId: 'me', achievementId: 'first_building', currentProgress: 1, targetCount: 1, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 20))),
  'first_quiz': UserAchievementModel(userId: 'me', achievementId: 'first_quiz', currentProgress: 1, targetCount: 1, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 10))),
  'join_parish': UserAchievementModel(userId: 'me', achievementId: 'join_parish', currentProgress: 1, targetCount: 1, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 21))),
  'first_artwork': UserAchievementModel(userId: 'me', achievementId: 'first_artwork', currentProgress: 1, targetCount: 1, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 3))),
  'first_game': UserAchievementModel(userId: 'me', achievementId: 'first_game', currentProgress: 1, targetCount: 1, isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 8))),
  'good_deed_10': UserAchievementModel(userId: 'me', achievementId: 'good_deed_10', currentProgress: 6, targetCount: 10, isCompleted: false),
  'kingdom_builder': UserAchievementModel(userId: 'me', achievementId: 'kingdom_builder', currentProgress: 4, targetCount: 10, isCompleted: false),
  'artworks_10': UserAchievementModel(userId: 'me', achievementId: 'artworks_10', currentProgress: 3, targetCount: 10, isCompleted: false),
};

// ── Screen ────────────────────────────────────────────────────────────────────

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = AchievementCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length + 1, // +1 for "All" tab
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _mockProgress.values.where((p) => p.isCompleted).length;
    final total = _allAchievements.where((a) => !a.isSecret).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '$completed / $total',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completed / total,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFFFFD700),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(completed / total * 100).round()}%',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Category tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFFFFD700),
                labelColor: const Color(0xFFFFD700),
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontSize: 11),
                tabs: [
                  const Tab(text: 'All'),
                  ..._categories.map((c) => Tab(text: c.displayName)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAchievementGrid(null),
          ..._categories.map((c) => _buildAchievementGrid(c)),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(AchievementCategory? category) {
    final filtered = category == null
        ? _allAchievements
        : _allAchievements.where((a) => a.category == category).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final achievement = filtered[i];
        final userProgress = _mockProgress[achievement.id];
        return _AchievementTile(
          achievement: achievement,
          userProgress: userProgress,
        ).animate().fadeIn(delay: (i * 30).ms);
      },
    );
  }
}

// ── Achievement tile ──────────────────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    this.userProgress,
  });
  final AchievementModel achievement;
  final UserAchievementModel? userProgress;

  @override
  Widget build(BuildContext context) {
    final isCompleted = userProgress?.isCompleted ?? false;
    final progress = userProgress?.progressPercent ?? 0.0;
    final current = userProgress?.currentProgress ?? 0;

    // Secret and not unlocked
    if (achievement.isSecret && !isCompleted) {
      return _buildSecretTile();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF1A3A1A)
            : const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF27AE60).withOpacity(0.5)
              : Colors.white12,
          width: isCompleted ? 1.5 : 1,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF27AE60).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF27AE60).withOpacity(0.4)
                    : Colors.white12,
              ),
            ),
            child: Center(
              child: Text(
                achievement.category.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          color: isCompleted
                              ? const Color(0xFF27AE60)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Cinzel',
                        ),
                      ),
                    ),
                    if (isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF27AE60),
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                if (!isCompleted && achievement.requiredCount > 1) ...[
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white12,
                          color: achievement.category == AchievementCategory.prayer
                              ? const Color(0xFF9B59B6)
                              : const Color(0xFFFFD700),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$current / ${achievement.requiredCount}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ] else if (isCompleted && userProgress?.completedAt != null) ...[
                  Text(
                    'Unlocked ${_formatDate(userProgress!.completedAt!)}',
                    style: const TextStyle(color: Color(0xFF27AE60), fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Reward
          Column(
            children: [
              Text(
                '+${achievement.holyPointsReward}',
                style: const TextStyle(
                  color: Color(0xFF9B59B6),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Text(
                'HP',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showShareOptions(context, achievement),
                  child: const Icon(Icons.share, color: Colors.white38, size: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecretTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('❓', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secret Achievement',
                  style: TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cinzel',
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Keep playing to discover this!',
                  style: TextStyle(color: Colors.white12, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  void _showShareOptions(BuildContext context, AchievementModel achievement) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🏆 ${achievement.title}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'Cinzel',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareButton(label: 'Share', icon: Icons.share, onTap: () {}),
                _ShareButton(
                  label: 'Print\nCertificate',
                  icon: Icons.picture_as_pdf,
                  onTap: () => _generateCertificate(context, achievement),
                ),
                _ShareButton(label: 'Parish\nFeed', icon: Icons.people, onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateCertificate(BuildContext context, AchievementModel achievement) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating certificate for "${achievement.title}"…'),
        backgroundColor: const Color(0xFF27AE60),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
