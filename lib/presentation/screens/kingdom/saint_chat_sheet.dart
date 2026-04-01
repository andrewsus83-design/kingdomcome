import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/saint/saint_model.dart';
import 'package:kingdomcome/presentation/providers/saint_provider.dart';
import 'package:kingdomcome/presentation/providers/ai_chat_provider.dart';
import 'package:kingdomcome/routing/route_names.dart';

/// Bottom sheet shown when tapping a Saint Resident in The Kingdom.
///
/// Shows:
/// - Saint portrait + rarity border + name
/// - Today's historical quote from this saint
/// - "Talk to [Saint]" input field → opens AiChatScreen with saint prompt
/// - 3 suggested questions chips
/// - Feast day countdown
class SaintChatBottomSheet extends ConsumerStatefulWidget {
  final SaintModel saint;

  const SaintChatBottomSheet({super.key, required this.saint});

  @override
  ConsumerState<SaintChatBottomSheet> createState() =>
      _SaintChatBottomSheetState();
}

class _SaintChatBottomSheetState extends ConsumerState<SaintChatBottomSheet> {
  final _questionController = TextEditingController();

  static const _suggestedQuestions = [
    'What is your greatest lesson?',
    'How did you find God?',
    'What should I pray for today?',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saint = widget.saint;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warmGrey,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Saint portrait + name header
              _SaintHeader(saint: saint),
              const SizedBox(height: AppSpacing.md),

              // Historical quote
              _SaintQuote(saint: saint),
              const SizedBox(height: AppSpacing.md),

              // Feast day countdown
              _FeastDayBadge(feastDay: saint.feastDay),
              const SizedBox(height: AppSpacing.lg),

              // Suggested questions
              Text(
                'Ask ${saint.name.split(' ').first} a question:',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: _suggestedQuestions.asMap().entries.map((e) {
                  return GestureDetector(
                    onTap: () => _openChatWithQuestion(
                        context, saint, e.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: AppColors.deepPurple.withOpacity(0.3),
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                            color: AppColors.purpleLight.withOpacity(0.4)),
                      ),
                      child: Text(
                        e.value,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.parchment,
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn(),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Custom question input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.ivory),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty) {
                          _openChatWithQuestion(
                              context, saint, text.trim());
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Ask ${saint.name.split(' ').first}...',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.midGrey),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusLg,
                          borderSide: const BorderSide(
                              color: AppColors.darkElevated),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusLg,
                          borderSide: const BorderSide(
                              color: AppColors.darkElevated),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusLg,
                          borderSide: const BorderSide(
                              color: AppColors.purpleLight),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () {
                      final q = _questionController.text.trim();
                      if (q.isNotEmpty) {
                        _openChatWithQuestion(context, saint, q);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.deepPurple,
                        border: Border.all(
                            color: AppColors.purpleLight.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.send,
                          color: AppColors.goldLight, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Full chat button
              OutlinedButton.icon(
                onPressed: () =>
                    _openChatWithQuestion(context, saint, ''),
                icon: const Icon(Icons.chat_outlined,
                    color: AppColors.gold, size: 18),
                label: Text(
                  'Open Full Chat with ${saint.name.split(' ').first}',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.gold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.goldDark),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatWithQuestion(
      BuildContext context, SaintModel saint, String question) {
    Navigator.pop(context);
    // Pre-seed the AI chat with the saint's system prompt
    ref.read(aiChatNotifierProvider.notifier).setSaintPersona(
          saintName: saint.name,
          saintBio: saint.shortBio,
          patronage: saint.patronage,
          era: saint.era,
        );

    if (question.isNotEmpty) {
      ref.read(aiChatNotifierProvider.notifier).sendMessage(question);
    }

    // Navigate to AI chat
    context.push(RouteNames.prayerChat);
  }
}

// ── Saint Header ──────────────────────────────────────────────────────────────

class _SaintHeader extends StatelessWidget {
  final SaintModel saint;
  const _SaintHeader({required this.saint});

  Color get _rarityColor {
    switch (saint.rarity.toLowerCase()) {
      case 'legendary':
        return AppColors.faithCoins;
      case 'epic':
        return AppColors.purpleLight;
      case 'rare':
        return AppColors.holyPoints;
      case 'uncommon':
        return AppColors.sage;
      default:
        return AppColors.parchmentDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Portrait with rarity glow
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _rarityColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: _rarityColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              saint.portraitAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.deepPurple,
                child: Center(
                  child: Text(
                    saint.name[0],
                    style: TextStyle(
                      color: _rarityColor,
                      fontSize: 28,
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8), duration: 300.ms),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saint.name,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.ivory,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                saint.latinName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.midGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Rarity + patronage row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _rarityColor.withOpacity(0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border:
                          Border.all(color: _rarityColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      saint.rarity.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _rarityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 8,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      saint.patronage,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.midGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Saint Quote ───────────────────────────────────────────────────────────────

class _SaintQuote extends StatelessWidget {
  final SaintModel saint;
  const _SaintQuote({required this.saint});

  String get _quote {
    // In production this would come from a quotes table.
    // Using prayerText as the historical "quote" for now.
    return saint.prayerText.isNotEmpty
        ? saint.prayerText
        : '"Faith is not merely believing in God with the mind, but trusting Him with the whole heart."';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1845), Color(0xFF1A0F30)],
        ),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: AppColors.gold, size: 18),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _quote,
            style: AppTextStyles.scriptureQuote.copyWith(
              color: AppColors.parchment,
              fontSize: 13,
              height: 1.7,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '— ${saint.name}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn();
  }
}

// ── Feast Day Badge ───────────────────────────────────────────────────────────

class _FeastDayBadge extends StatelessWidget {
  final String feastDay; // "MM-DD" format

  const _FeastDayBadge({required this.feastDay});

  int _daysUntilFeast() {
    try {
      final parts = feastDay.split('-');
      if (parts.length < 2) return -1;

      final now = DateTime.now();
      var feast = DateTime(now.year, int.parse(parts[0]),
          int.parse(parts[1]));

      if (feast.isBefore(now)) {
        feast = DateTime(now.year + 1, feast.month, feast.day);
      }

      return feast.difference(now).inDays;
    } catch (_) {
      return -1;
    }
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month.clamp(1, 12) - 1];
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysUntilFeast();
    if (days < 0) return const SizedBox.shrink();

    final parts = feastDay.split('-');
    final month = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 1 : 1;
    final day = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;

    final String daysLabel = days == 0
        ? 'Today!'
        : days == 1
            ? 'Tomorrow'
            : 'In $days days';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.blessings.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.blessings.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration,
              color: AppColors.blessings, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Feast Day: ${_monthName(month)} $day — $daysLabel',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.blessings,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page wrapper for navigator-based push (e.g. deep link from saint chat)
// ─────────────────────────────────────────────────────────────────────────────

/// Full-page wrapper for SaintChatBottomSheet used when navigating via GoRouter.
class SaintChatSheetPage extends ConsumerWidget {
  final String saintId;

  const SaintChatSheetPage({super.key, required this.saintId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saints = ref.watch(saintNotifierProvider).valueOrNull ?? [];
    final saint = saints.firstWhereOrNull((s) => s.id == saintId);

    if (saint == null) {
      return Scaffold(
        backgroundColor: AppColors.darkSurface,
        appBar: AppBar(backgroundColor: AppColors.purpleDark),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.goldLight),
          onPressed: () => context.pop(),
        ),
        title: Text(
          saint.name,
          style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.goldLight),
        ),
      ),
      body: SaintChatBottomSheet(saint: saint),
    );
  }
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
