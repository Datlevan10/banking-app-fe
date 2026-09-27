import 'package:dio/dio.dart';

import 'token_store.dart';

/// Attaches the JWT bearer token to protected requests.
///
/// Endpoints that must NOT carry the token (login, register, OTP) opt out via
/// `Options(extra: {AuthInterceptor.skipAuthKey: true})`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  /// Request `extra` flag to skip attaching the token.
  static const String skipAuthKey = 'skipAuth';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final bool skip = options.extra[skipAuthKey] == true;
    final String? token = _tokenStore.accessToken;

    if (!skip && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
