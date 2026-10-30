import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/logging/debug_log.dart';
import '../../../../shared/core/result/result.dart';
import '../../../../shared/data/local/database_provider.dart';
import '../../../../shared/data/remote/dio_client.dart';
import '../../../../shared/data/secure/secure_session_store.dart';
import '../../data/datasources/identity_toolkit_remote.dart';
import '../../data/datasources/login_preferences_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

// ───────── Infraestructura compartida ─────────

final secureSessionStoreProvider =
    Provider<SecureSessionStore>((ref) => SecureSessionStore());

final loginPreferencesStoreProvider =
    Provider<LoginPreferencesStore>((ref) => LoginPreferencesStore());

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(secureSessionStoreProvider));
});

// ───────── Auth feature ─────────

final identityToolkitRemoteProvider = Provider<IdentityToolkitRemote>((ref) {
  return IdentityToolkitRemote(ref.watch(dioClientProvider).authClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(identityToolkitRemoteProvider),
    session: ref.watch(secureSessionStoreProvider),
    accountCache: ref.watch(accountCacheDaoProvider),
  );
});

/// Notifier con estado sealed [AuthState].
/// Bootstrap asíncrono al construirse.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_bootstrap);
    return const AuthInitial();
  }

  Future<void> _bootstrap() async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).currentUser();
    state = result.fold(
      onOk: (user) =>
          user == null ? const Unauthenticated() : _stateFor(user),
      onErr: (_) => const Unauthenticated(),
    );
  }

  /// Con el correo sin verificar no se entra: la única pantalla posible es la
  /// de verificación. `emailVerified` nulo (sin red y sin estado guardado) sí
  /// pasa, porque no hay nada que comprobar y el corte de datos lo hace
  /// Firestore.
  AuthState _stateFor(AuthUser user) => user.emailVerified == false
      ? AuthUnverifiedEmail(user)
      : Authenticated(user);

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = result.fold(
      onOk: _stateFor,
      onErr: (f) => AuthError(f),
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signUp(email: email, password: password);
    state = result.fold(
      onOk: _stateFor,
      onErr: (f) => AuthError(f),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = result.fold(
      onOk: (user) {
        debugLog('[AuthNotifier] Google sign-in OK → uid=${user.uid}');
        return Authenticated(user);
      },
      onErr: (f) => AuthError(f),
    );
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    await ref.read(authRepositoryProvider).signOut();
    state = const Unauthenticated();
  }

  /// Reenvía el correo de verificación a la sesión que está esperando.
  Future<Result<void>> resendVerificationEmail() =>
      ref.read(authRepositoryProvider).sendEmailVerification();

  /// Vuelve a preguntar al servidor si el correo ya está verificado.
  ///
  /// `Ok(true)` ya pasa (el estado cambia a [Authenticated] y el router
  /// navega solo), `Ok(false)` es «todavía no», y `Err` que no se ha podido
  /// comprobar.
  Future<Result<bool>> checkEmailVerified() async {
    final result = await ref.read(authRepositoryProvider).currentUser();
    switch (result) {
      case Ok(value: final user):
        if (user == null) {
          state = const Unauthenticated();
          return const Ok(false);
        }
        state = _stateFor(user);
        return Ok(user.emailVerified != false);
      case Err(failure: final failure):
        return Err(failure);
    }
  }

  void clearError() {
    if (state is AuthError) state = const Unauthenticated();
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Uid de la sesión abierta. Solo vale en quien ya comprobó que hay sesión: los
/// notifiers de datos devuelven su estado inicial cuando no la hay.
extension SignedInUid on Ref {
  String get signedInUid => (read(authProvider) as Authenticated).user.uid;
}
