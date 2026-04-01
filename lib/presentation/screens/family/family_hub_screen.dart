import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Domain ────────────────────────────────────────────────────────────────────

class _FamilyMember {
  const _FamilyMember({
    required this.id,
    required this.displayName,
    required this.avatarEmoji,
    required this.kingdomLevel,
    required this.prayerStreakDays,
    required this.role,
  });

  final String id;
  final String displayName;
  final String avatarEmoji;
  final int kingdomLevel;
  final int prayerStreakDays;
  final String role; // 'parent' | 'child'
}

class _FamilyAchievement {
  const _FamilyAchievement({
    required this.title,
    required this.emoji,
    required this.isCompleted,
    required this.progress,
    required this.target,
  });

  final String title;
  final String emoji;
  final bool isCompleted;
  final int progress;
  final int target;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const List<_FamilyMember> _mockFamily = [
  _FamilyMember(
    id: '1',
    displayName: 'Dad',
    avatarEmoji: '👨',
    kingdomLevel: 8,
    prayerStreakDays: 14,
    role: 'parent',
  ),
  _FamilyMember(
    id: '2',
    displayName: 'Mom',
    avatarEmoji: '👩',
    kingdomLevel: 9,
    prayerStreakDays: 21,
    role: 'parent',
  ),
  _FamilyMember(
    id: '3',
    displayName: 'You',
    avatarEmoji: '🧒',
    kingdomLevel: 5,
    prayerStreakDays: 7,
    role: 'child',
  ),
  _FamilyMember(
    id: '4',
    displayName: 'Sibling',
    avatarEmoji: '👧',
    kingdomLevel: 3,
    prayerStreakDays: 3,
    role: 'child',
  ),
];

const List<_FamilyAchievement> _familyAchievements = [
  _FamilyAchievement(
    title: 'Attended Mass Together 10 times',
    emoji: '⛪',
    isCompleted: false,
    progress: 6,
    target: 10,
  ),
  _FamilyAchievement(
    title: 'Read Bible every day for a week',
    emoji: '📖',
    isCompleted: true,
    progress: 7,
    target: 7,
  ),
  _FamilyAchievement(
    title: 'Family Rosary 5 times',
    emoji: '📿',
    isCompleted: false,
    progress: 2,
    target: 5,
  ),
  _FamilyAchievement(
    title: 'All members complete a Good Deed',
    emoji: '❤️',
    isCompleted: true,
    progress: 4,
    target: 4,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class FamilyHubScreen extends ConsumerStatefulWidget {
  const FamilyHubScreen({super.key});

  @override
  ConsumerState<FamilyHubScreen> createState() => _FamilyHubScreenState();
}

class _FamilyHubScreenState extends ConsumerState<FamilyHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _prayerTimerActive = false;
  int _prayerSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family Hub',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'Members', icon: Icon(Icons.people, size: 18)),
            Tab(text: 'Mission', icon: Icon(Icons.flag, size: 18)),
            Tab(text: 'Prayer', icon: Icon(Icons.auto_awesome, size: 18)),
            Tab(text: 'Controls', icon: Icon(Icons.settings, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildMissionTab(),
          _buildPrayerTab(),
          _buildParentControlsTab(),
        ],
      ),
    );
  }

