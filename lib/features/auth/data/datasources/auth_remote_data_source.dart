import '../../../../core/network/api_client.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';

/// Thin remote data source for auth endpoints.
///
/// Speaks HTTP + DTOs only; it knows nothing about domain entities or failures.
/// The repository maps its DTOs/exceptions into the domain.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  static const String _loginPath = '/api/v1/auth/login';

  /// `POST /api/v1/auth/login` — public endpoint (no bearer token).
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final dynamic body = await _client.post(
      _loginPath,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (body is! Map) {
      throw const FormatException('Unexpected login response shape');
    }
    return LoginResponseDto.fromJson(Map<String, dynamic>.from(body));
  }
}
