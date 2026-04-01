import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Domain ────────────────────────────────────────────────────────────────────

class _ClassMember {
  const _ClassMember({
    required this.rank,
    required this.displayName,
    required this.avatarEmoji,
    required this.holyPoints,
    required this.isCurrentUser,
  });
  final int rank;
  final String displayName;
  final String avatarEmoji;
  final int holyPoints;
  final bool isCurrentUser;
}

class _TeacherQuest {
  const _TeacherQuest({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.reward,
    required this.isComplete,
    required this.biblePassage,
  });
  final String title;
  final String description;
  final String dueDate;
  final String reward;
  final bool isComplete;
  final String biblePassage;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const List<_ClassMember> _mockLeaderboard = [
  _ClassMember(rank: 1, displayName: 'Maria G.', avatarEmoji: '👧', holyPoints: 1240, isCurrentUser: false),
  _ClassMember(rank: 2, displayName: 'Thomas H.', avatarEmoji: '👦', holyPoints: 1180, isCurrentUser: false),
  _ClassMember(rank: 3, displayName: 'You', avatarEmoji: '🧒', holyPoints: 1050, isCurrentUser: true),
  _ClassMember(rank: 4, displayName: 'Sarah K.', avatarEmoji: '👩', holyPoints: 980, isCurrentUser: false),
  _ClassMember(rank: 5, displayName: 'James F.', avatarEmoji: '👨', holyPoints: 920, isCurrentUser: false),
];

const List<_TeacherQuest> _teacherQuests = [
  _TeacherQuest(
    title: 'The Beatitudes',
    description: 'Read and memorize the Beatitudes from the Sermon on the Mount.',
    dueDate: 'Due: Sunday',
    reward: '+50 Holy Points',
    isComplete: false,
    biblePassage: 'Matthew 5:3-12',
  ),
  _TeacherQuest(
    title: 'The Our Father',
    description: 'Explain the meaning of each petition in the Lord\'s Prayer.',
    dueDate: 'Due: Monday',
    reward: '+40 Holy Points',
    isComplete: true,
    biblePassage: 'Matthew 6:9-13',
  ),
  _TeacherQuest(
    title: 'The Good Samaritan',
    description: 'Read the parable and identify who your neighbour is in your life.',
    dueDate: 'Due: Wednesday',
    reward: '+60 Holy Points',
    isComplete: false,
    biblePassage: 'Luke 10:25-37',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class SchoolHubScreen extends ConsumerStatefulWidget {
  const SchoolHubScreen({super.key});

  @override
  ConsumerState<SchoolHubScreen> createState() => _SchoolHubScreenState();
}

class _SchoolHubScreenState extends ConsumerState<SchoolHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _inClass = true;
  String _classCode = 'GRACE2024';
  bool _weeklyView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'School Hub',
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
            Tab(text: 'Class', icon: Icon(Icons.school, size: 18)),
            Tab(text: 'Quests', icon: Icon(Icons.assignment, size: 18)),
            Tab(text: 'Events', icon: Icon(Icons.event, size: 18)),
          ],
        ),
      ),
      body: _inClass
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildClassTab(),
                _buildQuestsTab(),
                _buildEventsTab(),
              ],
            )
          : _buildJoinClass(),
    );
  }

  // ── Join class view ────────────────────────────────────────────────────────────

  Widget _buildJoinClass() {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏫', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Join Your Class',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontFamily: 'Cinzel',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the code your teacher gave you',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              hintText: 'CLASS CODE',
              hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF1A0A2E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _inClass = true),
              child: const Text(
                'Join Class',
                style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Class tab ─────────────────────────────────────────────────────────────────

  Widget _buildClassTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Class info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A1A), Color(0xFF0D2A0D)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏫 St. Joseph Catholic School',
                style: TextStyle(
                  color: Color(0xFF27AE60),
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Text(
                'Grade 7 Religion · Ms. O\'Brien',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Class Code: $_classCode',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 16),

        // Leaderboard toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Class Leaderboard',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'Cinzel',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _weeklyView = true),
                  child: Text(
                    'Week',
                    style: TextStyle(
                      color: _weeklyView ? const Color(0xFFFFD700) : Colors.white54,
                      fontWeight: _weeklyView ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Text(' | ', style: TextStyle(color: Colors.white24)),
                GestureDetector(
                  onTap: () => setState(() => _weeklyView = false),
                  child: Text(
                    'Month',
                    style: TextStyle(
                      color: !_weeklyView ? const Color(0xFFFFD700) : Colors.white54,
                      fontWeight: !_weeklyView ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._mockLeaderboard.asMap().entries.map(
              (e) => _LeaderboardRow(member: e.value).animate().fadeIn(delay: (e.key * 50).ms),
            ),

        const SizedBox(height: 16),

        // Class challenge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C1810),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE67E22).withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 Class Challenge',
                style: TextStyle(
                  color: Color(0xFFE67E22),
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Everyone completes 3 prayer quests this week → Bonus +100 HP for all!',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0.62,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFFE67E22),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '62%',
                    style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Quests tab ────────────────────────────────────────────────────────────────

  Widget _buildQuestsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Teacher-Assigned Quests',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Complete these for extra Holy Points!',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ..._teacherQuests.asMap().entries.map(
              (e) => _QuestCard(quest: e.value).animate().fadeIn(delay: (e.key * 80).ms),
            ),
      ],
    );
  }

  // ── Events tab ────────────────────────────────────────────────────────────────

  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _EventCard(
          title: 'Catholic Schools Week',
          subtitle: 'Special XP multiplier all week!',
          date: 'Jan 26 – Feb 1',
          emoji: '⭐',
          isActive: true,
        ),
        _EventCard(
          title: 'First Friday Mass',
          subtitle: 'Attend with your class for bonus Holy Points',
          date: 'First Friday of each month',
          emoji: '⛪',
          isActive: false,
        ),
        _EventCard(
          title: 'Scripture Memorization Contest',
          subtitle: 'Memorize 10 verses → win a Saint Relic!',
          date: 'Ongoing',
          emoji: '📖',
          isActive: true,
        ),
        _EventCard(
          title: 'Lenten Fast Challenge',
          subtitle: 'Log your fasting and prayer during Lent',
          date: 'Lent Season',
          emoji: '✝️',
          isActive: false,
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.member});
  final _ClassMember member;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (member.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFBEC2CB),
      3 => const Color(0xFFCD7F32),
      _ => Colors.white54,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: member.isCurrentUser
            ? const Color(0xFF3498DB).withOpacity(0.15)
            : const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: member.isCurrentUser
              ? const Color(0xFF3498DB).withOpacity(0.5)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${member.rank}',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(member.avatarEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              member.displayName + (member.isCurrentUser ? ' (You)' : ''),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            '${member.holyPoints} HP',
            style: const TextStyle(
              color: Color(0xFF9B59B6),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});
  final _TeacherQuest quest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quest.isComplete
            ? const Color(0xFF27AE60).withOpacity(0.1)
            : const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quest.isComplete
              ? const Color(0xFF27AE60).withOpacity(0.5)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                quest.isComplete ? Icons.check_circle : Icons.assignment,
                color: quest.isComplete ? const Color(0xFF27AE60) : const Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quest.title,
                  style: TextStyle(
                    color: quest.isComplete ? const Color(0xFF27AE60) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                quest.dueDate,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(quest.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '📖 ${quest.biblePassage}',
                  style: const TextStyle(color: Color(0xFF3498DB), fontSize: 10),
                ),
              ),
              const Spacer(),
              Text(
                quest.reward,
                style: const TextStyle(color: Color(0xFF9B59B6), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.emoji,
    required this.isActive,
  });
  final String title;
  final String subtitle;
  final String date;
  final String emoji;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFFD700).withOpacity(0.08)
            : const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFFD700).withOpacity(0.4)
              : Colors.white12,
        ),
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
                  style: TextStyle(
                    color: isActive ? const Color(0xFFFFD700) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
