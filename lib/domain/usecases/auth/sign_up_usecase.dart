import 'package:dartz/dartz.dart';

import '../../../core/errors/failure.dart';
import '../../../data/models/user/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Parameters for [SignUpUseCase].
class SignUpParams {
  final String email;
  final String password;
  final String username;

  /// User's actual age in years (used to derive age group).
  final int age;

  /// Parent email. Required when [age] < 13. Optional otherwise.
  final String? parentEmail;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.username,
    required this.age,
    this.parentEmail,
  });
}

/// Result returned by [SignUpUseCase].
class SignUpResult {
  final UserModel user;

  /// True when a parental-consent email was sent.
  final bool parentalConsentSent;

  const SignUpResult({
    required this.user,
    required this.parentalConsentSent,
  });
}

/// Handles user registration with age-based validation:
///
///  - Age 8–10  → ageGroup 1, parental consent required.
///  - Age 11–12 → ageGroup 1, parental consent required (COPPA / GDPR-K).
///  - Age 13–14 → ageGroup 2, no parental consent required.
///  - Age 15–18 → ageGroup 3, no parental consent required.
///  - Under 8 or over 18 → validation failure.
///
/// If age < 13 and no [parentEmail] is supplied, returns a
/// [ValidationFailure] asking for a parent email before proceeding.
class SignUpUseCase {
  const SignUpUseCase({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<Either<Failure, SignUpResult>> call(SignUpParams params) async {
    // -----------------------------------------------------------------------
    // 1. Basic field validation
    // -----------------------------------------------------------------------
    if (params.username.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Username cannot be empty.',
          code: 'username_empty',
        ),
      );
    }

    if (params.username.trim().length < 3 ||
        params.username.trim().length > 20) {
      return const Left(
        ValidationFailure(
          message: 'Username must be between 3 and 20 characters.',
          code: 'username_length',
        ),
      );
    }

    if (params.email.trim().isEmpty || !params.email.contains('@')) {
      return const Left(
        ValidationFailure(
          message: 'Please enter a valid email address.',
          code: 'invalid_email',
        ),
      );
    }

    if (params.password.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'Password must be at least 8 characters.',
          code: 'password_too_short',
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 2. Age validation
    // -----------------------------------------------------------------------
    if (params.age < 8) {
      return const Left(
        ValidationFailure(
          message: 'Kingdom Come is designed for players aged 8 and above.',
          code: 'age_too_young',
        ),
      );
    }

    if (params.age > 18) {
      return const Left(
        ValidationFailure(
          message: 'Kingdom Come is designed for players aged 8 to 18.',
          code: 'age_too_old',
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 3. Parental consent requirement for under-13s
    // -----------------------------------------------------------------------
    final requiresConsent = params.age < 13;
    if (requiresConsent) {
      if (params.parentEmail == null ||
          params.parentEmail!.trim().isEmpty ||
          !params.parentEmail!.contains('@')) {
        return const Left(
          ValidationFailure(
            message:
                'Players under 13 need a parent or guardian to approve their '
                'account. Please provide a parent email address.',
            code: 'parental_consent_required',
          ),
        );
      }
    }

    // -----------------------------------------------------------------------
    // 4. Derive age group
    // -----------------------------------------------------------------------
    final ageGroup = _ageGroupForAge(params.age);

    // -----------------------------------------------------------------------
    // 5. Sign up via repository
    // -----------------------------------------------------------------------
    final signUpResult = await _authRepository.signUp(
      params.email.trim(),
      params.password,
      params.username.trim(),
      ageGroup,
    );

    return signUpResult.fold(
      (failure) => Left(failure),
      (user) async {
        bool consentSent = false;

        // -----------------------------------------------------------------------
        // 6. Send parental consent email for under-13s
        // -----------------------------------------------------------------------
        if (requiresConsent && params.parentEmail != null) {
          final consentResult = await _authRepository.sendParentalConsent(
            params.parentEmail!.trim(),
            user.id,
          );
          consentSent = consentResult.isRight();
          // Non-fatal: account is created regardless of consent email success.
          // The app can resend consent email from settings.
        }

        return Right(
          SignUpResult(
            user: user,
            parentalConsentSent: consentSent,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _ageGroupForAge(int age) {
    if (age <= 10) return 1;
    if (age <= 14) return 2;
    return 3;
  }
}
