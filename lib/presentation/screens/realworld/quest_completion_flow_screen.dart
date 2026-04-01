import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quest/real_world_quest_model.dart';
import 'package:kingdomcome/presentation/providers/real_world_quest_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class QuestCompletionFlowScreen extends ConsumerStatefulWidget {
  final String questId;
  const QuestCompletionFlowScreen({super.key, required this.questId});

  @override
  ConsumerState<QuestCompletionFlowScreen> createState() =>
      _QuestCompletionFlowScreenState();
}

class _QuestCompletionFlowScreenState
    extends ConsumerState<QuestCompletionFlowScreen> {
  int _currentStep = 0;
  final TextEditingController _reflectionController = TextEditingController();
  int _starRating = 0;
  int _selectedMoodIndex = 2; // default: neutral
  bool _honorConfirmed = false;
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _autoApproved = false;

  static const _moods = ['😢', '😕', '😐', '😊', '😄'];
  static const _moodLabels = ['Sad', 'Unsure', 'Okay', 'Happy', 'Amazing'];

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  RealWorldQuestModel? _findQuest() {
    final questState = ref.read(realWorldQuestNotifierProvider);
    try {
      return questState.quests.firstWhere((q) => q.id == widget.questId);
    } catch (_) {
      return null;
    }
  }

  bool _needsProofStep(RealWorldQuestModel quest) {
    return quest.verification == RealWorldVerification.photoScan ||
        quest.verification == RealWorldVerification.honorSystem ||
        quest.verification == RealWorldVerification.appTimer;
  }

  bool get _isAutoApproved {
    final quest = _findQuest();
    if (quest == null) return false;
    return quest.verification == RealWorldVerification.honorSystem ||
        quest.verification == RealWorldVerification.appTimer;
  }

  Future<void> _submitCompletion() async {
    setState(() => _isSubmitting = true);

    final success = await ref
        .read(realWorldQuestNotifierProvider.notifier)
        .submitCompletion(
          widget.questId,
          _reflectionController.text.trim().isEmpty
              ? null
              : _reflectionController.text.trim(),
          null, // photo URL would come from camera capture
        );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = success;
        _autoApproved = _isAutoApproved && success;
        if (success) _currentStep = _needsProofStep(_findQuest()!) ? 2 : 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questState = ref.watch(realWorldQuestNotifierProvider);
    RealWorldQuestModel? quest;
    try {
      quest = questState.quests.firstWhere((q) => q.id == widget.questId);
    } catch (_) {
      quest = null;
    }

    if (quest == null) {
      return Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: const Center(
          child: Text('Quest not found.',
              style: TextStyle(color: AppColors.ivory)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.4,
            colors: [
              Color(0xFF1A0A2E),
              AppColors.darkSurface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _FlowTopBar(
                questTitle: quest.title,
                questEmoji: quest.iconEmoji,
                currentStep: _submitted ? 2 : _currentStep,
                totalSteps: _needsProofStep(quest) ? 3 : 2,
                onClose: () => context.pop(),
              ),

              // Step content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _submitted
                      ? _SubmittedStep(
                          key: const ValueKey('submitted'),
                          quest: quest,
                          autoApproved: _autoApproved,
                        )
                      : _currentStep == 0
                          ? _ReflectionStep(
                              key: const ValueKey('reflection'),
                              quest: quest,
                              controller: _reflectionController,
                              starRating: _starRating,
                              selectedMoodIndex: _selectedMoodIndex,
                              moods: _moods,
                              moodLabels: _moodLabels,
                              onStarTap: (s) =>
                                  setState(() => _starRating = s),
                              onMoodTap: (i) =>
                                  setState(() => _selectedMoodIndex = i),
                            )
                          : _ProofStep(
                              key: const ValueKey('proof'),
                              quest: quest,
                              honorConfirmed: _honorConfirmed,
                              onHonorChanged: (v) =>
                                  setState(() => _honorConfirmed = v),
                            ),
                ),
              ),

              // Bottom buttons
              if (!_submitted)
                _FlowBottomBar(
                  currentStep: _currentStep,
                  needsProofStep: _needsProofStep(quest),
                  isSubmitting: _isSubmitting,
                  canProceedProof: _canProceedProof(quest),
                  onBack: _currentStep > 0
                      ? () => setState(() => _currentStep--)
                      : null,
                  onNext: () {
                    if (_currentStep == 0) {
                      // Move to proof step (or submit directly)
                      if (_needsProofStep(quest!)) {
                        setState(() => _currentStep = 1);
                      } else {
                        _submitCompletion();
                      }
                    } else {
                      // Proof step → submit
                      _submitCompletion();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceedProof(RealWorldQuestModel quest) {
    if (!_needsProofStep(quest)) return true;
    if (quest.verification == RealWorldVerification.honorSystem) {
      return _honorConfirmed;
    }
    return true; // photo and timer steps can always proceed
  }
}

// ---------------------------------------------------------------------------
// Top bar with step indicator
// ---------------------------------------------------------------------------

class _FlowTopBar extends StatelessWidget {
  final String questTitle;
  final String questEmoji;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onClose;

  const _FlowTopBar({
    required this.questTitle,
    required this.questEmoji,
    required this.currentStep,
    required this.totalSteps,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(questEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.ivory,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Step indicator dots
                Row(
                  children: List.generate(
                    totalSteps,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 4),
                      width: i == currentStep ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= currentStep
                            ? AppColors.gold
                            : AppColors.darkElevated,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.midGrey),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Reflection
// ---------------------------------------------------------------------------

class _ReflectionStep extends StatelessWidget {
  final RealWorldQuestModel quest;
  final TextEditingController controller;
  final int starRating;
  final int selectedMoodIndex;
  final List<String> moods;
  final List<String> moodLabels;
  final ValueChanged<int> onStarTap;
  final ValueChanged<int> onMoodTap;

  const _ReflectionStep({
    super.key,
    required this.quest,
    required this.controller,
    required this.starRating,
    required this.selectedMoodIndex,
    required this.moods,
    required this.moodLabels,
    required this.onStarTap,
    required this.onMoodTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did it go?',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.goldLight,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

          const SizedBox(height: AppSpacing.md),

          // Journal entry
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.darkElevated),
            ),
            child: TextField(
              controller: controller,
              maxLines: 5,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.ivory,
              ),
              decoration: InputDecoration(
                hintText: 'Tell us about your experience...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.midGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.lg),

          // Star rating
          Text(
            'How good do you feel about this?',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => onStarTap(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < starRating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: i < starRating
                        ? AppColors.faithCoins
                        : AppColors.darkElevated,
                    size: 36,
                  ).animate(delay: (i * 50).ms).scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                      ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Mood picker
          Text(
            'Pick your mood:',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              moods.length,
              (i) => GestureDetector(
                onTap: () => onMoodTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: i == selectedMoodIndex
                        ? AppColors.deepPurple
                        : Colors.transparent,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: i == selectedMoodIndex
                          ? AppColors.purpleLight
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        moods[i],
                        style: TextStyle(
                          fontSize: i == selectedMoodIndex ? 32 : 24,
                        ),
                      ),
                      Text(
                        moodLabels[i],
                        style: AppTextStyles.labelSmall.copyWith(
                          color: i == selectedMoodIndex
                              ? AppColors.goldLight
                              : AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Proof
// ---------------------------------------------------------------------------

class _ProofStep extends StatelessWidget {
  final RealWorldQuestModel quest;
  final bool honorConfirmed;
  final ValueChanged<bool> onHonorChanged;

  const _ProofStep({
    super.key,
    required this.quest,
    required this.honorConfirmed,
    required this.onHonorChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (quest.verification) {
      case RealWorldVerification.photoScan:
        return _PhotoProofContent(quest: quest);
      case RealWorldVerification.honorSystem:
        return _HonorSystemContent(
          quest: quest,
          confirmed: honorConfirmed,
          onChanged: onHonorChanged,
        );
      case RealWorldVerification.appTimer:
        return _TimerProofContent(quest: quest);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PhotoProofContent extends StatelessWidget {
  final RealWorldQuestModel quest;
  const _PhotoProofContent({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Text('📸', style: TextStyle(fontSize: 64))
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 600.ms,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Take a Photo as Proof!',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Use the Masterpiece Scanner to capture your good deed.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          KingdomButton(
            label: 'Open Masterpiece Scanner',
            icon: Icons.camera_alt_rounded,
            onPressed: () {
              // Navigate to the arts/scanner screen
              context.push('/arts/scanner');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Or skip photo and submit without proof.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.midGrey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HonorSystemContent extends StatelessWidget {
  final RealWorldQuestModel quest;
  final bool confirmed;
  final ValueChanged<bool> onChanged;

  const _HonorSystemContent({
    required this.quest,
    required this.confirmed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            confirmed ? '✅' : '🤝',
            style: const TextStyle(fontSize: 64),
          )
              .animate(key: ValueKey(confirmed))
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 500.ms,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'On Your Honor',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'God sees everything you do — even when no one else does. '
            'Be honest with yourself and with Him.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: () => onChanged(!confirmed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: confirmed
                    ? AppColors.forestGreen.withOpacity(0.2)
                    : AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: confirmed
                      ? AppColors.forestGreen
                      : AppColors.darkElevated,
                  width: confirmed ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    confirmed
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color:
                        confirmed ? AppColors.forestGreen : AppColors.midGrey,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'I confirm on my honor that I completed this quest ✓',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: confirmed ? AppColors.ivory : AppColors.midGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerProofContent extends ConsumerWidget {
  final RealWorldQuestModel quest;
  const _TimerProofContent({required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastState = ref.watch(digitalFastNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Text('⏱️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Timer Complete!',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total gadget-free time today: '
            '${fastState.totalGadgetFreeMinutesToday} minutes',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.ivory,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The timer has automatically recorded your session.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar
// ---------------------------------------------------------------------------

class _FlowBottomBar extends StatelessWidget {
  final int currentStep;
  final bool needsProofStep;
  final bool isSubmitting;
  final bool canProceedProof;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _FlowBottomBar({
    required this.currentStep,
    required this.needsProofStep,
    required this.isSubmitting,
    required this.canProceedProof,
    required this.onBack,
    required this.onNext,
  });

  String get _nextLabel {
    if (currentStep == 0 && !needsProofStep) return 'Submit Quest';
    if (currentStep == 1) return 'Submit Quest';
    return 'Next Step';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        border: Border(
          top: BorderSide(color: AppColors.darkElevated),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            KingdomButton(
              label: 'Back',
              isPrimary: false,
              minWidth: 100,
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: KingdomButton(
              label: _nextLabel,
              icon: isSubmitting ? null : Icons.check_rounded,
              isLoading: isSubmitting,
              onPressed: (canProceedProof && !isSubmitting) ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Submitted
// ---------------------------------------------------------------------------

class _SubmittedStep extends ConsumerWidget {
  final RealWorldQuestModel quest;
  final bool autoApproved;

  const _SubmittedStep({
    super.key,
    required this.quest,
    required this.autoApproved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Main animation / icon
          Text(
            autoApproved ? '🎉' : '⭐',
            style: const TextStyle(fontSize: 80),
          )
              .animate(onPlay: (c) => c.repeat(count: 3))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.15, 1.15),
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .then()
              .scale(
                begin: const Offset(1.15, 1.15),
                end: const Offset(1, 1),
                duration: 200.ms,
              ),

          const SizedBox(height: AppSpacing.md),

          Text(
            autoApproved ? 'Quest Complete!' : 'Quest Submitted!',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.goldLight,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.1),

          const SizedBox(height: AppSpacing.md),

          if (autoApproved) ...[
            // Immediate reward
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldDark.withOpacity(0.3),
                    AppColors.darkCard,
                  ],
                ),
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(color: AppColors.gold.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    'Reward Earned!',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (quest.holyPointsReward > 0) ...[
                        Text(
                          '+${quest.holyPointsReward} ✨',
                          style: AppTextStyles.statNumber.copyWith(
                            color: AppColors.holyPoints,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      if (quest.faithCoinsReward > 0)
                        Text(
                          '+${quest.faithCoinsReward} 🪙',
                          style: AppTextStyles.statNumber.copyWith(
                            color: AppColors.faithCoins,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn().scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),
          ] else ...[
            // Waiting for parent
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.goldDark.withOpacity(0.15),
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Text('👨‍👩‍👧',
                      style: TextStyle(fontSize: 36)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Waiting for your parent to confirm...',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.goldLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ask them to check the Parent Gate!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.midGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Patient virtue reinforcement
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Text(
                      '"Be patient and wait for the Lord." — Psalm 37:7',
                      style: AppTextStyles.scriptureQuote.copyWith(
                        color: AppColors.ivory.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: AppSpacing.md),

            Text(
              'While you wait, check The Ark for more adventures!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.midGrey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 500.ms).fadeIn(),
          ],

          const SizedBox(height: AppSpacing.xl),

          KingdomButton(
            label: autoApproved ? 'Back to Quests' : 'Go to The Ark',
            icon:
                autoApproved ? Icons.list_alt_rounded : Icons.explore_rounded,
            onPressed: () {
              if (autoApproved) {
                context.go('/realworld');
              } else {
                context.go('/ark');
              }
            },
          ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.2),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
