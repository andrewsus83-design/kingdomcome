import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/presentation/providers/ark_provider.dart';

/// Daily Bread — Full-screen daily verse experience.
///
/// Features:
/// - Beautiful parchment-card with large centered verse text
/// - Book:Chapter:Verse reference display
/// - "Read Aloud" button for Suno-generated audio
/// - Saint narrator card with portrait and name
/// - Reflection prompt with private journal text input
/// - Share to parish button
/// - Bread-breaking animation on load
/// - Auto-completes the "Daily Bread" quest
class DailyBreadScreen extends ConsumerStatefulWidget {
  const DailyBreadScreen({super.key});

  @override
  ConsumerState<DailyBreadScreen> createState() => _DailyBreadScreenState();
}

class _DailyBreadScreenState extends ConsumerState<DailyBreadScreen>
    with TickerProviderStateMixin {
  final _reflectionController = TextEditingController();
  bool _reflectionSaved = false;
  bool _isReadingAloud = false;
  late final AnimationController _breadAnimController;
  late final AnimationController _lightRayController;

  @override
  void initState() {
    super.initState();
    _breadAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _lightRayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _breadAnimController.dispose();
    _lightRayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyBreadAsync = ref.watch(dailyBreadProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.goldLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Bread',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.goldLight,
          ),
        ),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.gold),
            onPressed: dailyBreadAsync.valueOrNull != null
                ? () => _shareToParish(dailyBreadAsync.value!)
                : null,
          ),
        ],
      ),
      body: dailyBreadAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (verse) => _DailyBreadContent(
          verse: verse,
          reflectionController: _reflectionController,
          reflectionSaved: _reflectionSaved,
          isReadingAloud: _isReadingAloud,
          breadAnimController: _breadAnimController,
          lightRayController: _lightRayController,
          onReadAloud: () => _toggleReadAloud(verse),
          onSaveReflection: () => _saveReflection(verse),
          onClearReflection: () => setState(() {
            _reflectionController.clear();
            _reflectionSaved = false;
          }),
        ),
      ),
    );
  }

  Future<void> _toggleReadAloud(DailyBreadVerse verse) async {
    setState(() => _isReadingAloud = !_isReadingAloud);
    if (_isReadingAloud) {
      // In production: play verse.audioUrl using just_audio
      // For now, simulate with a timer
      Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _isReadingAloud = false);
      });
    }
  }

  Future<void> _saveReflection(DailyBreadVerse verse) async {
    final text = _reflectionController.text.trim();
    if (text.isEmpty) return;

    // In production: save to Supabase prayer_journal table
    setState(() => _reflectionSaved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reflection saved to your journal',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
        ),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareToParish(DailyBreadVerse verse) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: const BorderSide(color: AppColors.goldDark),
        ),
        title: Text(
          'Share to Parish',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.goldLight),
        ),
        content: Text(
          '"${verse.verseText}"\n— ${verse.reference}',
          style: AppTextStyles.scriptureQuote.copyWith(color: AppColors.parchment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.midGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shared to parish feed!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
              foregroundColor: AppColors.gold,
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Content
// ─────────────────────────────────────────────────────────────────────────────

class _DailyBreadContent extends StatelessWidget {
  final DailyBreadVerse verse;
  final TextEditingController reflectionController;
  final bool reflectionSaved;
  final bool isReadingAloud;
  final AnimationController breadAnimController;
  final AnimationController lightRayController;
  final VoidCallback onReadAloud;
  final VoidCallback onSaveReflection;
  final VoidCallback onClearReflection;

  const _DailyBreadContent({
    required this.verse,
    required this.reflectionController,
    required this.reflectionSaved,
    required this.isReadingAloud,
    required this.breadAnimController,
    required this.lightRayController,
    required this.onReadAloud,
    required this.onSaveReflection,
    required this.onClearReflection,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Light ray animation + date badge
          _DateBadge(date: verse.date),
          const SizedBox(height: AppSpacing.lg),

          // Main verse card
          _VerseCard(
            verse: verse,
            animController: breadAnimController,
            lightRayController: lightRayController,
          ),
          const SizedBox(height: AppSpacing.md),

          // Read aloud button
          _ReadAloudButton(
            verse: verse,
            isPlaying: isReadingAloud,
            onTap: onReadAloud,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Saint narrator
          _SaintNarratorCard(verse: verse),
          const SizedBox(height: AppSpacing.lg),

          // Reflection prompt
          _ReflectionSection(
            verse: verse,
            controller: reflectionController,
            isSaved: reflectionSaved,
            onSave: onSaveReflection,
            onClear: onClearReflection,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Date Badge ────────────────────────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  final DateTime date;
  const _DateBadge({required this.date});

  String get _formatted {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today,
                color: AppColors.gold, size: 12),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _formatted,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

// ── Verse Card ────────────────────────────────────────────────────────────────

class _VerseCard extends StatelessWidget {
  final DailyBreadVerse verse;
  final AnimationController animController;
  final AnimationController lightRayController;

  const _VerseCard({
    required this.verse,
    required this.animController,
    required this.lightRayController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lightRayController,
      builder: (ctx, child) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A1F00), Color(0xFF1E1000)],
            ),
            borderRadius: AppSpacing.borderRadiusXl,
            border: Border.all(
              color: AppColors.gold.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(
                    0.15 + 0.1 * math.sin(lightRayController.value * math.pi * 2)),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          // Bread icon
          const Text('🍞', style: TextStyle(fontSize: 48))
              .animate(controller: animController, autoPlay: false)
              .scale(begin: const Offset(0.3, 0.3), duration: 600.ms)
              .then()
              .shimmer(duration: 800.ms, color: AppColors.gold.withOpacity(0.4)),
          const SizedBox(height: AppSpacing.lg),
          // Verse text
          Text(
            '"${verse.verseText}"',
            style: AppTextStyles.scriptureQuote.copyWith(
              color: AppColors.parchment,
              fontSize: 19,
              height: 1.9,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 400.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: AppSpacing.lg),
          // Reference
          Text(
            verse.reference,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.gold,
              letterSpacing: 1,
            ),
          ).animate(delay: 700.ms).fadeIn(),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New American Bible Revised Edition',
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.midGrey),
          ).animate(delay: 800.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Read Aloud Button ─────────────────────────────────────────────────────────

class _ReadAloudButton extends StatelessWidget {
  final DailyBreadVerse verse;
  final bool isPlaying;
  final VoidCallback onTap;

  const _ReadAloudButton({
    required this.verse,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.gold.withOpacity(0.2)
              : AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isPlaying
                ? AppColors.gold
                : AppColors.goldDark.withOpacity(0.4),
            width: isPlaying ? 1.5 : 1,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.volume_up,
                key: ValueKey(isPlaying),
                color: isPlaying ? AppColors.gold : AppColors.goldLight,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              isPlaying ? 'Playing...' : 'Read Aloud',
              style: AppTextStyles.labelLarge.copyWith(
                color: isPlaying ? AppColors.gold : AppColors.goldLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isPlaying) ...[
              const SizedBox(width: AppSpacing.sm),
              _AudioWaveIndicator(),
            ],
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
  }
}

class _AudioWaveIndicator extends StatefulWidget {
  @override
  State<_AudioWaveIndicator> createState() => _AudioWaveIndicatorState();
}

class _AudioWaveIndicatorState extends State<_AudioWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = (i * 0.33 + _anim.value) % 1.0;
            final h = 6 + 10 * math.sin(offset * math.pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Saint Narrator Card ───────────────────────────────────────────────────────

class _SaintNarratorCard extends StatelessWidget {
  final DailyBreadVerse verse;
  const _SaintNarratorCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Saint portrait
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
              color: AppColors.deepPurple,
            ),
            child: ClipOval(
              child: Image.asset(
                verse.narratorPortraitPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Narrated by',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.midGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  verse.narratorSaintName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.goldLight,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.star, color: AppColors.gold, size: 16),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.05);
  }
}

// ── Reflection Section ────────────────────────────────────────────────────────

class _ReflectionSection extends StatelessWidget {
  final DailyBreadVerse verse;
  final TextEditingController controller;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const _ReflectionSection({
    required this.verse,
    required this.controller,
    required this.isSaved,
    required this.onSave,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.edit_note, color: AppColors.grace, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'My Reflection',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.grace,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.grace.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(color: AppColors.grace.withOpacity(0.3)),
              ),
              child: Text(
                'Private',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.grace,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Prompt
        Text(
          verse.reflectionPrompt,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.parchmentDark,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Text input
        if (!isSaved)
          TextField(
            controller: controller,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Write your thoughts here...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.midGrey),
              filled: true,
              fillColor: AppColors.darkCard,
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
                borderSide: const BorderSide(color: AppColors.grace),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                  color: AppColors.forestGreen.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.sage, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Reflection saved',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.sage),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  controller.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.parchment),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (!isSaved)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save to Journal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grace.withOpacity(0.2),
                foregroundColor: AppColors.grace,
                side: BorderSide(color: AppColors.grace.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
            ),
          )
        else
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit reflection'),
            style: TextButton.styleFrom(foregroundColor: AppColors.midGrey),
          ),
      ],
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1);
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍞', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load today\'s bread',
              style:
                  AppTextStyles.headlineSmall.copyWith(color: AppColors.ivory),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
