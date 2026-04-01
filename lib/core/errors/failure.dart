import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:kingdomcome/core/errors/app_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Failure sealed class hierarchy
// ─────────────────────────────────────────────────────────────────────────────

/// Base failure type used in the dartz [Either] pattern.
///
/// Repositories and use-cases return `Either<Failure, T>` rather than
/// throwing exceptions, so the caller can handle errors declaratively.
sealed class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
  });

  /// User-facing error message.
  final String message;

  /// Optional machine-readable code for logging / analytics.
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

// ── Network failures ──────────────────────────────────────────────────────────

final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'The request timed out. Please try again.',
    super.code = 'TIMEOUT',
  });
}

final class NoConnectionFailure extends Failure {
  const NoConnectionFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NO_CONNECTION',
  });
}

// ── Auth failures ─────────────────────────────────────────────────────────────

final class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

final class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    super.message = 'Your session has expired. Please sign in again.',
    super.code = 'SESSION_EXPIRED',
  });
}

final class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code = 'PERMISSION_DENIED',
  });
}

final class ParentalConsentFailure extends Failure {
  const ParentalConsentFailure({
    super.message =
        'Parental consent is required to access this feature.',
    super.code = 'PARENTAL_CONSENT_REQUIRED',
  });
}

// ── Game failures ─────────────────────────────────────────────────────────────

final class GameFailure extends Failure {
  const GameFailure({
    required super.message,
    super.code,
  });
}

final class InsufficientResourcesFailure extends Failure {
  const InsufficientResourcesFailure({
    required super.message,
    super.code = 'INSUFFICIENT_RESOURCES',
    required this.resourceType,
    required this.required,
    required this.available,
  });

  final String resourceType;
  final int required;
  final int available;

  @override
  List<Object?> get props =>
      [message, code, resourceType, required, available];
}

final class LevelLockedFailure extends Failure {
  const LevelLockedFailure({
    required super.message,
    super.code = 'LEVEL_LOCKED',
    required this.requiredLevel,
  });

  final int requiredLevel;

  @override
  List<Object?> get props => [message, code, requiredLevel];
}

final class QuestLimitFailure extends Failure {
  const QuestLimitFailure({
    super.message =
        'You have reached the maximum number of active quests.',
    super.code = 'QUEST_LIMIT',
  });
}

final class ConstructionInProgressFailure extends Failure {
  const ConstructionInProgressFailure({
    required super.message,
    super.code = 'CONSTRUCTION_IN_PROGRESS',
    required this.buildingId,
  });

  final String buildingId;

  @override
  List<Object?> get props => [message, code, buildingId];
}

// ── Data / persistence failures ───────────────────────────────────────────────

final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code = 'NOT_FOUND',
  });
}

final class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    super.code = 'CONFLICT',
  });
}

final class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code = 'STORAGE_ERROR',
  });
}

// ── AI / external service failures ────────────────────────────────────────────

final class AiServiceFailure extends Failure {
  const AiServiceFailure({
    required super.message,
    super.code,
    required this.serviceName,
  });

  final String serviceName;

  @override
  List<Object?> get props => [message, code, serviceName];
}

final class ChatLimitFailure extends Failure {
  const ChatLimitFailure({
    super.message =
        'Daily chat limit reached. Come back tomorrow!',
    super.code = 'CHAT_LIMIT',
    required this.limit,
  });

  final int limit;

  @override
  List<Object?> get props => [message, code, limit];
}

final class ContentFilteredFailure extends Failure {
  const ContentFilteredFailure({
    required super.message,
    super.code = 'CONTENT_FILTERED',
  });
}

// ── Validation failures ───────────────────────────────────────────────────────

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors = const {},
  });

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

// ── Unexpected / unknown failures ─────────────────────────────────────────────

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNEXPECTED',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Type aliases
// ─────────────────────────────────────────────────────────────────────────────

/// Convenience type alias for repository return types.
typedef FutureEither<T> = Future<Either<Failure, T>>;

/// Convenience type alias for synchronous either returns.
typedef EitherResult<T> = Either<Failure, T>;

// ─────────────────────────────────────────────────────────────────────────────
// Exception → Failure mapper
// ─────────────────────────────────────────────────────────────────────────────

/// Maps any [AppException] to the corresponding [Failure] subtype.
Failure mapExceptionToFailure(AppException exception) {
  return switch (exception) {
    TimeoutException() => const TimeoutFailure(),
    NoConnectionException() => const NoConnectionFailure(),
    NetworkException(statusCode: final sc) => NetworkFailure(
        message: exception.message,
        code: exception.code,
        statusCode: sc,
      ),
    AuthException() => AuthFailure(
        message: exception.message,
        code: exception.code,
      ),
    PermissionException() => PermissionFailure(
        message: exception.message,
        code: exception.code,
      ),
    ParentalConsentException() => const ParentalConsentFailure(),
    InsufficientResourcesException(
      resourceType: final rt,
      required: final req,
      available: final avail,
    ) =>
      InsufficientResourcesFailure(
        message: exception.message,
        resourceType: rt,
        required: req,
        available: avail,
      ),
    LevelLockedException(requiredLevel: final rl) => LevelLockedFailure(
        message: exception.message,
        requiredLevel: rl,
      ),
    QuestLimitException() => const QuestLimitFailure(),
    ConstructionInProgressException(buildingId: final bid) =>
      ConstructionInProgressFailure(
        message: exception.message,
        buildingId: bid,
      ),
    GameException() => GameFailure(
        message: exception.message,
        code: exception.code,
      ),
    NotFoundException() => NotFoundFailure(message: exception.message),
    ConflictException() => ConflictFailure(message: exception.message),
    StorageException() => StorageFailure(message: exception.message),
    ChatLimitException(limit: final l) => ChatLimitFailure(limit: l),
    ContentFilteredException() =>
      ContentFilteredFailure(message: exception.message),
    AiServiceException(serviceName: final sn) => AiServiceFailure(
        message: exception.message,
        code: exception.code,
        serviceName: sn,
      ),
    ValidationException(fieldErrors: final fe) => ValidationFailure(
        message: exception.message,
        fieldErrors: fe,
      ),
    // ignore: pattern_never_matches_value_type
    AppException() => UnexpectedFailure(
        // Fallback for any new subtype not yet handled above
      ),
  };
}
