import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_trash_remote.dart';

/// Cuenta sin conexión: cualquier llamada revienta como lo haría Dio.
class _OfflineRemote implements FirestoreTrashRemote {
  @override
  Future<List<TrashEntry>> listEntries(String uid) async => throw _offline();

  @override
  Future<TrashEntry> createEntry({
    required String uid,
    required String groupId,
    required TrashItem item,
    required DateTime deletedAt,
  }) async =>
      throw _offline();

  @override
  Future<void> deleteEntry({required String uid, required String id}) async =>
      throw _offline();
}

DioException _offline() => DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    );

void main() {
  late FakeTrashRemote remote;
  late TrashRepositoryImpl repo;

  setUp(() {
    remote = FakeTrashRemote();
    repo = TrashRepositoryImpl(remote);
  });

  tearDown(() => repo.dispose());

  TrashItem item({
    String id = 't1',
    String? parentId,
    TrashKind kind = TrashKind.todo,
  }) =>
      TrashItem(
        kind: kind,
        itemId: id,
        parentId: parentId,
        label: 'Comprar $id',
        payload: {'id': id, 'title': 'Comprar $id'},
      );

  List<TrashEntry> valueOf(Result<List<TrashEntry>> res) =>
      res.fold(onOk: (entries) => entries, onErr: (f) => fail('Err: $f'));

  test('save guarda un documento por elemento y comparte grupo', () async {
    final res = await repo.save(uid: 'u1', items: [item(), item(id: 't2')]);

    expect(res.isOk, isTrue);
    expect(remote.entries, hasLength(2));
    expect(remote.entries.map((e) => e.groupId).toSet(), hasLength(1));
    expect(remote.entries.map((e) => e.itemId), containsAll(['t1', 't2']));
  });

  test('save sin elementos no escribe nada', () async {
    final res = await repo.save(uid: 'u1', items: const []);

    expect(res.isOk, isTrue);
    expect(remote.entries, isEmpty);
  });

  test('list devuelve lo último borrado primero', () async {
    await repo.save(uid: 'u1', items: [item(id: 't1')]);
    await repo.save(uid: 'u1', items: [item(id: 't2')]);

    final entries = valueOf(await repo.list('u1'));

    expect(entries.map((e) => e.itemId), ['t2', 't1']);
  });

  test('latestGroup devuelve el grupo más reciente del tipo y la lista',
      () async {
    await repo.save(uid: 'u1', items: [item(id: 't1', parentId: 'L1')]);
    await repo.save(
      uid: 'u1',
      items: [item(id: 'a1', kind: TrashKind.appointment)],
    );
    await repo.save(uid: 'u1', items: [item(id: 't2', parentId: 'L2')]);

    final todosOfL1 = valueOf(
      await repo.latestGroup(uid: 'u1', kind: TrashKind.todo, parentId: 'L1'),
    );
    expect(todosOfL1.map((e) => e.itemId), ['t1']);

    final appointments = valueOf(
      await repo.latestGroup(uid: 'u1', kind: TrashKind.appointment),
    );
    expect(appointments.map((e) => e.itemId), ['a1']);
  });

  test('latestGroup de una lista trae también sus tareas', () async {
    await repo.save(
      uid: 'u1',
      items: [
        item(id: 'L1', kind: TrashKind.list),
        item(id: 't1', parentId: 'L1'),
      ],
    );

    final group =
        valueOf(await repo.latestGroup(uid: 'u1', kind: TrashKind.list));

    expect(group.map((e) => e.itemId), containsAll(['L1', 't1']));
  });

  test('sin nada guardado no hay grupo que deshacer', () async {
    final group = valueOf(
      await repo.latestGroup(uid: 'u1', kind: TrashKind.todo),
    );

    expect(group, isEmpty);
  });

  test('remove borra solo los ids indicados', () async {
    await repo.save(uid: 'u1', items: [item(id: 't1')]);
    await repo.save(uid: 'u1', items: [item(id: 't2')]);
    final oldest = remote.entries.singleWhere((e) => e.itemId == 't1');

    final res = await repo.remove(uid: 'u1', ids: [oldest.id]);

    expect(res.isOk, isTrue);
    expect(remote.entries.map((e) => e.itemId), ['t2']);
  });

  test('empty deja la papelera vacía', () async {
    await repo.save(uid: 'u1', items: [item(id: 't1'), item(id: 't2')]);

    final res = await repo.empty('u1');

    expect(res.isOk, isTrue);
    expect(remote.entries, isEmpty);
  });

  test('save recorta lo que pasa del tope de la cuenta', () async {
    for (var i = 0; i <= TrashRepositoryImpl.maxEntriesPerUid; i++) {
      await repo.save(uid: 'u1', items: [item(id: 't$i')]);
    }

    expect(remote.entries, hasLength(TrashRepositoryImpl.maxEntriesPerUid));
    expect(remote.entries.map((e) => e.itemId), isNot(contains('t0')));
  });

  test('watch emite la papelera al suscribirse', () async {
    await repo.save(uid: 'u1', items: [item(id: 't1')]);

    final entries = await repo.watch('u1').first;

    expect(entries.map((e) => e.itemId), ['t1']);
  });

  test('si la red falla, list lo dice con NetworkFailure', () async {
    final offline = TrashRepositoryImpl(_OfflineRemote());

    final res = await offline.list('u1');

    expect(res.isErr, isTrue);
    expect(res.fold(onOk: (_) => null, onErr: (f) => f), isA<NetworkFailure>());
    offline.dispose();
  });

  test('save con la red caída devuelve Err', () async {
    final offline = TrashRepositoryImpl(_OfflineRemote());

    final res = await offline.save(uid: 'u1', items: [item()]);

    expect(res.isErr, isTrue);
    offline.dispose();
  });
}
