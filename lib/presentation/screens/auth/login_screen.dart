import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      setState(() {
        _errorMessage =
            authState.error?.toString() ?? 'Sign in failed. Please try again.';
      });
    } else if (authState.valueOrNull != null) {
      context.go('/kingdom');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.purpleDark, AppColors.darkSurface],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageH,
              vertical: AppSpacing.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo + title
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          AssetPaths.appLogoWhite,
                          width: 100,
                          height: 100,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.church,
                            size: 80,
                            color: AppColors.gold,
                          ),
                        ).animate().fadeIn(duration: 600.ms),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Welcome Back',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.goldLight,
                          ),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Continue your faith journey',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.midGrey,
                          ),
                        ).animate(delay: 300.ms).fadeIn(),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Parchment card
                  _ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.crimson.withOpacity(0.15),
                              borderRadius: AppSpacing.borderRadiusSm,
                              border: Border.all(
                                color: AppColors.crimson.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.crimson,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Email
                        _MedievalTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Password
                        _MedievalTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.warmGrey,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              'Forgot Password?',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Sign In button
                        KingdomButton(
                          label: 'Sign In',
                          onPressed: isLoading ? null : _signIn,
                          isLoading: isLoading,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.parchmentDark)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: Text(
                                'OR',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.warmGrey,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.parchmentDark)),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Google sign-in
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.parchmentDark),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                          ),
                          icon: const Icon(Icons.g_mobiledata,
                              color: AppColors.warmGrey, size: 24),
                          label: Text(
                            'Continue with Google',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.inkBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: AppSpacing.xl),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text(
                          'Join the Kingdom',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 600.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    // Google OAuth via Supabase — opens browser flow
    await ref.read(authNotifierProvider.notifier).signIn('', '');
    // Actual Google OAuth would be: supabase.auth.signInWithOAuth(OAuthProvider.google)
    // For now, navigate to register if not implemented
    if (mounted) context.push('/register');
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ParchmentCard extends StatelessWidget {
  final Widget child;
  const _ParchmentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
        image: const DecorationImage(
          image: AssetImage(AssetPaths.parchmentTexture),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: child,
    );
  }
}

class _MedievalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _MedievalTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkBlack),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.warmGrey,
        ),
        prefixIcon: Icon(icon, color: AppColors.deepPurple, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.parchmentDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.parchmentDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.crimson),
        ),
        filled: true,
        fillColor: AppColors.white.withOpacity(0.6),
      ),
    );
  }
}
