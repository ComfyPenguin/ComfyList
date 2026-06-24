import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../models/auth_dto.dart';

/// Datasource para Identity Toolkit (Firebase Auth REST).
///
/// Usa el cliente "auth" de [DioClient] (sin AuthInterceptor) porque las
/// llamadas signUp/signIn no llevan Bearer y deben evitar el ciclo de refresh.
class IdentityToolkitRemote {
  IdentityToolkitRemote(this._dio);

  final Dio _dio;

  Future<IdentityAuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.identityBase}:signUp?key=${FirebaseEndpoints.apiKey}',
      data: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
    return IdentityAuthResponse.fromJson(res.data!);
  }

  Future<IdentityAuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.identityBase}:signInWithPassword?key=${FirebaseEndpoints.apiKey}',
      data: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
    return IdentityAuthResponse.fromJson(res.data!);
  }

  /// Intercambia un ID token de Google por tokens de Firebase via
  /// `accounts:signInWithIdp`. Si el usuario no existe en Firebase Auth,
  /// se crea automáticamente (sign-in y sign-up usan el mismo endpoint).
  Future<IdentityAuthResponse> signInWithGoogle({
    required String googleIdToken,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.identityBase}:signInWithIdp?key=${FirebaseEndpoints.apiKey}',
      data: {
        // postBody usa formato form-encoded dentro del JSON: así lo exige
        // el endpoint signInWithIdp para identificar provider + token.
        'postBody': 'id_token=$googleIdToken&providerId=google.com',
        'requestUri': 'http://localhost',
        'returnIdpCredential': true,
        'returnSecureToken': true,
      },
    );
    return IdentityAuthResponse.fromJson(res.data!);
  }

  /// Envía un email con enlace de restablecimiento de contraseña.
  /// El usuario recibe un correo de Firebase con un enlace que abre la página
  /// de reset (gestionada por Firebase Auth).
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.identityBase}:sendOobCode?key=${FirebaseEndpoints.apiKey}',
      data: {
        'requestType': 'PASSWORD_RESET',
        'email': email,
      },
    );
  }

  /// Devuelve el primer usuario de `accounts:lookup` para el idToken dado.
  Future<IdentityLookupUser?> lookup(String idToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.identityBase}:lookup?key=${FirebaseEndpoints.apiKey}',
      data: {'idToken': idToken},
    );
    final users = (res.data?['users'] as List?) ?? const [];
    if (users.isEmpty) return null;
    return IdentityLookupUser.fromJson(users.first as Map<String, dynamic>);
  }

  /// Refresca el idToken con el refreshToken. Devuelve el nuevo (idToken, refreshToken).
  Future<({String idToken, String refreshToken})> refresh(
    String refreshToken,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.tokenBase}?key=${FirebaseEndpoints.apiKey}',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    final body = res.data!;
    return (
      idToken: body['id_token'] as String,
      refreshToken: body['refresh_token'] as String? ?? refreshToken,
    );
  }
}
