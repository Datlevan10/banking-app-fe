/// Domain-level failure raised when authentication cannot be completed.
///
/// Using a typed exception (instead of leaking `PlatformException` or HTTP
/// errors) keeps the presentation layer decoupled from `local_auth` and the
/// network stack — the BLoC only ever handles [AuthException].
class AuthException implements Exception {
  const AuthException(this.message);

  /// User-safe message the UI can display directly.
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
