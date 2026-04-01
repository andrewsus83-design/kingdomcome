import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/game/game_session_model.dart';

// ── Game metadata ─────────────────────────────────────────────────────────────

class _GameInfo {
  const _GameInfo({
    required this.gameType,
    required this.name,
    required this.description,
    required this.xpReward,
    required this.icon,
    required this.color,
    required this.requiredBuilding,
    required this.route,
    this.isLocked = false,
  });

  final GameType gameType;
  final String name;
  final String description;
  final String xpReward;
  final IconData icon;
  final Color color;
  final String requiredBuilding;
  final String route;
  final bool isLocked;
}

final List<_GameInfo> _games = [
  const _GameInfo(
    gameType: GameType.saintDefender,
    name: 'Saint Defender',
    description: 'Defend against vices with the power of the saints!',
    xpReward: '+50 Holy Points/wave',
    icon: Icons.shield,
    color: Color(0xFF9B59B6),
    requiredBuilding: 'Fortress Wall',
    route: '/games/saint-defender',
  ),
  const _GameInfo(
    gameType: GameType.scriptureBuilder,
    name: 'Scripture Builder',
    description: 'Rebuild Bible verses word by word.',
    xpReward: '+30 FaithCoins/verse',
    icon: Icons.menu_book,
    color: Color(0xFF3498DB),
    requiredBuilding: 'Scriptorium',
    route: '/games/scripture-builder',
  ),
  const _GameInfo(
    gameType: GameType.rosaryRunner,
    name: 'Rosary Runner',
    description: 'Run the Way of the Rosary and collect all 50 beads!',
    xpReward: '+Grace on completion',
    icon: Icons.radio_button_checked,
    color: Color(0xFF1ABC9C),
    requiredBuilding: 'Chapel',
    route: '/games/rosary-runner',
  ),
  const _GameInfo(
    gameType: GameType.virtueForge,
    name: 'Virtue Forge',
    description: 'Combine virtue cards to forge saint relics.',
    xpReward: '+Kingdom bonuses',
    icon: Icons.auto_fix_high,
    color: Color(0xFFE67E22),
    requiredBuilding: 'Market',
    route: '/games/virtue-forge',
  ),
  const _GameInfo(
    gameType: GameType.bibleTrivialDuel,
    name: 'Bible Trivia Duel',
    description: 'Battle friends in Catholic knowledge!',
    xpReward: '+40 FaithCoins/win',
    icon: Icons.quiz,
    color: Color(0xFFE74C3C),
    requiredBuilding: 'Cathedral',
    route: '/games/bible-trivia-duel',
  ),
  const _GameInfo(
    gameType: GameType.liturgyCalendar,
    name: 'Liturgy Calendar',
    description: 'Place seasons and feasts on the sacred wheel.',
    xpReward: '+20 Holy Points/item',
    icon: Icons.calendar_month,
    color: Color(0xFF27AE60),
    requiredBuilding: 'Parish Hall',
    route: '/games/liturgy-calendar',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In production: derive daily game from current date
    const dailyChallengeIndex = 0; // Saint Defender today

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Games',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Daily Challenge Banner ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _DailyChallengeBanner(game: _games[dailyChallengeIndex]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Section title ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'All Games',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontFamily: 'Cinzel',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ── Game grid ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _GameCard(
                  game: _games[index],
                  isDaily: index == dailyChallengeIndex,
                ),
                childCount: _games.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Daily Challenge Banner ────────────────────────────────────────────────────

class _DailyChallengeBanner extends StatelessWidget {
  const _DailyChallengeBanner({required this.game});
  final _GameInfo game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [game.color.withOpacity(0.8), game.color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          boxShadow: [
            BoxShadow(
              color: game.color.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(game.route),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(game.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DAILY CHALLENGE',
                            style: TextStyle(
                              color: Color(0xFF1A0A2E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          game.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cinzel',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          game.xpReward,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1);
  }
}

// ── Game Card ─────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, this.isDaily = false});
  final _GameInfo game;
  final bool isDaily;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDaily
              ? const Color(0xFFFFD700)
              : game.color.withOpacity(0.4),
          width: isDaily ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: game.color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: game.isLocked ? null : () => context.push(game.route),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + lock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: game.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(game.icon, color: game.color, size: 26),
                    ),
                    if (game.isLocked)
                      const Icon(Icons.lock, color: Colors.white38, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                // Name
                Text(
                  game.name,
                  style: TextStyle(
                    color: game.isLocked ? Colors.white38 : Colors.white,
                    fontFamily: 'Cinzel',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Description
                Expanded(
                  child: Text(
                    game.isLocked
                        ? 'Requires ${game.requiredBuilding}'
                        : game.description,
                    style: TextStyle(
                      color: game.isLocked ? Colors.white24 : Colors.white60,
                      fontSize: 11,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                // XP badge
                if (!game.isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: game.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: game.color.withOpacity(0.4)),
                    ),
                    child: Text(
                      game.xpReward,
                      style: TextStyle(
                        color: game.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 50.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
