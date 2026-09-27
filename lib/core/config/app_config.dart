/// Compile-time application configuration.
///
/// Values are provided via `--dart-define` so the same binary can target
/// different environments without code changes, e.g.:
///
/// ```
/// flutter run \
///   --dart-define=API_BASE_URL=https://api.novabank.com \
///   --dart-define=USE_MOCK=false
/// ```
///
/// Defaults keep local development and the test suite working fully offline
/// (mock data, no network required).
abstract final class AppConfig {
  const AppConfig._();

  /// Base URL of the C# .NET backend. `10.0.2.2` maps to the host machine's
  /// `localhost` from the Android emulator.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  /// When true, features resolve their mock repositories instead of hitting the
  /// network. Defaults to true so offline dev + tests never break.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  /// Even when [useMock] is false, real repositories may fall back to their
  /// mock behaviour if the backend is unreachable (connection errors only).
  static const bool fallbackToMockWhenOffline = bool.fromEnvironment(
    'OFFLINE_FALLBACK',
    defaultValue: true,
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
