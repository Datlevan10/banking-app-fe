import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';

/// Production [AuthRepository]: credential sign-in calls the C# .NET backend
/// (`POST /api/v1/auth/login`); the returned JWT is persisted via a token store
/// for the [AuthInterceptor] to attach to subsequent requests.
///
/// PIN and biometric sign-in are delegated to [_fallback] (the mock) until
/// their backend endpoints land — a deliberate strangler-fig migration. On a
/// connection error, credential sign-in also falls back when
/// [AppConfig.fallbackToMockWhenOffline] is enabled, so local testing survives
/// an offline backend.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remote,
    required this._onToken,
    required this._fallback,
  });

  final AuthRemoteDataSource _remote;
  final Future<void> Function(String token) _onToken;
  final AuthRepository _fallback;

  @override
  Future<AuthUser> authenticateWithCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final LoginResponseDto response = await _remote.login(
        LoginRequestDto(username: username, password: password),
      );
      await _onToken(response.accessToken);
      return response.user.toEntity();
    } on AppException catch (error) {
      // Offline? Optionally fall back to the mock so local dev keeps working.
      if (error is ConnectionException &&
          AppConfig.fallbackToMockWhenOffline) {
        return _fallback.authenticateWithCredentials(
          username: username,
          password: password,
        );
      }
      throw _toAuthException(error);
    } on FormatException {
      throw const AuthException('Received an invalid response from the server.');
    }
  }

  // --- Not yet migrated: delegated to the fallback -------------------------

  @override
  Future<bool> isBiometricAvailable() => _fallback.isBiometricAvailable();

  @override
  Future<AuthUser> authenticateWithBiometrics() =>
      _fallback.authenticateWithBiometrics();

  @override
  Future<AuthUser> authenticateWithPin(String pin) =>
      _fallback.authenticateWithPin(pin);

  /// Maps an infrastructure [AppException] to a user-facing [AuthException].
  AuthException _toAuthException(AppException error) {
    return switch (error) {
      UnauthorizedException() ||
      ValidationException() =>
        const AuthException('Invalid username or password.'),
      _ => AuthException(error.message),
    };
  }
}
