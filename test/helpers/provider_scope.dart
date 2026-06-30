import 'package:comfy_list/features/appointments/data/datasources/firestore_appointments_remote.dart';
import 'package:comfy_list/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/auth/data/datasources/identity_toolkit_remote.dart';
import 'package:comfy_list/features/auth/domain/entities/auth_user.dart';
import 'package:comfy_list/features/auth/domain/repositories/auth_repository.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_provider.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/todo_lists/data/datasources/firestore_lists_remote.dart';
import 'package:comfy_list/features/todo_lists/domain/repositories/todo_lists_repository.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:comfy_list/shared/data/local/database_provider.dart';
import 'package:comfy_list/shared/data/secure/secure_session_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// `Override` no se re-exporta desde `package:flutter_riverpod/flutter_riverpod.dart`
// (está marcado `@publicInCodegen`). Se importa desde la ruta interna
// de `flutter_riverpod` para evitar obligar al call-site a declarar
// `List<dynamic>` y mantener el tipado fuerte en el helper.
// ignore: implementation_imports
import 'package:flutter_riverpod/src/internals.dart' show Override;

/// Mock no-op del almacén seguro — los métodos retornan valores neutros
/// (null / false / `Future.value()`) salvo que el test los sobreescriba
/// con `when(...)`. Hand-declared, sin codegen (ver D-MockSecureSessionStore).
class MockSecureSessionStore extends Mock implements SecureSessionStore {}

/// Stub de [AuthNotifier] que devuelve un [AuthState] fijo sin hacer
/// bootstrap. Permite que un test arranque directamente en
/// [Authenticated]/[Unauthenticated] sin depender de
/// `authRepositoryProvider`.
class StaticAuthNotifier extends AuthNotifier {
  StaticAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

/// Construye un [ProviderContainer] aislado para tests de notifier/repo.
///
/// Por defecto:
///  - `appDatabaseProvider` lanza un error salvo que se pase
///    `withInMemoryDb: true` (el test debe ser explícito si necesita DB).
///  - `authProvider` arranca en [Unauthenticated] (via [StaticAuthNotifier]).
///    Pasar `authedUser: buildAuthUser()` lo arranca en [Authenticated]
///    con ese usuario, o `authState: ...` para una variante custom
///    (p. ej. [AuthLoading]).
///  - `secureSessionStoreProvider` devuelve un [MockSecureSessionStore] para
///    que un `ref.read` accidental no toque `flutter_secure_storage` real.
///  - `dioClientProvider` se construye con ese mock, de modo que un
///    `ref.read` accidental tampoco instancia HTTP real (los DIO internos
///    del `DioClient` nunca se usan en tests de notifier).
///
/// `repositoryOverrides` y `remoteOverrides` aceptan un mapa `Type → mock`
/// (D-MockAtDatasourceLayer). Para un override que no entre en el registro
/// conocido, usar `extra: [provider.overrideWithValue(mock)]`.
///
/// `addTearDown(container.dispose)` se registra automáticamente.
ProviderContainer createTestContainer({
  bool withInMemoryDb = false,
  AuthUser? authedUser,
  AuthState? authState,
  Map<Type, Object> repositoryOverrides = const {},
  Map<Type, Object> remoteOverrides = const {},
  List<Override> extra = const [],
}) {
  final overrides = <Override>[
    secureSessionStoreProvider.overrideWithValue(MockSecureSessionStore()),
  ];

  if (withInMemoryDb) {
    overrides.add(
      appDatabaseProvider.overrideWithValue(
        AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    );
  }

  final effectiveAuthState = authState ??
      (authedUser != null ? Authenticated(authedUser) : const Unauthenticated());
  overrides.add(
    authProvider.overrideWith(() => StaticAuthNotifier(effectiveAuthState)),
  );

  overrides.addAll(_mapRepositoryOverrides(repositoryOverrides));
  overrides.addAll(_mapRemoteOverrides(remoteOverrides));
  overrides.addAll(extra);

  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

List<Override> _mapRepositoryOverrides(Map<Type, Object> overrides) {
  return [
    for (final entry in overrides.entries)
      _repositoryOverrideFor(entry.key, entry.value),
  ];
}

Override _repositoryOverrideFor(Type type, Object value) {
  if (type == AuthRepository) {
    return authRepositoryProvider.overrideWithValue(value as AuthRepository);
  }
  if (type == TodoListsRepository) {
    return todoListsRepositoryProvider
        .overrideWithValue(value as TodoListsRepository);
  }
  if (type == TodosRepository) {
    return todosRepositoryProvider.overrideWithValue(value as TodosRepository);
  }
  if (type == AppointmentsRepository) {
    return appointmentsRepositoryProvider
        .overrideWithValue(value as AppointmentsRepository);
  }
  if (type == SettingsRepository) {
    return settingsRepositoryProvider
        .overrideWithValue(value as SettingsRepository);
  }
  throw StateError(
    'createTestContainer: type $type no está registrado en '
    'repositoryOverrides. Usa `extra: [provider.overrideWithValue(mock)]` '
    'o añade el caso al switch de _repositoryOverrideFor.',
  );
}

List<Override> _mapRemoteOverrides(Map<Type, Object> overrides) {
  return [
    for (final entry in overrides.entries)
      _remoteOverrideFor(entry.key, entry.value),
  ];
}

Override _remoteOverrideFor(Type type, Object value) {
  if (type == IdentityToolkitRemote) {
    return identityToolkitRemoteProvider
        .overrideWithValue(value as IdentityToolkitRemote);
  }
  if (type == FirestoreListsRemote) {
    return firestoreListsRemoteProvider
        .overrideWithValue(value as FirestoreListsRemote);
  }
  if (type == FirestoreRestRemote) {
    return firestoreRestRemoteProvider
        .overrideWithValue(value as FirestoreRestRemote);
  }
  if (type == FirestoreAppointmentsRemote) {
    return firestoreAppointmentsRemoteProvider
        .overrideWithValue(value as FirestoreAppointmentsRemote);
  }
  throw StateError(
    'createTestContainer: type $type no está registrado en remoteOverrides. '
    'Usa `extra: [provider.overrideWithValue(mock)]` o añade el caso al '
    'switch de _remoteOverrideFor.',
  );
}
