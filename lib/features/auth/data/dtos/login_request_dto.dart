/// Request body for `POST /api/v1/auth/login`.
///
/// DTOs live in the data layer and own JSON (de)serialization, keeping the
/// domain entities free of transport concerns. Hand-written here to avoid a
/// build_runner step; swap for `json_serializable` if the surface grows.
class LoginRequestDto {
  const LoginRequestDto({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'username': username,
        'password': password,
      };
}
