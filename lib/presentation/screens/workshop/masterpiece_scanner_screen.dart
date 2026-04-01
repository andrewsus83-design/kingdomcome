import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/data/models/resources/resource_model.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

// ── AI analysis result model ───────────────────────────────────────────────────

class _ArtworkAnalysis {
  final String type;
  final int effortLevel;
  final bool catholicTheme;
  final String themeDetail;
  final int completionPercent;
  final String encouragingMessage;

  const _ArtworkAnalysis({
    required this.type,
    required this.effortLevel,
    required this.catholicTheme,
    required this.themeDetail,
    required this.completionPercent,
    required this.encouragingMessage,
  });

  factory _ArtworkAnalysis.fromJson(Map<String, dynamic> json) {
    return _ArtworkAnalysis(
      type: json['type'] as String? ?? 'drawing',
      effortLevel: (json['effortLevel'] as num?)?.toInt() ?? 3,
      catholicTheme: json['catholicTheme'] as bool? ?? false,
      themeDetail: json['themeDetail'] as String? ?? '',
      completionPercent: (json['completionPercent'] as num?)?.toInt() ?? 80,
      encouragingMessage:
          json['encouragingMessage'] as String? ?? 'Great work!',
    );
  }

  /// FaithCoins base reward based on effort
  int get faithCoinReward => effortLevel * 10;

  /// HolyPoints for Catholic theme bonus
  int get holyPointBonus => catholicTheme ? 50 : 0;

  String get typeEmoji {
    return switch (type.toLowerCase()) {
      'coloring' => '🖍️',
      'drawing' => '✏️',
      'papercraft' => '📄',
      'craft' => '✂️',
      _ => '🎨',
    };
  }

  String get effortStars {
    return '⭐' * effortLevel.clamp(1, 5);
  }
}

// ── Scan phases ────────────────────────────────────────────────────────────────

enum _ScanPhase { capture, analyzing, results }

// ── Cloudflare Worker URL ─────────────────────────────────────────────────────

const String _aiGatewayBase = String.fromEnvironment(
  'AI_GATEWAY_URL',
  defaultValue: 'https://kingdom-come-ai-gateway.workers.dev',
);

// ── Screen ─────────────────────────────────────────────────────────────────────

class MasterpieceScannerScreen extends ConsumerStatefulWidget {
  const MasterpieceScannerScreen({super.key});

  @override
  ConsumerState<MasterpieceScannerScreen> createState() =>
      _MasterpieceScannerScreenState();
}

