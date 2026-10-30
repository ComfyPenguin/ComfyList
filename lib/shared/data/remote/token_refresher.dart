import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/env/firebase_endpoints.dart';
import '../secure/secure_session_store.dart';

/// Cómo acabó un refresco de tokens.
sealed class RefreshOutcome {
  const RefreshOutcome();
}

/// Hay un idToken válido y ya está guardado junto al [refreshToken] vigente.
class Refreshed extends RefreshOutcome {
  const Refreshed({required this.idToken, required this.refreshToken});

  final String idToken;
  final String refreshToken;
}

/// El servidor no dio tokens utilizables: no hay refreshToken, lo rechazó
/// (400/401) o la respuesta no permitía guardar la sesión. Esa sesión ya no
/// vale.
class RefreshRejected extends RefreshOutcome {
  const RefreshRejected();
}

/// No se pudo preguntar (sin red, tiempo agotado, fallo del servidor): la
/// sesión puede seguir valiendo. Lleva el [error] para que quien llama decida.
class RefreshUnavailable extends RefreshOutcome {
  const RefreshUnavailable(this.error);

  final DioException error;
}

/// Renueva el idToken con el refreshToken y lo guarda. Es la única manera en
/// que la app refresca la sesión: la usan el interceptor, tras un 401 de
/// Firestore, y el arranque de la sesión.
///
/// Varios refrescos a la vez comparten una sola petición: securetoken puede
/// rotar el refreshToken, y pedirlo dos veces seguidas con el viejo es una
/// carrera.
class TokenRefresher {
  TokenRefresher({
    required SecureSessionStore session,
    required Dio client,
  })  : _session = session,
        _client = client;

  final SecureSessionStore _session;

  // Cliente Dio sin interceptor: refrescar no puede pasar por el refresco.
  final Dio _client;

  Future<RefreshOutcome>? _inFlight;

  /// Refresca la sesión. [staleIdToken] es el idToken con el que falló una
  /// petición: si desde entonces ya hay otro guardado (otro refresco acabó
  /// mientras esta petición esperaba), se usa ese sin volver a preguntar.
  Future<RefreshOutcome> refresh({String? staleIdToken}) {
    return _inFlight ??= _refresh(staleIdToken).whenComplete(
      () => _inFlight = null,
    );
  }

  Future<RefreshOutcome> _refresh(String? staleIdToken) async {
    final refreshToken = await _session.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const RefreshRejected();
    }

    if (staleIdToken != null) {
      final current = await _session.readIdToken();
      if (current != null && current.isNotEmpty && current != staleIdToken) {
        return Refreshed(idToken: current, refreshToken: refreshToken);
      }
    }

    try {
      final res = await _client.post<Map<String, dynamic>>(
        '${FirebaseEndpoints.tokenBase}?key=${FirebaseEndpoints.apiKey}',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final body = res.data;
      final newId = body?['id_token'] as String?;
      if (body == null || newId == null) return const RefreshRejected();

      final newRefresh = body['refresh_token'] as String?;
      if (newRefresh == null) {
        await _session.updateIdToken(newId);
        return Refreshed(idToken: newId, refreshToken: refreshToken);
      }

      // securetoken puede rotar el refresh: se persiste el par nuevo, pero
      // nunca con un uid vacío.
      final uid = await _session.readUid() ?? (body['user_id'] as String?);
      if (uid == null || uid.isEmpty) return const RefreshRejected();
      await _session.saveSession(
        idToken: newId,
        refreshToken: newRefresh,
        uid: uid,
      );
      return Refreshed(idToken: newId, refreshToken: newRefresh);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) return const RefreshRejected();
      return RefreshUnavailable(e);
    }
  }
}
