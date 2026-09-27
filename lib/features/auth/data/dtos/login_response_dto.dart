import '../../domain/entities/auth_user.dart';

/// Response body for `POST /api/v1/auth/login`.
///
/// Tolerant parsing: accepts a few common key spellings the C# backend might
/// use (`accessToken`/`token`, `user`/`data`) so minor contract drift doesn't
/// crash the client.
class LoginResponseDto {
  const LoginResponseDto({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUserDto user;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final Object? token = json['accessToken'] ?? json['token'];
    final Object? userJson = json['user'] ?? json['data'];

    if (token is! String || token.isEmpty || userJson is! Map) {
      throw const FormatException('Malformed login response');
    }

    return LoginResponseDto(
      accessToken: token,
      user: AuthUserDto.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }
}

/// The user object nested in the login response.
class AuthUserDto {
  const AuthUserDto({required this.id, required this.name});

  final String id;
  final String name;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['username'] ?? 'User')
          .toString(),
    );
  }

  /// Maps the DTO to the domain entity.
  AuthUser toEntity() => AuthUser(id: id, name: name);
}
