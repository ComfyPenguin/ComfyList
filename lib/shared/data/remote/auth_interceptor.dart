import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/env/firebase_endpoints.dart';
import '../secure/secure_session_store.dart';

/// Interceptor que:
///  - Adjunta `Authorization: Bearer <idToken>` en cada llamada a Firestore.
///  - Refresca el idToken con el refreshToken si la respuesta es 401.
///  - Reintenta la petición original una sola vez tras refrescar.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SecureSessionStore session,
    required Dio refreshClient,
  })  : _session = session,
        _refreshClient = refreshClient;

  final SecureSessionStore _session;
  // Cliente Dio separado SOLO para el refresh, evitando recursión por el
  // propio interceptor.
  final Dio _refreshClient;

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

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      return handler.next(err);
    }

    final newToken = await _session.readIdToken();
    final retryOptions = err.requestOptions
      ..headers['Authorization'] = 'Bearer $newToken'
      ..extra[_retriedFlag] = true;

    try {
      final response = await _refreshClient.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _session.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await _refreshClient.post<Map<String, dynamic>>(
        '${FirebaseEndpoints.tokenBase}?key=${FirebaseEndpoints.apiKey}',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      final body = res.data;
      if (body == null) return false;

      final newId = body['id_token'] as String?;
      final newRefresh = body['refresh_token'] as String?;
      if (newId == null) return false;

      if (newRefresh != null) {
        // securetoken puede rotar el refresh: persistimos el nuevo par, pero
        // nunca con un uid vacío.
        final uid = await _session.readUid() ?? (body['user_id'] as String?);
        if (uid == null || uid.isEmpty) return false;
        await _session.saveSession(
          idToken: newId,
          refreshToken: newRefresh,
          uid: uid,
        );
      } else {
        await _session.updateIdToken(newId);
      }
      return true;
    } on DioException {
      return false;
    }
  }
}
