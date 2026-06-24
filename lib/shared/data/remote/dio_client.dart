import 'package:dio/dio.dart';

import '../secure/secure_session_store.dart';
import 'auth_interceptor.dart';

/// Singleton de Dio compartido por todas las features.
///
/// Reglas:
///  - Toda llamada HTTP de la app pasa por aquí.
///  - El interceptor adjunta el Bearer en peticiones a Firestore y refresca
///    el idToken cuando expira.
class DioClient {
  DioClient(this._session)
      : _refreshClient = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            responseType: ResponseType.json,
            contentType: 'application/json',
          ),
        ) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      AuthInterceptor(session: _session, refreshClient: _refreshClient),
    );
  }

  final SecureSessionStore _session;
  late final Dio _dio;
  // Cliente independiente para los endpoints de auth (signIn, signUp, refresh).
  // No lleva el interceptor para evitar bucles cuando el idToken es inválido.
  final Dio _refreshClient;

  Dio get instance => _dio;
  Dio get authClient => _refreshClient;
}
