/// Typed exception hierarchy for CodeOps API errors.
///
/// All exceptions extend [ApiException] as a sealed class, enabling
/// exhaustive pattern matching in error handlers.
library;

/// Base class for all CodeOps API exceptions.
sealed class ApiException implements Exception {
  /// Human-readable error message.
  final String message;

  /// HTTP status code that triggered this exception, if applicable.
  final int? statusCode;

  /// Creates an [ApiException] with a [message] and optional [statusCode].
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// HTTP 400 — the request was malformed or invalid.
class BadRequestException extends ApiException {
  /// Optional map of field-level validation errors.
  final Map<String, String>? errors;

  /// Creates a [BadRequestException].
  const BadRequestException(super.message, {this.errors})
      : super(statusCode: 400);
}

/// HTTP 401 — authentication failed or token expired.
class UnauthorizedException extends ApiException {
  /// Creates an [UnauthorizedException].
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

/// HTTP 403 — the user lacks permission for this action.
class ForbiddenException extends ApiException {
  /// Creates a [ForbiddenException].
  const ForbiddenException(super.message) : super(statusCode: 403);
}

/// HTTP 404 — the requested resource was not found.
class NotFoundException extends ApiException {
  /// Creates a [NotFoundException].
  const NotFoundException(super.message) : super(statusCode: 404);
}

/// HTTP 409 — a conflict with existing data (e.g. duplicate email).
class ConflictException extends ApiException {
  /// Creates a [ConflictException].
  const ConflictException(super.message) : super(statusCode: 409);
}

/// HTTP 422 — the request body failed validation.
class ValidationException extends ApiException {
  /// Map of field names to validation error messages.
  final Map<String, String>? fieldErrors;

  /// Creates a [ValidationException].
  const ValidationException(super.message, {this.fieldErrors})
      : super(statusCode: 422);
}

/// HTTP 429 — rate limit exceeded.
class RateLimitException extends ApiException {
  /// Seconds to wait before retrying, if provided by the server.
  final int? retryAfterSeconds;

  /// Creates a [RateLimitException].
  const RateLimitException(super.message, {this.retryAfterSeconds})
      : super(statusCode: 429);
}

/// HTTP 500+ — an internal server error occurred.
class ServerException extends ApiException {
  /// Creates a [ServerException] with the given [statusCode].
  const ServerException(super.message, {required int super.statusCode});
}

/// No network connectivity or DNS resolution failure.
class NetworkException extends ApiException {
  /// Creates a [NetworkException].
  const NetworkException(super.message) : super(statusCode: null);
}

/// The request timed out before a response was received.
class TimeoutException extends ApiException {
  /// Creates a [TimeoutException].
  const TimeoutException(super.message) : super(statusCode: null);
}
