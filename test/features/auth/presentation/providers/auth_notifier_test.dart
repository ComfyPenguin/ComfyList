import 'package:comfy_list/features/auth/domain/entities/auth_user.dart';
import 'package:comfy_list/features/auth/domain/repositories/auth_repository.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_provider.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    // El AuthNotifier real hace bootstrap asíncrono (microtask) que llama
    // a `currentUser()`. Para que ese microtask no lance, siempre lo
    // dejamos como `Ok(null)` por defecto; los tests que necesiten otro
    // valor lo sobreescriben.
    when(() => repo.currentUser())
        .thenAnswer((_) async => const Ok<AuthUser?>(null));
  });

  /// Construye un ProviderContainer con el AuthNotifier REAL (no el
  /// `StaticAuthNotifier` por defecto) y el repo mockeado. No usamos
  /// `createTestContainer` porque su `StaticAuthNotifier` override choca
  /// con `authProvider.overrideWith(AuthNotifier.new)`.
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        secureSessionStoreProvider.overrideWithValue(MockSecureSessionStore()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthNotifier', () {
    test('bootstrap transitions AuthInitial → AuthLoading → Unauthenticated',
        () async {
      final container = buildContainer();

      // El build() síncrono devuelve AuthInitial y agenda el microtask.
      expect(container.read(authProvider), isA<AuthInitial>());

      await pumpEventQueue();

      expect(container.read(authProvider), isA<Unauthenticated>());
    });

    test('bootstrap transitions to Authenticated when currentUser returns a user',
        () async {
      const user = AuthUser(uid: 'u-1', email: 'a@b.c', displayName: 'Ana');
      when(() => repo.currentUser())
          .thenAnswer((_) async => const Ok<AuthUser?>(user));

      final container = buildContainer();

      // Forzamos el build para que se agende el microtask del bootstrap.
      expect(container.read(authProvider), isA<AuthInitial>());

      await pumpEventQueue();

      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).user.uid, 'u-1');
      expect(state.user.email, 'a@b.c');
      expect(state.user.displayName, 'Ana');
    });

    test('signIn transitions AuthLoading → Authenticated on Ok', () async {
      const user = AuthUser(uid: 'u-1', email: 'a@b.c');
      when(() => repo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Ok<AuthUser>(user));

      final container = buildContainer();

      // Forzamos el build del notifier (AuthInitial) sin esperar bootstrap.
      expect(container.read(authProvider), isA<AuthInitial>());

      await container.read(authProvider.notifier).signIn(
            email: 'a@b.c',
            password: 'pw!',
          );

      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).user.uid, 'u-1');
    });

    test('signIn transitions AuthLoading → AuthError on Err', () async {
      when(() => repo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => const Err<AuthUser>(InvalidCredentialsFailure()),
      );

      final container = buildContainer();

      expect(container.read(authProvider), isA<AuthInitial>());

      await container.read(authProvider.notifier).signIn(
            email: 'a@b.c',
            password: 'wrong',
          );

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).failure, isA<InvalidCredentialsFailure>());
    });

    test('clearError resets AuthError to Unauthenticated', () async {
      when(() => repo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => const Err<AuthUser>(InvalidCredentialsFailure()),
      );

      final container = buildContainer();

      expect(container.read(authProvider), isA<AuthInitial>());

      await container.read(authProvider.notifier).signIn(
            email: 'a@b.c',
            password: 'wrong',
          );
      expect(container.read(authProvider), isA<AuthError>());

      container.read(authProvider.notifier).clearError();

      expect(container.read(authProvider), isA<Unauthenticated>());
    });
  });
}
