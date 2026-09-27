import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/app_exception.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'token_store.dart';

/// Thin, typed wrapper around [Dio].
///
/// - Wires the [AuthInterceptor] and [ErrorInterceptor].
/// - Exposes small `get`/`post` helpers that return the decoded JSON body and
///   throw typed [AppException]s (never raw `DioException`s).
class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio})
      : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..contentType = Headers.jsonContentType
      ..responseType = ResponseType.json;

    _dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(tokenStore),
      const ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  /// POST returning the decoded JSON body.
  ///
  /// Set [requiresAuth] to false for public endpoints (login, register).
  Future<dynamic> post(
    String path, {
    Object? data,
    bool requiresAuth = true,
  }) =>
      _send(() => _dio.post<dynamic>(
            path,
            data: data,
            options: _options(requiresAuth),
          ));

  /// GET returning the decoded JSON body.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) =>
      _send(() => _dio.get<dynamic>(
            path,
            queryParameters: queryParameters,
            options: _options(requiresAuth),
          ));

  Options _options(bool requiresAuth) => Options(
        extra: <String, dynamic>{AuthInterceptor.skipAuthKey: !requiresAuth},
      );

  /// Runs a request and normalises errors into typed [AppException]s.
  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final Response<dynamic> response = await request();
      return response.data;
    } on DioException catch (e) {
      // ErrorInterceptor already mapped this; surface the typed exception.
      final Object? mapped = e.error;
      if (mapped is AppException) throw mapped;
      throw const UnknownApiException();
    }
  }
}
