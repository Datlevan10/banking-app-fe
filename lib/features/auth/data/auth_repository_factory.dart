import '../../../core/config/app_config.dart';
import '../../../core/network/network_module.dart';
import '../domain/repositories/auth_repository.dart';
import 'datasources/auth_remote_data_source.dart';
import 'repositories/auth_mock_repository.dart';
import 'repositories/auth_repository_impl.dart';

/// Composition root for the auth feature's repository.
///
/// Returns the mock repository when [AppConfig.useMock] is true (default —
/// keeps local dev + tests offline), otherwise the real API-backed repository
/// with the mock injected as the fallback for offline / not-yet-migrated flows.
AuthRepository createAuthRepository() {
  final AuthMockRepository mock = AuthMockRepository();
  if (AppConfig.useMock) return mock;

  final NetworkModule net = NetworkModule.instance;
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(net.apiClient),
    onToken: net.tokenStore.saveToken,
    fallback: mock,
  );
}