class _MasterpieceScannerScreenState
    extends ConsumerState<MasterpieceScannerScreen> {
  final _picker = ImagePicker();
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));

  _ScanPhase _phase = _ScanPhase.capture;
  File? _imageFile;
  _ArtworkAnalysis? _analysis;
  String? _errorMessage;
  bool _claimed = false;
  String _analysisStep = 'Checking Catholic theme...';
  bool _displayInKingdom = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Masterpiece Scanner',
          style:
              AppTextStyles.headlineMedium.copyWith(color: AppColors.goldLight),
        ),
      ),
      body: switch (_phase) {
        _ScanPhase.capture => _CaptureView(
            onCamera: () => _pickImage(ImageSource.camera),
            onGallery: () => _pickImage(ImageSource.gallery),
          ),
        _ScanPhase.analyzing => _AnalyzingView(currentStep: _analysisStep),
        _ScanPhase.results => _analysis != null
            ? _ResultsView(
                imageFile: _imageFile!,
                analysis: _analysis!,
                claimed: _claimed,
                displayInKingdom: _displayInKingdom,
                onToggleDisplay: (val) =>
                    setState(() => _displayInKingdom = val),
                onClaim: _claimReward,
                onShare: _shareToParish,
                onScanAnother: _reset,
              )
            : _ErrorView(
                message: _errorMessage ?? 'Analysis failed.',
                onRetry: _reset,
              ),
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile == null) return;

    setState(() {
      _imageFile = File(xFile.path);
      _phase = _ScanPhase.analyzing;
      _analysisStep = 'Checking Catholic theme...';
    });

    await _analyzeArtwork();
  }

  Future<void> _analyzeArtwork() async {
    if (_imageFile == null) return;

    final steps = [
      'Checking Catholic theme...',
      'Measuring effort...',
      'Calculating reward...',
    ];

    // Animate through steps
    for (var i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _analysisStep = steps[i]);
    }

    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _setError('Session expired. Please sign in again.');
        return;
      }

      final response = await _dio.post(
        '$_aiGatewayBase/analyze-artwork',
        options: Options(headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        }),
        data: {
          'image': base64Image,
          'mimeType': 'image/jpeg',
        },
      );

      final data = response.data as Map<String, dynamic>;
      setState(() {
        _analysis = _ArtworkAnalysis.fromJson(data);
        _phase = _ScanPhase.results;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        _setError(
            'You\'ve reached your daily scan limit (10 per day). Come back tomorrow!');
      } else {
        _setError('Could not analyze artwork. Please try again.');
      }
    } catch (e) {
      _setError('Something went wrong. Please try again.');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _phase = _ScanPhase.results;
      _analysis = null;
    });
  }

  Future<void> _claimReward() async {
    final analysis = _analysis;
    if (analysis == null || _claimed) return;

    // Award resources
    ref.read(resourceNotifierProvider.notifier).optimisticAdd(
      ResourceReward(
        faithCoins: analysis.faithCoinReward,
        holyPoints: analysis.holyPointBonus,
        blessings: 0,
        grace: 0,
      ),
    );

    setState(() => _claimed = true);

    if (mounted) {
      _showCelebration();
    }
  }

  void _showCelebration() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape:
            RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reward Claimed!',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.goldLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '+${_analysis!.faithCoinReward} 🪵 FaithCoins'
              '${_analysis!.catholicTheme ? '\n+${_analysis!.holyPointBonus} ✨ HolyPoints' : ''}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.ivory,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _analysis!.encouragingMessage,
              style: AppTextStyles.scriptureQuote.copyWith(
                color: AppColors.parchment,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Amazing!',
                style: AppTextStyles.buttonSecondary.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareToParish() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(
          'Share to Parish',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        content: Text(
          'Sharing your artwork with your parish community is coming soon!',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.parchment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _phase = _ScanPhase.capture;
      _imageFile = null;
      _analysis = null;
      _errorMessage = null;
      _claimed = false;
    });
  }
}

// ── Capture view ───────────────────────────────────────────────────────────────

class _CaptureView extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _CaptureView({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Guide frame
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.4), width: 2),
            ),
            child: Stack(
              children: [
                // Corner decorations
                ...const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ].map((align) => Align(
                      alignment: align,
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          border: Border(
                            top: align == Alignment.topLeft ||
                                    align == Alignment.topRight
                                ? const BorderSide(
                                    color: AppColors.gold, width: 2.5)
                                : BorderSide.none,
                            bottom: align == Alignment.bottomLeft ||
                                    align == Alignment.bottomRight
                                ? const BorderSide(
                                    color: AppColors.gold, width: 2.5)
                                : BorderSide.none,
                            left: align == Alignment.topLeft ||
                                    align == Alignment.bottomLeft
                                ? const BorderSide(
                                    color: AppColors.gold, width: 2.5)
                                : BorderSide.none,
                            right: align == Alignment.topRight ||
                                    align == Alignment.bottomRight
                                ? const BorderSide(
                                    color: AppColors.gold, width: 2.5)
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    )),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_search,
                        color: AppColors.gold.withOpacity(0.4),
                        size: 56,
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 1500.ms),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Place your artwork here',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Tips
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Column(
              children: [
                _TipRow(emoji: '💡', text: 'Make sure it\'s well lit'),
                _TipRow(emoji: '📐', text: 'Hold phone steady & flat'),
                _TipRow(
                    emoji: '✝️',
                    text: 'Catholic themes earn bonus HolyPoints!'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          KingdomButton(
            label: 'Take Photo',
            onPressed: onCamera,
            icon: Icons.camera_alt,
          ),

          const SizedBox(height: AppSpacing.sm),

          KingdomButton(
            label: 'Upload from Gallery',
            onPressed: onGallery,
            icon: Icons.photo_library_outlined,
            isPrimary: false,
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _TipRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.parchment),
          ),
        ],
      ),
    );
  }
}

// ── Analyzing view ─────────────────────────────────────────────────────────────

class _AnalyzingView extends StatelessWidget {
  final String currentStep;

