import '../entities/auth_user.dart';

/// Authentication contract the [AuthBloc] depends on.
///
/// All methods return the authenticated [AuthUser] on success and throw an
/// `AuthException` on failure — a uniform result shape that keeps the BLoC's
/// error handling simple and platform-agnostic.
abstract interface class AuthRepository {
  /// Whether the device has enrolled biometrics available for use.
  Future<bool> isBiometricAvailable();

  /// Prompt the OS biometric sheet (Face ID / fingerprint).
  Future<AuthUser> authenticateWithBiometrics();

  /// Validate a numeric PIN.
  Future<AuthUser> authenticateWithPin(String pin);

  /// Validate standard username + password credentials.
  Future<AuthUser> authenticateWithCredentials({
    required String username,
    required String password,
  });
}
