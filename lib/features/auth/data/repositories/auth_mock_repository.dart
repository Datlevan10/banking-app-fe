import 'package:local_auth/local_auth.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';

/// Offline/mock [AuthRepository]: validates PIN and credentials against fixed
/// demo values and uses the OS biometric APIs (`local_auth`) for real.
///
/// Kept as the fallback for local development and testing (and for the auth
/// methods whose backend endpoints aren't wired yet). [LocalAuthentication] is
/// injected so the class stays testable.
class AuthMockRepository implements AuthRepository {
  AuthMockRepository({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  // Demo credentials — replace with a real backend call.
  static const String _demoPin = '123456';
  static const String _demoUsername = 'vandat';
  static const String _demoPassword = 'password';

  static const AuthUser _demoUser = AuthUser(id: 'usr_01', name: 'Van Dat');

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      // At least one biometric must actually be enrolled.
      final List<BiometricType> enrolled =
          await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on Object {
      // Unsupported platform / no plugin -> treat as unavailable, never crash.
      return false;
    }
  }

  @override
  Future<AuthUser> authenticateWithBiometrics() async {
    final bool didAuthenticate;
    try {
      didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        biometricOnly: true,
        // Retry automatically if the app is backgrounded mid-prompt.
        persistAcrossBackgrounding: true,
      );
    } on Object {
      throw const AuthException('Biometric authentication is unavailable.');
    }

    if (!didAuthenticate) {
      throw const AuthException('Biometric authentication was cancelled.');
    }
    return _demoUser;
  }

  @override
  Future<AuthUser> authenticateWithPin(String pin) async {
    await _simulateLatency();
    if (pin != _demoPin) {
      throw const AuthException('Incorrect PIN. Please try again.');
    }
    return _demoUser;
  }

  @override
  Future<AuthUser> authenticateWithCredentials({
    required String username,
    required String password,
  }) async {
    await _simulateLatency();
    if (username.trim() != _demoUsername || password != _demoPassword) {
      throw const AuthException('Invalid username or password.');
    }
    return _demoUser;
  }

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 500));
}
