import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/presentation/providers/ai_chat_provider.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

// ── Guardian saints for avatar ─────────────────────────────────────────────────

const _guardianSaints = [
  (name: 'St. Michael', emoji: '⚔️'),
  (name: 'St. Joseph', emoji: '🪵'),
  (name: 'Our Lady', emoji: '💙'),
  (name: 'St. Francis', emoji: '🌿'),
  (name: 'St. Therese', emoji: '🌹'),
  (name: 'St. Peter', emoji: '🔑'),
  (name: 'St. John', emoji: '✍️'),
];

// ── Starter prompts ────────────────────────────────────────────────────────────

const _starterPrompts = [
  (emoji: '🙏', text: 'Help me write a prayer'),
  (emoji: '📖', text: 'Explain this Bible verse to me'),
  (emoji: '❓', text: 'What does the Church teach about...'),
  (emoji: '🌟', text: 'Tell me about a saint'),
  (emoji: '💭', text: 'I\'m feeling sad / confused / happy'),
];

// ── Prayer companion screen ────────────────────────────────────────────────────

class PrayerCompanionScreen extends ConsumerStatefulWidget {
  const PrayerCompanionScreen({super.key});

  @override
  ConsumerState<PrayerCompanionScreen> createState() =>
      _PrayerCompanionScreenState();
}

class _PrayerCompanionScreenState
    extends ConsumerState<PrayerCompanionScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final messages = ref.watch(aiChatNotifierProvider);

    // Age gate
    final isLocked = user != null &&
        (user.ageGroup < 2 || !user.parentalConsentGiven);

    final dayOfWeek = DateTime.now().weekday - 1;
    final guardian = _guardianSaints[dayOfWeek % _guardianSaints.length];

    if (isLocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A0A00),
        appBar: _buildAppBar(context, guardian),
        body: _LockedState(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
      appBar: _buildAppBar(context, guardian),
      body: Column(
        children: [
          // Candle glow header
          _ParchmentHeader(guardianName: guardian.name),

          // Messages area
          Expanded(
            child: messages.isEmpty
                ? _StarterPromptsGrid(
                    onPromptTap: _sendMessage,
                  )
                : _ScrollingMessages(
                    messages: messages,
                    scrollController: _scrollController,
                    guardianEmoji: guardian.emoji,
                  ),
          ),

          // Input bar
          _ParchmentInputBar(
            controller: _controller,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ({String name, String emoji}) guardian) {
    return AppBar(
      backgroundColor: const Color(0xFF2A1505),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.gold),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.5),
              color: AppColors.deepPurple,
            ),
            child: Center(
              child: Text(guardian.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prayer Companion',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.goldLight,
                ),
              ),
              Text(
                'Guide: ${guardian.name}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.midGrey,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (ref.watch(aiChatNotifierProvider).isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.midGrey),
            onPressed: _confirmClear,
          ),
      ],
    );
  }

  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    setState(() => _isSending = true);

    await ref.read(aiChatNotifierProvider.notifier).sendMessage(text);

    if (mounted) {
      setState(() => _isSending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _confirmClear() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(
          'Clear Conversation?',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        content: Text(
          'This conversation is private and not stored.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.midGrey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(aiChatNotifierProvider.notifier).clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.crimson)),
          ),
        ],
      ),
    );
  }
}

// ── Parchment header ───────────────────────────────────────────────────────────

class _ParchmentHeader extends StatelessWidget {
  final String guardianName;

  const _ParchmentHeader({required this.guardianName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: Color(0xFF2A1505),
        border: Border(
            bottom: BorderSide(color: AppColors.goldDark, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: AppColors.gold, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Ask $guardianName anything about faith, prayer, or the saints',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.blessings.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withOpacity(0.15),
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                  color: AppColors.forestGreen.withOpacity(0.4)),
            ),
            child: Text(
              'Private',
              style: AppTextStyles.badge.copyWith(
                color: AppColors.forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Starter prompts grid ───────────────────────────────────────────────────────

class _StarterPromptsGrid extends StatelessWidget {
  final void Function(String) onPromptTap;

  const _StarterPromptsGrid({required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.deepPurple.withOpacity(0.3),
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_stories, color: AppColors.gold, size: 36),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2500.ms, color: AppColors.goldLight.withOpacity(0.2)),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Start a conversation',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Ask anything about the Catholic faith',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          ..._starterPrompts.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onPromptTap(e.value.text),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A10).withOpacity(0.8),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                        color: AppColors.goldDark.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(e.value.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          e.value.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.parchment,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: AppColors.goldDark, size: 12),
                    ],
                  ),
                ),
              )
                  .animate(delay: (e.key * 80).ms)
                  .fadeIn()
                  .slideX(begin: -0.1),
            );
          }),
        ],
      ),
    );
  }
}

// ── Scrolling messages ─────────────────────────────────────────────────────────

class _ScrollingMessages extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final String guardianEmoji;

  const _ScrollingMessages({
    required this.messages,
    required this.scrollController,
    required this.guardianEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        return _ScrollBubble(
          message: messages[i],
          guardianEmoji: guardianEmoji,
        ).animate(delay: 30.ms).fadeIn();
      },
    );
  }
}

// ── Scroll bubble ──────────────────────────────────────────────────────────────

class _ScrollBubble extends StatelessWidget {
  final ChatMessage message;
  final String guardianEmoji;

  const _ScrollBubble({required this.message, required this.guardianEmoji});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.sm,
          left: isUser ? 56 : 0,
          right: isUser ? 0 : 56,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.deepPurple.withOpacity(0.8)
              : message.isError
                  ? AppColors.crimson.withOpacity(0.12)
                  : const Color(0xFF2A1A05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(
                isUser ? AppSpacing.radiusMd : AppSpacing.radiusXs),
            bottomRight: Radius.circular(
                isUser ? AppSpacing.radiusXs : AppSpacing.radiusMd),
          ),
          border: !isUser
              ? Border.all(
                  color: message.isError
                      ? AppColors.crimson.withOpacity(0.3)
                      : AppColors.goldDark.withOpacity(0.25),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(guardianEmoji,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    'Prayer Companion',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.blessings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message.content,
              style: AppTextStyles.chatText.copyWith(
                color: isUser
                    ? AppColors.white
                    : message.isError
                        ? AppColors.crimson
                        : AppColors.parchment,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Parchment input bar ────────────────────────────────────────────────────────

class _ParchmentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final void Function([String?]) onSend;

  const _ParchmentInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Color(0xFF2A1505),
        border:
            Border(top: BorderSide(color: AppColors.goldDark, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.parchment,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Write a prayer, ask a question...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.midGrey,
                    fontStyle: FontStyle.italic,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: const BorderSide(
                        color: AppColors.goldDark, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: const BorderSide(
                        color: AppColors.goldDark, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: const BorderSide(
                        color: AppColors.gold, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A0A00),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: isSending ? null : () => onSend(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSending
                      ? AppColors.darkElevated
                      : AppColors.deepPurple,
                  border: Border.all(
                      color: isSending
                          ? AppColors.midGrey
                          : AppColors.gold.withOpacity(0.5)),
                ),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: AppColors.gold, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Locked state ───────────────────────────────────────────────────────────────

class _LockedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.family_restroom,
                color: AppColors.blessings, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Parent Approval Needed',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.blessings,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The Prayer Companion is an AI chat feature.\n\n'
              'To unlock it, ask your parent or guardian to enable it in the Parent Gate.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.midGrey,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                    color: AppColors.goldDark.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: AppColors.goldDark, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ask your parent to open the Parent Gate',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.parchment,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
