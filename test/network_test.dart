// Tests for the network layer: status-code → AppException mapping, the auth
// bearer interceptor, and the migrated AuthRepositoryImpl.

import 'dart:typed_data';

import 'package:banking_app_fe/core/error/app_exception.dart';
import 'package:banking_app_fe/core/network/api_client.dart';
import 'package:banking_app_fe/core/network/token_store.dart';
import 'package:banking_app_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:banking_app_fe/features/auth/data/repositories/auth_mock_repository.dart';
import 'package:banking_app_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:banking_app_fe/features/auth/domain/entities/auth_user.dart';
import 'package:banking_app_fe/features/auth/domain/failures/auth_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Responder = Future<ResponseBody> Function(RequestOptions options);

/// A Dio adapter that returns canned responses (or throws) and records the
/// last request so we can assert on headers.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  _Responder responder;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    lastOptions = options;
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status) => ResponseBody.fromString(
      body,
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

({ApiClient client, _FakeAdapter adapter, TokenStore store}) _build(
  _Responder responder,
) {
  final TokenStore store = InMemoryTokenStore();
  final Dio dio = Dio();
  final ApiClient client = ApiClient(tokenStore: store, dio: dio);
  final _FakeAdapter adapter = _FakeAdapter(responder);
  dio.httpClientAdapter = adapter;
  return (client: client, adapter: adapter, store: store);
}

void main() {
  group('ApiClient error mapping', () {
    test('200 returns the decoded body', () async {
      final rig = _build((_) async => _json('{"ok":true}', 200));
      final dynamic body = await rig.client.get('/x');
      expect(body, <String, dynamic>{'ok': true});
    });

    test('401 → UnauthorizedException', () async {
      final rig = _build((_) async => _json('{"message":"nope"}', 401));
      expect(rig.client.get('/x'), throwsA(isA<UnauthorizedException>()));
    });

    test('403 → ForbiddenException', () async {
      final rig = _build((_) async => _json('{}', 403));
      expect(rig.client.get('/x'), throwsA(isA<ForbiddenException>()));
    });

    test('422 → ValidationException with field errors', () async {
      final rig = _build((_) async => _json(
            '{"errors":{"username":["already taken"]}}',
            422,
          ));
      try {
        await rig.client.post('/x', data: <String, dynamic>{});
        fail('should have thrown');
      } on ValidationException catch (e) {
        expect(e.fieldErrors['username'], 'already taken');
      }
    });

    test('500 → ServerException', () async {
      final rig = _build((_) async => _json('{}', 500));
      expect(rig.client.get('/x'), throwsA(isA<ServerException>()));
    });

    test('connection error → ConnectionException', () async {
      final rig = _build((RequestOptions o) async =>
          throw DioException.connectionError(
            requestOptions: o,
            reason: 'offline',
          ));
      expect(rig.client.get('/x'), throwsA(isA<ConnectionException>()));
    });
  });

  group('AuthInterceptor', () {
    test('attaches bearer token on protected requests', () async {
      final rig = _build((_) async => _json('{}', 200));
      await rig.store.saveToken('jwt-123');
      await rig.client.get('/protected');
      expect(
        rig.adapter.lastOptions?.headers['Authorization'],
        'Bearer jwt-123',
      );
    });

    test('omits token when requiresAuth is false', () async {
      final rig = _build((_) async => _json('{}', 200));
      await rig.store.saveToken('jwt-123');
      await rig.client.post('/login', requiresAuth: false);
      expect(
        rig.adapter.lastOptions?.headers.containsKey('Authorization'),
        false,
      );
    });
  });

  group('AuthRepositoryImpl (real)', () {
    AuthRepositoryImpl buildRepo(_FakeAdapter adapter, TokenStore store) {
      final Dio dio = Dio();
      final ApiClient client = ApiClient(tokenStore: store, dio: dio);
      dio.httpClientAdapter = adapter;
      return AuthRepositoryImpl(
        remote: AuthRemoteDataSource(client),
        onToken: store.saveToken,
        fallback: AuthMockRepository(),
      );
    }

    test('successful login returns the user and stores the token', () async {
      final TokenStore store = InMemoryTokenStore();
      final adapter = _FakeAdapter((_) async => _json(
            '{"accessToken":"tok-9","user":{"id":"u1","fullName":"Ada"}}',
            200,
          ));
      final AuthRepositoryImpl repo = buildRepo(adapter, store);

      final AuthUser user = await repo.authenticateWithCredentials(
        username: 'ada',
        password: 'secret',
      );

      expect(user.name, 'Ada');
      expect(store.accessToken, 'tok-9');
    });

    test('401 maps to a domain AuthException', () async {
      final store = InMemoryTokenStore();
      final adapter = _FakeAdapter((_) async => _json('{}', 401));
      final AuthRepositoryImpl repo = buildRepo(adapter, store);

      expect(
        repo.authenticateWithCredentials(username: 'x', password: 'y'),
        throwsA(isA<AuthException>()),
      );
    });

    test('offline falls back to the mock repository', () async {
      final store = InMemoryTokenStore();
      final adapter = _FakeAdapter((RequestOptions o) async =>
          throw DioException.connectionError(
            requestOptions: o,
            reason: 'offline',
          ));
      final AuthRepositoryImpl repo = buildRepo(adapter, store);

      // Mock demo credentials succeed even though the network is down.
      final AuthUser user = await repo.authenticateWithCredentials(
        username: 'vandat',
        password: 'password',
      );
      expect(user.name, 'Van Dat');
    });
  });
}
