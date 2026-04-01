import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/ark/ark_node_model.dart';
import 'package:kingdomcome/presentation/providers/ark_provider.dart';
import 'package:kingdomcome/routing/route_names.dart';

/// Full-screen node detail for any Ark journey node.
///
/// Adapts its content based on [ArkNodeType]:
/// - story: thumbnail, Watch + Listen buttons, reward preview
/// - verse: NABRE verse text, Memorize mini-game button
/// - dailyBread: large verse card + reflection, share button
/// - chapter: book/chapter info, Read with me / Read alone
/// - quiz: topic, question count, time estimate
/// - locked: shows unlock condition
class ArkNodeDetailScreen extends ConsumerWidget {
  final String nodeId;

  const ArkNodeDetailScreen({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(arkNotifierProvider);

    return nodesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.darkSurface,
        appBar: AppBar(backgroundColor: AppColors.purpleDark),
        body: Center(
          child: Text(e.toString(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory)),
        ),
      ),
      data: (nodes) {
        final node = nodes.firstWhere(
          (n) => n.id == nodeId,
          orElse: () => nodes.first,
        );
        return _NodeDetailContent(node: node);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main content
// ─────────────────────────────────────────────────────────────────────────────

class _NodeDetailContent extends ConsumerWidget {
  final ArkNodeModel node;
  const _NodeDetailContent({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.goldLight),
          onPressed: () => context.pop(),
        ),
        title: Text(
          node.section.displayName,
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        actions: [
          if (node.isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: Icon(Icons.verified, color: AppColors.gold, size: 22),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Node type badge + title
            _NodeHeader(node: node),
            const SizedBox(height: AppSpacing.lg),

            // Type-specific content
            _buildTypeContent(context, ref),

            const SizedBox(height: AppSpacing.lg),

            // Reward preview
            if (node.nodeType != ArkNodeType.locked)
              _RewardPreview(node: node),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeContent(BuildContext context, WidgetRef ref) {
    switch (node.nodeType) {
      case ArkNodeType.story:
        return _StoryContent(node: node);
      case ArkNodeType.verse:
        return _VerseContent(node: node);
      case ArkNodeType.dailyBread:
        return _DailyBreadContent(node: node);
      case ArkNodeType.chapter:
        return _ChapterContent(node: node);
      case ArkNodeType.quiz:
        return _QuizContent(node: node);
      case ArkNodeType.locked:
        return _LockedContent(node: node);
    }
  }
}

// ── Node Header ───────────────────────────────────────────────────────────────

class _NodeHeader extends StatelessWidget {
  final ArkNodeModel node;
  const _NodeHeader({required this.node});

  Color get _typeColor {
    switch (node.nodeType) {
      case ArkNodeType.story:
        return AppColors.purpleLight;
      case ArkNodeType.verse:
        return AppColors.holyPoints;
      case ArkNodeType.quiz:
        return AppColors.blessings;
      case ArkNodeType.dailyBread:
        return AppColors.faithCoins;
      case ArkNodeType.chapter:
        return AppColors.deepPurple;
      case ArkNodeType.locked:
        return AppColors.midGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.15),
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(color: _typeColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(node.nodeType.emoji,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                node.nodeType.displayName.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: _typeColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Title
        Text(
          node.title,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.ivory,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Description
        Text(
          node.description,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }
}

// ── Story Content ─────────────────────────────────────────────────────────────

class _StoryContent extends ConsumerWidget {
  final ArkNodeModel node;
  const _StoryContent({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Thumbnail
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
          ),
          child: node.thumbnailUrl != null
              ? ClipRRect(
                  borderRadius: AppSpacing.borderRadiusLg,
                  child: Image.network(
                    node.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ThumbnailPlaceholder(
                        emoji: node.nodeType.emoji),
                  ),
                )
              : _ThumbnailPlaceholder(emoji: node.nodeType.emoji),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.lg),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Watch Story',
                icon: Icons.play_circle_filled,
                color: AppColors.crimson,
                onTap: node.heygenVideoUrl != null
                    ? () => context.push(
                        RouteNames.arkStoryViewerPath(node.id),
                        extra: node)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionButton(
                label: 'Listen',
                icon: Icons.headphones,
                color: AppColors.holyPoints,
                onTap: node.sunoAudioUrl != null
                    ? () => _showAudioPlayer(context)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAudioPlayer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio player coming soon')),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  final String emoji;
  const _ThumbnailPlaceholder({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Story Preview',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.midGrey),
          ),
        ],
      ),
    );
  }
}

// ── Verse Content ─────────────────────────────────────────────────────────────

class _VerseContent extends ConsumerWidget {
  final ArkNodeModel node;
  const _VerseContent({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Verse card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1845), Color(0xFF1A0F30)],
            ),
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.holyPoints.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.holyPoints.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.format_quote, color: AppColors.holyPoints, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                node.description.isNotEmpty
                    ? node.description
                    : 'Verse text will appear here.',
                style: AppTextStyles.scriptureQuote.copyWith(
                  color: AppColors.parchment,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                node.chapterRef ?? node.title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.holyPoints,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'NABRE',
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.lg),
        _ActionButton(
          label: 'Memorize This Verse',
          icon: Icons.psychology,
          color: AppColors.holyPoints,
          onTap: () => _launchMemorizeGame(context, ref),
        ),
      ],
    );
  }

  void _launchMemorizeGame(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemorizeGame(node: node),
    );
  }
}

class _MemorizeGame extends ConsumerStatefulWidget {
  final ArkNodeModel node;
  const _MemorizeGame({required this.node});

  @override
  ConsumerState<_MemorizeGame> createState() => _MemorizeGameState();
}

class _MemorizeGameState extends ConsumerState<_MemorizeGame> {
  final _controller = TextEditingController();
  bool _revealed = false;
  bool _completed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.warmGrey,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Memorize This Verse',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.goldLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (!_revealed)
            Text(
              'Type the verse from memory, then tap Reveal to check.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.sm),
          if (!_completed) ...[
            TextField(
              controller: _controller,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write the verse here...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: const BorderSide(color: AppColors.darkElevated),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: const BorderSide(color: AppColors.darkElevated),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: const BorderSide(color: AppColors.holyPoints),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _revealed = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepPurple,
                      foregroundColor: AppColors.goldLight,
                    ),
                    child: const Text('Reveal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _completed = true);
                      await ref
                          .read(arkNotifierProvider.notifier)
                          .completeNode(widget.node.id);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('I Know It!'),
                  ),
                ),
              ],
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
          if (_revealed && !_completed) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.holyPoints.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.holyPoints.withOpacity(0.3)),
              ),
              child: Text(
                widget.node.description.isNotEmpty
                    ? widget.node.description
                    : 'Verse text here — ${widget.node.chapterRef ?? widget.node.title}',
                style: AppTextStyles.scriptureQuote.copyWith(
                    color: AppColors.parchment),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ── Daily Bread Content ───────────────────────────────────────────────────────

class _DailyBreadContent extends ConsumerWidget {
  final ArkNodeModel node;
  const _DailyBreadContent({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Large verse card
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D2800), Color(0xFF1A1200)],
            ),
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('🍞', style: TextStyle(fontSize: 40)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Daily Bread',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                node.description.isNotEmpty
                    ? node.description
                    : '"I am the bread of life. Whoever comes to me will never hunger."',
                style: AppTextStyles.scriptureQuote.copyWith(
                  color: AppColors.parchment,
                  fontSize: 17,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                node.chapterRef ?? 'John 6:35',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).shimmer(
              duration: 2000.ms,
              color: AppColors.gold.withOpacity(0.1),
            ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Read Aloud',
                icon: Icons.volume_up,
                color: AppColors.gold,
                onTap: () => context.push(RouteNames.dailyBread),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionButton(
                label: 'Full Experience',
                icon: Icons.open_in_full,
                color: AppColors.faithCoins,
                onTap: () => context.push(RouteNames.dailyBread),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Chapter Content ───────────────────────────────────────────────────────────

class _ChapterContent extends StatelessWidget {
  final ArkNodeModel node;
  const _ChapterContent({required this.node});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('📜', style: TextStyle(fontSize: 40)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.chapterRef ?? node.title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Est. 5 min read',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.midGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Read with Me',
                icon: Icons.headphones,
                color: AppColors.purpleLight,
                onTap: () => context.push(
                  RouteNames.interactiveReadingPath(node.id),
                  extra: node,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionButton(
                label: 'Read Alone',
                icon: Icons.menu_book,
                color: AppColors.deepPurple,
                onTap: () => context.push(
                  RouteNames.interactiveReadingPath(node.id),
                  extra: node,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Quiz Content ──────────────────────────────────────────────────────────────

class _QuizContent extends ConsumerWidget {
  final ArkNodeModel node;
  const _QuizContent({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.blessings.withOpacity(0.15),
                AppColors.darkCard,
              ],
            ),
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.blessings.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 40)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Knowledge Quiz',
                style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.blessings),
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuizInfoRow(icon: Icons.quiz, label: '3 Questions'),
              const SizedBox(height: AppSpacing.xs),
              _QuizInfoRow(icon: Icons.timer, label: 'Est. 2 minutes'),
              const SizedBox(height: AppSpacing.xs),
              _QuizInfoRow(
                icon: Icons.topic,
                label: node.section.shortDescription,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.lg),
        _ActionButton(
          label: 'Start Quiz',
          icon: Icons.play_arrow,
          color: AppColors.blessings,
          onTap: () {
            // Navigate to quiz screen — using quizId if present
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz feature coming soon!')),
            );
          },
        ),
      ],
    );
  }
}

class _QuizInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuizInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.midGrey, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.parchment),
        ),
      ],
    );
  }
}

