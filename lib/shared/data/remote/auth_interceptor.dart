import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/env/firebase_endpoints.dart';
import '../secure/secure_session_store.dart';
import 'token_refresher.dart';

/// Interceptor que:
///  - Adjunta `Authorization: Bearer <idToken>` en cada llamada a Firestore.
///  - Refresca el idToken (con el [TokenRefresher]) si la respuesta es 401.
///  - Reintenta la petición original una sola vez tras refrescar.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SecureSessionStore session,
    required Dio refreshClient,
    required TokenRefresher refresher,
  })  : _session = session,
        _refreshClient = refreshClient,
        _refresher = refresher;

  final SecureSessionStore _session;
  // Cliente Dio separado, sin este interceptor, para reintentar la petición
  // original tras refrescar sin entrar en bucle.
  final Dio _refreshClient;
  final TokenRefresher _refresher;

  static const _retriedFlag = 'auth_retried';

  bool _shouldAttachToken(Uri uri) {
    return uri.toString().startsWith(FirebaseEndpoints.firestoreBase);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldAttachToken(options.uri)) {
      final token = await _session.readIdToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;

    if (!isUnauthorized ||
        alreadyRetried ||
        !_shouldAttachToken(err.requestOptions.uri)) {
      return handler.next(err);
    }

    final outcome = await _refresher.refresh(
      staleIdToken: _bearerOf(err.requestOptions),
    );
    if (outcome is! Refreshed) {
      return handler.next(err);
    }

    final retryOptions = err.requestOptions
      ..headers['Authorization'] = 'Bearer ${outcome.idToken}'
      ..extra[_retriedFlag] = true;

    try {
      final response = await _refreshClient.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// El idToken con el que se mandó la petición, si llevaba uno.
  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    return header is String && header.startsWith('Bearer ')
        ? header.substring('Bearer '.length)
        : null;
  }
}
