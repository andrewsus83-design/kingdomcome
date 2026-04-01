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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parentEmailController = TextEditingController();

  int _age = 13;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get _requiresParentalConsent => _age < 13;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          age: _age,
          parentEmail: _requiresParentalConsent
              ? _parentEmailController.text.trim()
              : null,
        );

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      setState(() {
        _errorMessage = authState.error?.toString() ??
            'Registration failed. Please try again.';
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
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: AppColors.gold),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Join the Kingdom',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.goldLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 40), // balance the back button
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Registration card
                  _buildFormCard(isLoading),

                  const SizedBox(height: AppSpacing.lg),

                  // Parental consent section (age < 13)
                  if (_requiresParentalConsent)
                    _buildParentalConsentSection()
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.2),

                  const SizedBox(height: AppSpacing.lg),

                  // Sign In link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isLoading) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.crimson.withOpacity(0.12),
                borderRadius: AppSpacing.borderRadiusSm,
                border:
                    Border.all(color: AppColors.crimson.withOpacity(0.4)),
              ),
              child: Text(
                _errorMessage!,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.crimson),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Username
          _MedievalField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter a username';
              if (v.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              if (v.trim().length > 20) {
                return 'Username must be at most 20 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Email
          _MedievalField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Invalid email address';
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Password
          _MedievalField(
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
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Age slider
          Text(
            'How old are you?',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.warmGrey,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '$_age years old',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.deepPurple,
                ),
              ),
              const Spacer(),
              Text(
                _requiresParentalConsent
                    ? '⚠ Parent consent required'
                    : '✓ All set!',
                style: AppTextStyles.labelSmall.copyWith(
                  color: _requiresParentalConsent
                      ? AppColors.blessings
                      : AppColors.forestGreen,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.deepPurple,
              inactiveTrackColor: AppColors.parchmentDark,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withOpacity(0.2),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _age.toDouble(),
              min: 8,
              max: 18,
              divisions: 10,
              onChanged: (v) => setState(() => _age = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('8', style: AppTextStyles.labelSmall),
              Text('18', style: AppTextStyles.labelSmall),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          KingdomButton(
            label: 'Begin Your Journey',
            onPressed: isLoading ? null : _register,
            isLoading: isLoading,
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildParentalConsentSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blessings.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.blessings.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.family_restroom,
                  color: AppColors.blessings, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Parental Consent Required',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.blessings,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Because you\'re under 13, we need a parent or guardian\'s permission. '
            'We\'ll send them an email to approve your account.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warmGrey),
          ),
          const SizedBox(height: AppSpacing.md),
          _MedievalField(
            controller: _parentEmailController,
            label: "Parent / Guardian's Email",
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: _requiresParentalConsent
                ? (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter your parent's email";
                    }
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Shared field widget ───────────────────────────────────────────────────────

class _MedievalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _MedievalField({
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
        labelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.warmGrey),
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
