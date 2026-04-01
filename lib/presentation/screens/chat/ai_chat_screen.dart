import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/presentation/providers/ai_chat_provider.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final messages = ref.watch(aiChatNotifierProvider);
    final starterPrompts = ref.watch(starterPromptsProvider);

    // Age gate check: young users without parental consent cannot use AI chat
    final requiresConsent =
        user != null && user.ageGroup == 1 && !user.parentalConsentGiven;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
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
              child: const Icon(Icons.church, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Magisterium Guide',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
                Text(
                  'Catholic AI Companion',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.midGrey),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.darkCard,
                    title: Text(
                      'Clear Conversation?',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.ivory,
                      ),
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
              },
            ),
        ],
      ),
      body: requiresConsent
          ? _AgeGateMessage()
          : Column(
              children: [
                // Illuminated manuscript header
                _ManuscriptHeader(),

                // Messages
                Expanded(
                  child: messages.isEmpty
                      ? _StarterPromptsView(
                          prompts: starterPrompts,
                          onPromptTap: _sendMessage,
                        )
                      : _MessageList(
                          messages: messages,
                          scrollController: _scrollController,
                        ),
                ),

                // Input bar
                _InputBar(
                  controller: _messageController,
                  isSending: _isSending,
                  onSend: _sendMessage,
                ),
              ],
            ),
    );
  }

  Future<void> _sendMessage([String? overrideMessage]) async {
    final text = overrideMessage ?? _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    await ref.read(aiChatNotifierProvider.notifier).sendMessage(text);

    if (mounted) {
      setState(() => _isSending = false);
      // Scroll to bottom
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
}

// ── Manuscript header ─────────────────────────────────────────────────────────

class _ManuscriptHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.deepPurple.withOpacity(0.3),
        border: const Border(
          bottom: BorderSide(color: AppColors.goldDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: AppColors.gold, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Ask anything about Catholic faith, prayer, or the saints',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.goldLight.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Starter prompts ───────────────────────────────────────────────────────────

class _StarterPromptsView extends StatelessWidget {
  final List<String> prompts;
  final void Function(String) onPromptTap;

  const _StarterPromptsView({required this.prompts, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(Icons.church, color: AppColors.gold, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ask Your Guide',
            style:
                AppTextStyles.headlineLarge.copyWith(color: AppColors.goldLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start a conversation about the Catholic faith',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...prompts.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PromptChip(
                prompt: e.value,
                onTap: () => onPromptTap(e.value),
              ).animate(delay: (e.key * 80).ms).fadeIn().slideX(begin: -0.1),
            );
          }),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String prompt;
  final VoidCallback onTap;

  const _PromptChip({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.deepPurple.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                color: AppColors.deepPurple, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                prompt,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.midGrey, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const _MessageList(
      {required this.messages, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final message = messages[i];
        return _MessageBubble(
          message: message,
        ).animate(delay: 50.ms).fadeIn();
      },
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.sm,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.deepPurple
              : message.isError
                  ? AppColors.crimson.withOpacity(0.15)
                  : AppColors.darkCard,
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
                      ? AppColors.crimson.withOpacity(0.4)
                      : AppColors.goldDark.withOpacity(0.2),
                )
              : null,
          // Scroll/parchment aesthetic for AI messages
          image: !isUser && !message.isError
              ? const DecorationImage(
                  image: AssetImage('assets/images/ui/parchment_texture.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
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
                  const Icon(Icons.church, color: AppColors.gold, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Magisterium Guide',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message.content,
              style: AppTextStyles.chatText.copyWith(
                color: isUser ? AppColors.white : AppColors.parchment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.goldDark)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.ivory,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask about faith, prayer, saints...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.midGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: const BorderSide(color: AppColors.darkElevated),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: const BorderSide(color: AppColors.darkElevated),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide:
                        const BorderSide(color: AppColors.gold, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: isSending ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSending
                      ? AppColors.midGrey
                      : AppColors.deepPurple,
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
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

// ── Age gate ──────────────────────────────────────────────────────────────────

class _AgeGateMessage extends StatelessWidget {
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
              'Parental Consent Required',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.blessings,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'To use the AI Chat feature, your parent or guardian needs to approve your account. '
              'Please ask them to check their email.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.midGrey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
