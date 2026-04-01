import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Allow animation to play, then check auth
    Future.delayed(const Duration(milliseconds: 2800), _checkAuth);
  }

  void _checkAuth() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final authState = ref.read(authNotifierProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          context.go('/kingdom');
        } else {
          context.go('/onboarding');
        }
      },
      loading: () {
        // Auth is still resolving — wait for it
        _navigated = false;
        Future.delayed(const Duration(milliseconds: 500), _checkAuth);
      },
      error: (_, __) => context.go('/onboarding'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also listen for auth resolution after delay
    ref.listenManual(authNotifierProvider, (prev, next) {
      if (!next.isLoading && !_navigated) {
        _navigated = true;
        next.when(
          data: (user) => user != null
              ? context.go('/kingdom')
              : context.go('/onboarding'),
          loading: () {},
          error: (_, __) => context.go('/onboarding'),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purpleDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.deepPurple,
                  AppColors.purpleDark,
                  Color(0xFF0A0015),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Particles / holy light animation
          Positioned.fill(
            child: Lottie.asset(
              AssetPaths.holyLightAnimation,
              fit: BoxFit.cover,
              repeat: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  AssetPaths.appLogo,
                  width: 160,
                  height: 160,
                  errorBuilder: (_, __, ___) => const _LogoFallback(),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'KINGDOM COME',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(
                        blurRadius: 20,
                        color: AppColors.gold,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms),

                const SizedBox(height: 8),

                Text(
                  'Your Faith Journey Awaits',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.goldLight.withOpacity(0.7),
                    letterSpacing: 1.5,
                  ),
                )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 60),

                // Loading cross animation
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Lottie.asset(
                    AssetPaths.loadingCrossAnimation,
                    repeat: true,
                    errorBuilder: (_, __, ___) =>
                        const CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  ),
                ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // Version text
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              '† Thy Kingdom Come †',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.goldLight.withOpacity(0.4),
                letterSpacing: 2,
              ),
            ).animate(delay: 1200.ms).fadeIn(duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

// ── Logo fallback ─────────────────────────────────────────────────────────────

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 3),
        gradient: const RadialGradient(
          colors: [AppColors.deepPurple, AppColors.purpleDark],
        ),
      ),
      child: const Icon(
        Icons.church,
        size: 72,
        color: AppColors.gold,
      ),
    );
  }
}
