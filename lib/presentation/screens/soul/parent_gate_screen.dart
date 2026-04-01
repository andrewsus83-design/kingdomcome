import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/presentation/providers/soul_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

// ── Parent gate screen ─────────────────────────────────────────────────────────

class ParentGateScreen extends ConsumerStatefulWidget {
  const ParentGateScreen({super.key});

  @override
  ConsumerState<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends ConsumerState<ParentGateScreen> {
  String _input = '';
  bool _wrong = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gateState = ref.watch(parentGateNotifierProvider);

    if (gateState.isUnlocked) {
      return _ParentDashboardView(
        onLock: () => ref.read(parentGateNotifierProvider.notifier).lock(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Parent Area 👋',
          style:
              AppTextStyles.headlineMedium.copyWith(color: AppColors.goldLight),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.family_restroom,
                    color: AppColors.blessings, size: 64)
                .animate()
                .fadeIn(),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'Parent Area',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.goldLight,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'This area is for parents and guardians.\nSolve the math challenge to continue.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.midGrey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: AppSpacing.xl),

            // Math problem
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(
                  color: _wrong
                      ? AppColors.crimson.withOpacity(0.5)
                      : AppColors.goldDark.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    gateState.mathProblem,
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.ivory,
                      fontFamily: 'Cinzel',
                    ),
                    textAlign: TextAlign.center,
                  ).animate(key: ValueKey(gateState.mathProblem)).fadeIn(),

                  const SizedBox(height: AppSpacing.md),

                  // Input display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: _wrong
                            ? AppColors.crimson
                            : _input.isNotEmpty
                                ? AppColors.gold
                                : AppColors.darkElevated,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _input.isEmpty ? '___' : _input,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: _wrong
                                ? AppColors.crimson
                                : _input.isEmpty
                                    ? AppColors.midGrey
                                    : AppColors.ivory,
                          ),
                        ),
                        if (_input.isNotEmpty)
                          const Text(
                            '|',
                            style: TextStyle(
                                color: AppColors.gold, fontSize: 28),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(duration: 600.ms),
                      ],
                    ),
                  ),

                  if (_wrong)
                    Text(
                      'Not quite — try again! (${3 - gateState.attempts} left)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.crimson,
                      ),
                    ).animate().shake(),

                  if (_cooldownSeconds > 0)
                    Text(
                      'Wait $_cooldownSeconds seconds to try again',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.faithCoins,
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: AppSpacing.lg),

            // Number pad
            if (_cooldownSeconds == 0)
              _NumberPad(
                onDigit: _onDigit,
                onDelete: _onDelete,
                onSubmit: _onSubmit,
              ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  void _onDigit(String digit) {
    if (_input.length >= 4) return;
    setState(() {
      _input += digit;
      _wrong = false;
    });
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _wrong = false;
    });
  }

  void _onSubmit() {
    final answer = int.tryParse(_input);
    if (answer == null) return;

    final success = ref
        .read(parentGateNotifierProvider.notifier)
        .submitAnswer(answer);

    if (success) {
      setState(() {
        _input = '';
        _wrong = false;
      });
    } else {
      setState(() {
        _input = '';
        _wrong = true;
      });

      final gate = ref.read(parentGateNotifierProvider);
      if (gate.attempts >= 3) {
        _startCooldown();
      }
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          t.cancel();
          _wrong = false;
          ref.read(parentGateNotifierProvider.notifier).generateNewProblem();
        }
      });
    });
  }
}

// ── Number pad ─────────────────────────────────────────────────────────────────

