import 'package:dio/dio.dart';

import '../error/app_exception.dart';

/// Global network error handler.
///
/// Converts every [DioException] into a typed [AppException] and rejects with
/// it attached to `DioException.error`. The [ApiClient] then unwraps and throws
/// the [AppException], so callers only ever handle our typed failures.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final AppException mapped = _map(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
        stackTrace: err.stackTrace,
      ),
    );
  }

  AppException _map(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const ConnectionException();
      case DioExceptionType.cancel:
        return const ConnectionException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ConnectionException('Insecure server certificate.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return _mapResponse(err);
    }
  }

  AppException _mapResponse(DioException err) {
    final Response<dynamic>? response = err.response;
    final int? status = response?.statusCode;
    final dynamic data = response?.data;

    switch (status) {
      case 401:
        return UnauthorizedException(_serverMessage(data) ??
            'Your session has expired. Please sign in again.');
      case 403:
        return ForbiddenException(_serverMessage(data) ??
            'You do not have permission to perform this action.');
      case 422:
        return ValidationException(
          message: _serverMessage(data) ??
              'Some of the information provided is invalid.',
          fieldErrors: _fieldErrors(data),
        );
      case null:
        return const ConnectionException();
      default:
        if (status >= 500) {
          return ServerException(
            _serverMessage(data) ??
                'Something went wrong on our end. Please try again later.',
            status,
          );
        }
        return UnknownApiException(
          _serverMessage(data) ?? 'An unexpected error occurred.',
          status,
        );
    }
  }

  /// Extracts a top-level `message`/`error`/`title` string from an error body.
  String? _serverMessage(dynamic data) {
    if (data is Map) {
      final Object? msg = data['message'] ?? data['error'] ?? data['title'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return null;
  }

  /// Extracts ASP.NET-style `errors: { field: [msg, ...] }` into a flat map.
  Map<String, String> _fieldErrors(dynamic data) {
    final Map<String, String> result = <String, String>{};
    if (data is Map && data['errors'] is Map) {
      (data['errors'] as Map).forEach((dynamic key, dynamic value) {
        final String field = key.toString();
        if (value is List && value.isNotEmpty) {
          result[field] = value.first.toString();
        } else if (value is String) {
          result[field] = value;
        }
      });
    }
    return result;
  }
}
