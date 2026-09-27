import 'api_client.dart';
import 'token_store.dart';

/// Minimal composition root for shared network singletons.
///
/// A single [ApiClient] / [TokenStore] is reused across the app so the Dio
/// instance (connection pool) and the session token are shared. In a larger
/// app this is where a DI container (e.g. `get_it`) would live.
class NetworkModule {
  NetworkModule._();

  static final NetworkModule instance = NetworkModule._();

  late final TokenStore tokenStore = InMemoryTokenStore();

  late final ApiClient apiClient = ApiClient(tokenStore: tokenStore);
}
