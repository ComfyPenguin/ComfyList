import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/features/trash/presentation/providers/trash_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/fake_trash_remote.dart';
import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late FakeTrashRemote trash;

  setUp(() {
    trash = FakeTrashRemote();
  });

  Future<void> seedOldEntry({required int days}) => trash.createEntry(
        uid: 'u1',
        groupId: 'g1',
        item: const TrashItem(
          kind: TrashKind.todo,
          itemId: 't1',
          label: 'Comprar pan',
          payload: {},
        ),
        deletedAt: DateTime.now().toUtc().subtract(Duration(days: days)),
      );

  ProviderContainer containerWith({
    required FakeSettingsRepository settings,
    AuthState? authState,
  }) {
    addTearDown(settings.close);
    return createTestContainer(
      authedUser: authState == null ? buildAuthUser() : null,
      authState: authState,
      remoteOverrides: {FirestoreTrashRemote: trash},
      repositoryOverrides: {SettingsRepository: settings},
    );
  }

  test('al abrir la app vacía solo lo que pasó el plazo', () async {
    final container = containerWith(
      settings: FakeSettingsRepository(
        settings: buildAppSettings(trashRetentionDays: 7),
      ),
    );
    await seedOldEntry(days: 20);

    // Activar el provider es lo que hace `app.dart`.
    container.listen(trashPurgeProvider, (_, _) {});
    await pumpEventQueue();

    expect(trash.entries, isEmpty);
  });

  test('con «nunca» la papelera se queda como esté', () async {
    final container = containerWith(
      settings: FakeSettingsRepository(
        settings: buildAppSettings(trashRetentionDays: 0),
      ),
    );
    await seedOldEntry(days: 300);

    container.listen(trashPurgeProvider, (_, _) {});
    await pumpEventQueue();

    expect(trash.entries, hasLength(1));
  });

  test('sin los ajustes leídos no se purga con el plazo de fábrica', () async {
    // El plazo de fábrica es un mes: darlo por bueno antes de leer las
    // preferencias borraría de más a quien tenga «nunca» puesto.
    final settings = FakeSettingsRepository(
      settings: buildAppSettings(trashRetentionDays: 0),
    )..fail = true;
    final container = containerWith(settings: settings);
    await seedOldEntry(days: 300);

    container.listen(trashPurgeProvider, (_, _) {});
    await pumpEventQueue();

    expect(trash.entries, hasLength(1));
  });

  test('sin sesión no hay papelera que vaciar', () async {
    final container = containerWith(
      authState: const Unauthenticated(),
      settings: FakeSettingsRepository(
        settings: buildAppSettings(trashRetentionDays: 7),
      ),
    );
    await seedOldEntry(days: 20);

    container.listen(trashPurgeProvider, (_, _) {});
    await pumpEventQueue();

    expect(trash.entries, hasLength(1));
  });
}
