import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/local/database_provider.dart';
import '../../../../shared/data/remote/dio_client.dart';
import '../../../../shared/data/secure/secure_session_store.dart';
import '../../data/datasources/identity_toolkit_remote.dart';
import '../../data/datasources/login_preferences_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
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
          user == null ? const Unauthenticated() : Authenticated(user),
      onErr: (_) => const Unauthenticated(),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = result.fold(
      onOk: (user) => Authenticated(user),
      onErr: (f) => AuthError(f),
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signUp(email: email, password: password);
    state = result.fold(
      onOk: (user) => Authenticated(user),
      onErr: (f) => AuthError(f),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = result.fold(
      onOk: (user) {
        debugPrint('[AuthNotifier] Google sign-in OK → uid=${user.uid}');
        return Authenticated(user);
      },
      onErr: (f) {
        debugPrint('[AuthNotifier] Google sign-in ERROR → ${f.message}');
        return AuthError(f);
      },
    );
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    await ref.read(authRepositoryProvider).signOut();
    state = const Unauthenticated();
  }

  void clearError() {
    if (state is AuthError) state = const Unauthenticated();
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
