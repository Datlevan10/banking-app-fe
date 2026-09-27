/// Infrastructure-level, transport-agnostic error hierarchy.
///
/// The network layer maps raw `DioException`s / HTTP status codes into these
/// typed exceptions. Feature repositories then translate them into their own
/// domain failures (e.g. `AuthException`), so the presentation layer never sees
/// Dio or HTTP concepts — preserving the Clean Architecture boundary.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  /// User-safe, human-readable message.
  final String message;

  /// The HTTP status code, when the failure originated from a response.
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// 401 — the request lacked valid authentication (expired/invalid token).
final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]) : super(statusCode: 401);
}

/// 403 — authenticated but not permitted.
final class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'You do not have permission to perform this action.',
  ]) : super(statusCode: 403);
}

/// 422 — the server rejected the payload; carries per-field messages.
final class ValidationException extends AppException {
  const ValidationException({
    String message = 'Some of the information provided is invalid.',
    this.fieldErrors = const <String, String>{},
  }) : super(message, statusCode: 422);

  /// Field name → error message, e.g. `{'username': 'already taken'}`.
  final Map<String, String> fieldErrors;
}

/// 5xx — the server failed to process a valid request.
final class ServerException extends AppException {
  const ServerException([
    super.message = 'Something went wrong on our end. Please try again later.',
    int statusCode = 500,
  ]) : super(statusCode: statusCode);
}

/// No usable response — timeout, DNS failure, offline, cancelled.
final class ConnectionException extends AppException {
  const ConnectionException([
    super.message = 'Unable to reach the server. Check your connection.',
  ]);
}

/// Any other unexpected failure.
final class UnknownApiException extends AppException {
  const UnknownApiException([
    super.message = 'An unexpected error occurred.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}