  // ── Members tab ───────────────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    final familyStreakMin = _mockFamily.map((m) => m.prayerStreakDays).reduce((a, b) => a < b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Family prayer streak
        _StreakBanner(streakDays: familyStreakMin),
        const SizedBox(height: 16),
        const Text(
          'Family Members',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._mockFamily.map((m) => _MemberCard(member: m)).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.person_add),
          label: const Text('Invite Family Member'),
        ),
      ],
    );
  }

  // ── Mission tab ───────────────────────────────────────────────────────────────

  Widget _buildMissionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // This week's family mission
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B2FA0), Color(0xFF3498DB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏆 Weekly Family Mission',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pray the Rosary together as a family',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Reward: +200 Holy Points for everyone!',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Member progress
        const Text(
          'Member Progress',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._mockFamily.map((m) => _MissionProgressRow(member: m)),
        const SizedBox(height: 24),
        const Text(
          'Family Achievements',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._familyAchievements.map((a) => _AchievementTile(achievement: a)),
      ],
    );
  }

  // ── Prayer tab ────────────────────────────────────────────────────────────────

  Widget _buildPrayerTab() {
    final minutes = _prayerSeconds ~/ 60;
    final seconds = _prayerSeconds % 60;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A3A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'Pray Together',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontFamily: 'Cinzel',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set a shared timer for family rosary\nor evening prayers',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cinzel',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _prayerTimerActive = !_prayerTimerActive;
                        if (!_prayerTimerActive) _prayerSeconds = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _prayerTimerActive
                          ? Colors.redAccent
                          : const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF1A0A2E),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(_prayerTimerActive ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _prayerTimerActive ? 'Stop Prayer' : 'Start Praying',
                      style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 16),
        const _PrayerSuggestionCard(
          title: 'Family Rosary',
          description: 'Pray all 5 decades together (~25 min)',
          emoji: '📿',
          duration: '~25 min',
        ),
        const _PrayerSuggestionCard(
          title: 'Evening Prayer',
          description: 'Night Prayer from the Liturgy of the Hours',
          emoji: '🌙',
          duration: '~10 min',
        ),
        const _PrayerSuggestionCard(
          title: 'Grace Before Meals',
          description: 'A short blessing before family dinner',
          emoji: '🍽️',
          duration: '~2 min',
        ),
      ],
    );
  }

  // ── Parent controls tab ───────────────────────────────────────────────────────

  Widget _buildParentControlsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Parent Controls',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Available for accounts with parent role',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 20),
        _ControlSwitch(
          label: 'Screen Time Limits',
          description: 'Set daily app usage limits for children',
          value: false,
          onChanged: (_) {},
        ),
        _ControlSwitch(
          label: 'Content Filtering',
          description: 'Restrict content to youngest age group',
          value: true,
          onChanged: (_) {},
        ),
        _ControlSwitch(
          label: 'In-App Purchase Lock',
          description: 'Require parent approval for purchases',
          value: true,
          onChanged: (_) {},
        ),
        _ControlSwitch(
          label: 'Activity Reports',
          description: 'Weekly email summary of child activity',
          value: false,
          onChanged: (_) {},
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.download),
          label: const Text('Export Family Activity Report'),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streakDays});
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays-Day Family Prayer Streak!',
                  style: const TextStyle(
                    color: Color(0xFF1A0A2E),
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  'Keep praying together every day!',
                  style: TextStyle(color: Color(0xFF4A2800), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final _FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text(member.avatarEmoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: member.role == 'parent'
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : const Color(0xFF3498DB).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        member.role.toUpperCase(),
                        style: TextStyle(
                          color: member.role == 'parent'
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF3498DB),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Kingdom Level ${member.kingdomLevel}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '🔥 ${member.prayerStreakDays} days',
                      style: const TextStyle(color: Color(0xFFE67E22), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        ],
      ),
    );
  }
}

class _MissionProgressRow extends StatelessWidget {
  const _MissionProgressRow({required this.member});
  final _FamilyMember member;

  @override
  Widget build(BuildContext context) {
    // Simulate progress
    final progress = member.prayerStreakDays > 5 ? 1.0 : member.prayerStreakDays / 5.0;
    final done = progress >= 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(member.avatarEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: done ? const Color(0xFF27AE60) : const Color(0xFFFFD700),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            done ? '✅' : '⏳',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});
  final _FamilyAchievement achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.isCompleted
            ? const Color(0xFF27AE60).withOpacity(0.15)
            : const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: achievement.isCompleted
              ? const Color(0xFF27AE60).withOpacity(0.5)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Text(achievement.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: achievement.isCompleted ? const Color(0xFF27AE60) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: achievement.progress / achievement.target,
                  backgroundColor: Colors.white12,
                  color: achievement.isCompleted
                      ? const Color(0xFF27AE60)
                      : const Color(0xFFFFD700),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
                Text(
                  '${achievement.progress} / ${achievement.target}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerSuggestionCard extends StatelessWidget {
  const _PrayerSuggestionCard({
    required this.title,
    required this.description,
    required this.emoji,
    required this.duration,
  });
  final String title;
  final String description;
  final String emoji;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ControlSwitch extends StatelessWidget {
  const _ControlSwitch({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }
}
