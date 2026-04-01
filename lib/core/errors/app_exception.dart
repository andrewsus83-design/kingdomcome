/// Kingdom Come — Custom exception hierarchy.
///
/// All exceptions extend [AppException] so they can be caught generically
/// at the top of the call stack while still carrying structured information.
sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Human-readable message — suitable for logging, NOT for display
  /// (use Failure for user-facing messages).
  final String message;

  /// Optional machine-readable error code (HTTP status, Supabase error code…).
  final String? code;

  /// The underlying error that caused this exception.
  final Object? originalError;

  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException($runtimeType): $message'
      '${code != null ? " [code: $code]" : ""}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Network
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when an HTTP request fails (timeout, no connection, non-2xx).
final class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.statusCode,
  });

  /// HTTP status code, if available.
  final int? statusCode;
}

/// Thrown when a request times out.
final class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out. Please check your connection.',
    super.code = 'TIMEOUT',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when the device has no internet connection.
final class NoConnectionException extends AppException {
  const NoConnectionException({
    super.message = 'No internet connection available.',
    super.code = 'NO_CONNECTION',
    super.originalError,
    super.stackTrace,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Authentication
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when the user is not authenticated or the session has expired.
final class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when the user has insufficient permissions for an action.
final class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code = 'PERMISSION_DENIED',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when parental consent is required but not yet given.
final class ParentalConsentException extends AppException {
  const ParentalConsentException({
    super.message = 'Parental consent is required for this feature.',
    super.code = 'PARENTAL_CONSENT_REQUIRED',
    super.originalError,
    super.stackTrace,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Game logic
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a game rule is violated (e.g. insufficient resources).
final class GameException extends AppException {
  const GameException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when the player cannot afford a purchase.
final class InsufficientResourcesException extends GameException {
  const InsufficientResourcesException({
    required super.message,
    super.code = 'INSUFFICIENT_RESOURCES',
    super.originalError,
    super.stackTrace,
    required this.resourceType,
    required this.required,
    required this.available,
  });

  final String resourceType;
  final int required;
  final int available;
}

/// Thrown when trying to unlock something above the player's level.
final class LevelLockedException extends GameException {
  const LevelLockedException({
    required super.message,
    super.code = 'LEVEL_LOCKED',
    super.originalError,
    super.stackTrace,
    required this.requiredLevel,
    required this.currentLevel,
  });

  final int requiredLevel;
  final int currentLevel;
}

/// Thrown when the player hits a quest slot limit.
final class QuestLimitException extends GameException {
  const QuestLimitException({
    super.message = 'You already have the maximum number of active quests.',
    super.code = 'QUEST_LIMIT_REACHED',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when trying to construct a building that is already being built.
final class ConstructionInProgressException extends GameException {
  const ConstructionInProgressException({
    required super.message,
    super.code = 'CONSTRUCTION_IN_PROGRESS',
    super.originalError,
    super.stackTrace,
    required this.buildingId,
  });

  final String buildingId;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data / Persistence
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a requested resource could not be found.
final class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when there is a conflict in the data (e.g. duplicate record).
final class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.code = 'CONFLICT',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when local storage operations fail.
final class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AI / External services
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when an AI service call fails.
final class AiServiceException extends AppException {
  const AiServiceException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    required this.serviceName,
  });

  final String serviceName;
}

/// Thrown when the daily AI chat limit has been reached.
final class ChatLimitException extends AppException {
  const ChatLimitException({
    super.message = 'You\'ve reached your daily chat limit. '
        'Come back tomorrow for more conversations!',
    super.code = 'CHAT_LIMIT_REACHED',
    super.originalError,
    super.stackTrace,
    required this.limit,
  });

  final int limit;
}

/// Thrown when content is filtered by the content filter.
final class ContentFilteredException extends AppException {
  const ContentFilteredException({
    required super.message,
    super.code = 'CONTENT_FILTERED',
    super.originalError,
    super.stackTrace,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Validation
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when input validation fails.
final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
    super.stackTrace,
    this.fieldErrors = const {},
  });

  /// Map of field name → error message for form validation.
  final Map<String, String> fieldErrors;
}
