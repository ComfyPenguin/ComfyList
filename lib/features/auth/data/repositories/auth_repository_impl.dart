import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/logging/debug_log.dart';
import '../../../../shared/core/result/result.dart';
import '../../../../shared/data/local/daos/account_cache_dao.dart';
import '../../../../shared/data/secure/secure_session_store.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/identity_toolkit_remote.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required IdentityToolkitRemote remote,
    required SecureSessionStore session,
    required AccountCacheDao accountCache,
  })  : _remote = remote,
        _session = session,
        _accountCache = accountCache;

  final IdentityToolkitRemote _remote;
  final SecureSessionStore _session;
  final AccountCacheDao _accountCache;

  @override
  Future<Result<AuthUser?>> currentUser() async {
    try {
      final hasSession = await _session.hasSession();
      if (!hasSession) return const Ok<AuthUser?>(null);

      final refreshToken = await _session.readRefreshToken();
      if (refreshToken == null) return const Ok<AuthUser?>(null);

      try {
        // Refresca para asegurar idToken válido y luego pide perfil.
        final tokens = await _remote.refresh(refreshToken);
        final lookup = await _remote.lookup(tokens.idToken);
        if (lookup == null) {
          await signOut();
          return const Ok<AuthUser?>(null);
        }

        await _session.saveSession(
          idToken: tokens.idToken,
          refreshToken: tokens.refreshToken,
          uid: lookup.localId,
        );
        await _accountCache.upsert(
          uid: lookup.localId,
          email: lookup.email,
          displayName: lookup.displayName,
        );

        return Ok<AuthUser?>(
          AuthUser(
            uid: lookup.localId,
            email: lookup.email,
            displayName: lookup.displayName,
            emailVerified: lookup.emailVerified,
          ),
        );
      } on DioException catch (e) {
        // Si el refresco falla por RED (no por credenciales rechazadas),
        // hidratamos desde la cache local para que el usuario no pierda
        // su sesión visible al abrir la app sin conexión.
        // Las llamadas a Firestore fallarán hasta que vuelva la red,
        // pero el usuario sigue dentro de la app sin tener que loguearse.
        if (_isNetworkError(e)) {
          final cached = await _readCachedUser();
          if (cached != null) return Ok<AuthUser?>(cached);
        }
        // Si el refreshToken fue rechazado (400/401), la sesión ya no vale.
        if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
          await signOut();
          return const Ok<AuthUser?>(null);
        }
        return Err<AuthUser?>(_mapDioError(e));
      }
    } catch (_) {
      return const Err<AuthUser?>(UnknownFailure());
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  Future<AuthUser?> _readCachedUser() async {
    final uid = await _session.readUid();
    if (uid == null || uid.isEmpty) return null;
    final cached = await _accountCache.findByUid(uid);
    if (cached == null) return null;
    // Sin red no hay forma de saber si el correo está verificado, así que se
    // deja en `null` y no se bloquea a quien sí lo verificó.
    return AuthUser(
      uid: cached.uid,
      email: cached.email,
      displayName: cached.displayName,
    );
  }

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _remote.signInWithPassword(
        email: email,
        password: password,
      );
      await _session.saveSession(
        idToken: res.idToken,
        refreshToken: res.refreshToken,
        uid: res.localId,
      );
      await _accountCache.upsert(
        uid: res.localId,
        email: res.email,
        displayName: res.displayName,
      );
      // El inicio de sesión no dice si el correo está verificado: hay que
      // preguntarlo, y si no hay respuesta se trata como no verificado.
      final lookup = await _remote.lookup(res.idToken);
      return Ok(AuthUser(
        uid: res.localId,
        email: res.email,
        displayName: res.displayName,
        emailVerified: lookup?.emailVerified ?? false,
      ));
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _remote.signUp(email: email, password: password);
      await _session.saveSession(
        idToken: res.idToken,
        refreshToken: res.refreshToken,
        uid: res.localId,
      );
      await _accountCache.upsert(
        uid: res.localId,
        email: res.email,
        displayName: res.displayName,
      );
      // La cuenta recién creada nunca está verificada: se manda el correo de
      // una vez para que la pantalla de verificación tenga algo que esperar.
      await _sendVerificationEmailBestEffort(res.idToken);
      return Ok(AuthUser(
        uid: res.localId,
        email: res.email,
        displayName: res.displayName,
        emailVerified: false,
      ));
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    // Paso 1 — flujo nativo de Google. Lanza GoogleSignInException si el
    // usuario cancela el popup o si el SDK está mal configurado.
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
      debugLog('[AuthRepo] GoogleSignIn.authenticate() OK → ${account.email}');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('[AuthRepo] GoogleSignIn cancelado por el usuario.');
        return const Err(GoogleSignInCancelledFailure());
      }
      debugPrint('[AuthRepo] GoogleSignInException: ${e.code} — ${e.description}');
      return Err(GoogleSignInFailure(
        e.description ?? 'No se ha podido iniciar sesión con Google.',
      ));
    } catch (e, st) {
      debugPrint('[AuthRepo] Error inesperado en GoogleSignIn: $e\n$st');
      return const Err(GoogleSignInFailure());
    }

    final googleIdToken = account.authentication.idToken;
    debugLog('[AuthRepo] idToken recibido: ${googleIdToken != null ? '${googleIdToken.length} chars' : 'null'}');
    if (googleIdToken == null || googleIdToken.isEmpty) {
      // Sin ID token no podemos verificarlo en Firebase. Causa habitual:
      // serverClientId vacío o mal configurado en initialize().
      debugPrint('[AuthRepo] idToken vacío — serverClientId mal configurado.');
      return const Err(GoogleSignInFailure(
        'Google no ha devuelto un token válido. Revisa la configuración.',
      ));
    }

    // Paso 2 — intercambio en Firebase Identity Toolkit.
    try {
      final res = await _remote.signInWithGoogle(googleIdToken: googleIdToken);
      debugLog('[AuthRepo] Firebase signInWithIdp OK → uid=${res.localId}');
      await _session.saveSession(
        idToken: res.idToken,
        refreshToken: res.refreshToken,
        uid: res.localId,
      );
      await _accountCache.upsert(
        uid: res.localId,
        email: res.email,
        displayName: res.displayName,
      );
      return Ok(AuthUser(
        uid: res.localId,
        email: res.email,
        displayName: res.displayName,
        // Google ya ha verificado ese correo por nosotros.
        emailVerified: true,
      ));
    } on DioException catch (e) {
      debugPrint('[AuthRepo] DioException en signInWithIdp: ${e.response?.statusCode} ${e.message}');
      return Err(_mapDioError(e));
    } catch (e, st) {
      debugPrint('[AuthRepo] Error inesperado en signInWithIdp: $e\n$st');
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _remote.sendPasswordResetEmail(email: email);
      return const Ok(null);
    } on DioException catch (e) {
      // Privacidad: si Firebase responde EMAIL_NOT_FOUND lo tratamos como
      // éxito silencioso para no filtrar qué cuentas existen.
      // Errores de red/timeout sí los propagamos para que el usuario pueda
      // reintentar de forma informada.
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final code = (data['error'] as Map<String, dynamic>?)?['message'];
        if (code == 'EMAIL_NOT_FOUND') return const Ok(null);
      }
      return Err(_mapDioError(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      final idToken = await _session.readIdToken();
      if (idToken == null || idToken.isEmpty) {
        return const Err(UnknownFailure());
      }
      await _remote.sendEmailVerification(idToken);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  /// El primer envío no puede tumbar el registro: la cuenta ya está creada y
  /// la pantalla de verificación trae su propio botón para reintentarlo.
  Future<void> _sendVerificationEmailBestEffort(String idToken) async {
    try {
      await _remote.sendEmailVerification(idToken);
    } on DioException {
      return;
    }
  }

  @override
  Future<void> signOut() async {
    // El refreshToken no caduca solo: sin revocarlo, quien lo tenga puede
    // seguir pidiendo idTokens después de que el usuario cierre sesión.
    await _revokeRefreshTokensBestEffort();
    // Cerramos también la sesión nativa de Google para que el siguiente
    // login no entre con el mismo usuario en silencio.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Si Google no estaba inicializado (p.ej. en plataformas no Android)
      // ignoramos: la limpieza importante es la de Firebase/local.
    }
    await _session.clear();
    await _accountCache.deleteAll();
  }

  /// Sin red o con un idToken ya caducado la sesión se cierra igual: borrar
  /// los tokens locales es lo que deja al usuario fuera ahora mismo.
  Future<void> _revokeRefreshTokensBestEffort() async {
    try {
      final idToken = await _session.readIdToken();
      if (idToken == null || idToken.isEmpty) return;
      await _remote.revokeRefreshTokens(idToken);
    } catch (_) {
      return;
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TimeoutFailure();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    // Extrae el código de error del cuerpo JSON de Firebase Identity Toolkit.
    String? code;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        code = error['message'] as String?;
      }
    }

    if (code == null) {
      return ServerFailure('Error ${e.response?.statusCode ?? "?"}');
    }
    if (code == 'EMAIL_NOT_FOUND' ||
        code == 'INVALID_PASSWORD' ||
        code == 'INVALID_LOGIN_CREDENTIALS') {
      return const InvalidCredentialsFailure();
    }
    if (code == 'EMAIL_EXISTS') return const EmailAlreadyInUseFailure();
    if (code.startsWith('WEAK_PASSWORD')) return const WeakPasswordFailure();
    // Estos códigos existen para el usuario, no para que los lea tal cual: sin
    // mapear, el aviso de la pantalla enseñaba «TOO_MANY_ATTEMPTS_TRY_LATER».
    if (code == 'TOO_MANY_ATTEMPTS_TRY_LATER') {
      return const TooManyAttemptsFailure();
    }
    if (code == 'USER_DISABLED') return const AccountDisabledFailure();
    if (code == 'PASSWORD_LOGIN_DISABLED' || code == 'OPERATION_NOT_ALLOWED') {
      return const PasswordLoginDisabledFailure();
    }
    return ServerFailure(code);
  }
}