// ── Locked Content ────────────────────────────────────────────────────────────

class _LockedContent extends StatelessWidget {
  final ArkNodeModel node;
  const _LockedContent({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.midGrey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, color: AppColors.midGrey, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Node Locked',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.midGrey),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            node.unlockCondition ??
                'Complete earlier nodes in this section to unlock.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Reward Preview ────────────────────────────────────────────────────────────

class _RewardPreview extends StatelessWidget {
  final ArkNodeModel node;
  const _RewardPreview({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                node.isCompleted
                    ? 'Rewards Earned'
                    : 'Completion Rewards',
                style: AppTextStyles.labelMedium.copyWith(
                  color: node.isCompleted ? AppColors.sage : AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (node.isCompleted) ...[
                const Spacer(),
                const Icon(Icons.check_circle,
                    color: AppColors.sage, size: 16),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RewardChip(
                icon: Icons.star,
                color: AppColors.holyPoints,
                label: '+${node.holyPointsReward} HP',
              ),
              _RewardChip(
                icon: Icons.monetization_on,
                color: AppColors.faithCoins,
                label: '+${node.faithCoinsReward} FC',
              ),
              _RewardChip(
                icon: Icons.auto_awesome,
                color: AppColors.grace,
                label: '+${node.graceReward} GR',
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RewardChip(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Shared Action Button ──────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.darkCard
              : color.withOpacity(0.15),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: disabled
                ? AppColors.midGrey.withOpacity(0.2)
                : color.withOpacity(0.5),
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: disabled ? AppColors.midGrey : color,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: disabled ? AppColors.midGrey : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
