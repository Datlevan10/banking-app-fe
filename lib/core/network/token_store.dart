/// Holds the current session's auth tokens for the [AuthInterceptor] to read.
///
/// The in-memory implementation is fine for development. In production, swap
/// [InMemoryTokenStore] for one backed by `flutter_secure_storage` (Keychain /
/// EncryptedSharedPreferences) so the token survives restarts securely.
abstract interface class TokenStore {
  String? get accessToken;

  Future<void> saveToken(String accessToken);

  Future<void> clear();
}

/// Simple in-memory [TokenStore]. Not persisted across app restarts.
class InMemoryTokenStore implements TokenStore {
  String? _accessToken;

  @override
  String? get accessToken => _accessToken;

  @override
  Future<void> saveToken(String accessToken) async {
    _accessToken = accessToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
  }
}
