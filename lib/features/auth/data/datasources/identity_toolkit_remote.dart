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

  /// Manda el correo de verificación de la cuenta dueña de [idToken].
  Future<void> sendEmailVerification(String idToken) async {
    await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.identityBase}:sendOobCode?key=${FirebaseEndpoints.apiKey}',
      data: {
        'requestType': 'VERIFY_EMAIL',
        'idToken': idToken,
      },
    );
  }

  /// Invalida en el servidor los tokens emitidos antes de ahora para la cuenta
  /// de [idToken] (`validSince`). Un refreshToken filtrado deja de valer.
  Future<void> revokeRefreshTokens(String idToken) async {
    await _dio.post<Map<String, dynamic>>(
      '${FirebaseEndpoints.identityBase}:update?key=${FirebaseEndpoints.apiKey}',
      data: {
        'idToken': idToken,
        'validSince': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
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
}