  const _AnalyzingView({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Checking Catholic theme...',
      'Measuring effort...',
      'Calculating reward...',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 56))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 800.ms,
                ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Analyzing your masterpiece...',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.goldLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Progress steps
            ...steps.asMap().entries.map((e) {
              final isDone = steps.indexOf(currentStep) > e.key;
              final isActive = currentStep == e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.forestGreen
                            : isActive
                                ? AppColors.gold
                                : AppColors.darkCard,
                        border: Border.all(
                          color: isDone
                              ? AppColors.forestGreen
                              : isActive
                                  ? AppColors.gold
                                  : AppColors.darkElevated,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 12)
                          : isActive
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    color: AppColors.gold,
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      e.value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDone
                            ? AppColors.forestGreen
                            : isActive
                                ? AppColors.ivory
                                : AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Results view ───────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final File imageFile;
  final _ArtworkAnalysis analysis;
  final bool claimed;
  final bool displayInKingdom;
  final void Function(bool) onToggleDisplay;
  final VoidCallback onClaim;
  final VoidCallback onShare;
  final VoidCallback onScanAnother;

  const _ResultsView({
    required this.imageFile,
    required this.analysis,
    required this.claimed,
    required this.displayInKingdom,
    required this.onToggleDisplay,
    required this.onClaim,
    required this.onShare,
    required this.onScanAnother,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Submitted photo
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusLg,
            child: Image.file(
              imageFile,
              height: 200,
              fit: BoxFit.cover,
            ),
          ).animate().fadeIn(),

          const SizedBox(height: AppSpacing.md),

          // Analysis result cards
          Text(
            'Analysis Results',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.goldLight,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _AnalysisChip(
                label: 'Artwork Type',
                value: '${analysis.typeEmoji} ${analysis.type}',
                color: AppColors.deepPurple,
              ),
              _AnalysisChip(
                label: 'Effort',
                value: analysis.effortStars,
                color: AppColors.forestGreen,
              ),
              _AnalysisChip(
                label: 'Catholic Theme',
                value: analysis.catholicTheme
                    ? '✅ ${analysis.themeDetail}'
                    : '❌ None detected',
                color: analysis.catholicTheme
                    ? AppColors.forestGreen
                    : AppColors.midGrey,
              ),
              _AnalysisChip(
                label: 'Completion',
                value: '${analysis.completionPercent}%',
                color: AppColors.holyPoints,
              ),
            ].asMap().entries.map((e) {
              return e.value
                  .animate(delay: (e.key * 80).ms)
                  .fadeIn()
                  .slideY(begin: 0.1);
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          // Reward breakdown
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.goldDark.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward Breakdown',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _RewardRow(
                  label: 'Base FaithCoins',
                  value: '+${analysis.faithCoinReward} 🪵',
                  subtitle: 'Effort × 10',
                ),
                if (analysis.catholicTheme)
                  _RewardRow(
                    label: 'Catholic Theme Bonus',
                    value: '+${analysis.holyPointBonus} ✨',
                    subtitle: analysis.themeDetail,
                  ),
                const Divider(color: AppColors.darkElevated, height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.ivory,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '+${analysis.faithCoinReward} 🪵  '
                      '${analysis.catholicTheme ? '+${analysis.holyPointBonus} ✨' : ''}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.faithCoins,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: AppSpacing.sm),

          // Display in kingdom toggle
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              children: [
                const Icon(Icons.castle_outlined,
                    color: AppColors.gold, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Display in Kingdom Art Studio',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.ivory,
                    ),
                  ),
                ),
                Switch(
                  value: displayInKingdom,
                  onChanged: onToggleDisplay,
                  activeColor: AppColors.gold,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          if (!claimed)
            KingdomButton(
              label: 'Claim Reward!',
              onPressed: onClaim,
              icon: Icons.celebration,
            ).animate().fadeIn(delay: 500.ms).scale(),

          if (claimed) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withOpacity(0.15),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.forestGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.forestGreen),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Reward Claimed! Well done!',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: KingdomButton(
                  label: 'Share to Parish',
                  onPressed: onShare,
                  icon: Icons.share,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: KingdomButton(
                  label: 'Scan Another',
                  onPressed: onScanAnother,
                  icon: Icons.camera_alt_outlined,
                  isPrimary: false,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _AnalysisChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnalysisChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.ivory,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _RewardRow({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.parchment,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.faithCoins,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.crimson, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Oops!',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.crimson,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.parchment,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            KingdomButton(
              label: 'Try Again',
              onPressed: onRetry,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}