class _NumberPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const _NumberPad({
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        ...digits.map(
          (row) => Row(
            children: row.map((d) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _PadButton(
                    label: d,
                    onTap: () => onDigit(d),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _PadButton(
                  label: '⌫',
                  onTap: onDelete,
                  color: AppColors.crimson.withOpacity(0.15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _PadButton(
                  label: '0',
                  onTap: () => onDigit('0'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _PadButton(
                  label: '✓',
                  onTap: onSubmit,
                  color: AppColors.forestGreen.withOpacity(0.2),
                  textColor: AppColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;

  const _PadButton({
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color ?? AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.darkElevated),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.headlineMedium.copyWith(
              color: textColor ?? AppColors.ivory,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Parent dashboard view ──────────────────────────────────────────────────────

class _ParentDashboardView extends ConsumerWidget {
  final VoidCallback onLock;

  const _ParentDashboardView({required this.onLock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(parentGateNotifierProvider);
    final settings = ref.watch(parentalSettingsProvider);

    // Show lock warning when nearly expired
    final unlockedAt = gate.unlockedAt;
    final elapsed = unlockedAt != null
        ? DateTime.now().difference(unlockedAt).inMinutes
        : 0;
    final remaining = (10 - elapsed).clamp(0, 10);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        title: Row(
          children: [
            const Icon(Icons.family_restroom, color: AppColors.gold, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Parent Dashboard',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: remaining <= 2
                    ? AppColors.crimson.withOpacity(0.15)
                    : AppColors.forestGreen.withOpacity(0.15),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(
                  color: remaining <= 2
                      ? AppColors.crimson.withOpacity(0.4)
                      : AppColors.forestGreen.withOpacity(0.4),
                ),
              ),
              child: Text(
                '$remaining min left',
                style: AppTextStyles.labelSmall.copyWith(
                  color: remaining <= 2
                      ? AppColors.crimson
                      : AppColors.forestGreen,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: AppColors.midGrey),
            onPressed: onLock,
            tooltip: 'Lock Now',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Validate Good Deeds ──────────────────────────────────────────
            _DashboardSection(
              title: 'Validate Good Deeds',
              icon: Icons.check_circle_outline,
              iconColor: AppColors.forestGreen,
              child: _GoodDeedsValidator(),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: AppSpacing.md),

            // ── Screen Time ──────────────────────────────────────────────────
            _DashboardSection(
              title: 'Daily Screen Time Limit',
              icon: Icons.timer_outlined,
              iconColor: AppColors.holyPoints,
              child: _ScreenTimePicker(
                current: settings.dailyLimitMinutes,
                onChanged: (val) => ref
                    .read(parentalSettingsProvider.notifier)
                    .updateScreenTime(val),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: AppSpacing.md),

            // ── AI Chat Toggle ───────────────────────────────────────────────
            _DashboardSection(
              title: 'AI Chat',
              icon: Icons.chat_bubble_outline,
              iconColor: AppColors.grace,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prayer Companion',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                      Text(
                        'Allow child to use AI chat',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: settings.aiChatEnabled,
                    onChanged: (val) => ref
                        .read(parentalSettingsProvider.notifier)
                        .toggleAiChat(val),
                    activeColor: AppColors.gold,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: AppSpacing.md),

            // ── FaithCoin spending ────────────────────────────────────────────
            _DashboardSection(
              title: 'Resource Spending',
              icon: Icons.savings_outlined,
              iconColor: AppColors.faithCoins,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allow FaithCoin Spending',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                      Text(
                        'Needed to unlock upgrades',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: settings.allowCoinSpending,
                    onChanged: (val) => ref
                        .read(parentalSettingsProvider.notifier)
                        .toggleCoinSpending(val),
                    activeColor: AppColors.gold,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: AppSpacing.md),

            // ── Weekly report ─────────────────────────────────────────────────
            _DashboardSection(
              title: 'Weekly Report',
              icon: Icons.bar_chart,
              iconColor: AppColors.blessings,
              child: _WeeklyReportCard(),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: AppSpacing.lg),

            KingdomButton(
              label: 'Lock Parent Area',
              onPressed: onLock,
              icon: Icons.lock,
              isPrimary: false,
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard section wrapper ──────────────────────────────────────────────────

class _DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.darkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.goldLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ── Good deeds validator ───────────────────────────────────────────────────────

class _GoodDeedsValidator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingGoodDeedsProvider);

    if (pending.isEmpty) {
      return Text(
        'No pending good deeds to validate.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
      );
    }

    return Column(
      children: pending.asMap().entries.map((e) {
        final deed = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.darkElevated,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deed.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.ivory,
                      ),
                    ),
                    Text(
                      deed.completedAt,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle,
                    color: AppColors.forestGreen),
                onPressed: () => ref
                    .read(pendingGoodDeedsProvider.notifier)
                    .validate(deed.id),
                tooltip: 'Validate',
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Screen time picker ─────────────────────────────────────────────────────────

class _ScreenTimePicker extends StatelessWidget {
  final int current; // minutes
  final void Function(int) onChanged;

  const _ScreenTimePicker({required this.current, required this.onChanged});

  static const _options = [
    (label: '30 min', value: 30),
    (label: '1 hr', value: 60),
    (label: '2 hr', value: 120),
    (label: 'Unlimited', value: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: _options.map((opt) {
        final isSelected = current == opt.value;
        return GestureDetector(
          onTap: () => onChanged(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.holyPoints.withOpacity(0.2)
                  : AppColors.darkElevated,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: isSelected ? AppColors.holyPoints : AppColors.darkCard,
                width: 1.5,
              ),
            ),
            child: Text(
              opt.label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.holyPoints : AppColors.midGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Weekly report card ─────────────────────────────────────────────────────────

class _WeeklyReportCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyReportProvider);

    return Column(
      children: [
        _ReportStat(
          label: 'Quests Completed',
          value: '${stats.questsCompleted}',
          emoji: '⚔️',
        ),
        _ReportStat(
          label: 'Time in App',
          value: '${stats.minutesSpent} min',
          emoji: '⏱️',
        ),
        _ReportStat(
          label: 'Quizzes Played',
          value: '${stats.quizzesPlayed}',
          emoji: '🧠',
        ),
        _ReportStat(
          label: 'Good Deeds',
          value: '${stats.goodDeedsRecorded}',
          emoji: '✅',
        ),
      ],
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _ReportStat({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.parchment),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.ivory,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
