import 'package:comfy_list/features/trash/data/datasources/drift_trash_local.dart';
import 'package:comfy_list/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:comfy_list/shared/data/local/daos/trash_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TrashRepositoryImpl trash;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    trash = TrashRepositoryImpl(DriftTrashLocal(db.trashDao));
  });

  tearDown(() => db.close());

  TrashItem item({
    TrashKind kind = TrashKind.todo,
    String id = 't1',
    String label = 'Comprar pan',
    String? parentId = 'L1',
  }) {
    return TrashItem(
      kind: kind,
      itemId: id,
      parentId: parentId,
      label: label,
      payload: {'id': id, 'label': label},
    );
  }

  TrashItem list({String id = 'L1', String name = 'Compras'}) => TrashItem(
        kind: TrashKind.list,
        itemId: id,
        label: name,
        payload: {'id': id, 'name': name},
      );

  test('guarda el borrado y lo devuelve con su payload', () async {
    await trash.save(uid: 'u1', items: [list()]);

    final entries = await trash.list('u1');
    final entry = entries.single;
    expect(entry.kind, TrashKind.list);
    expect(entry.itemId, 'L1');
    expect(entry.label, 'Compras');
    expect(entry.parentId, isNull);
    expect(entry.payload, {'id': 'L1', 'name': 'Compras'});
    expect(
      entry.deletedAt.difference(DateTime.now().toUtc()).inSeconds.abs() < 5,
      isTrue,
      reason: 'deletedAt debe estar dentro de los últimos segundos.',
    );
  });

  test('lo último borrado va primero', () async {
    await trash.save(uid: 'u1', items: [item(id: 't1')]);
    await trash.save(uid: 'u1', items: [item(id: 't2')]);

    final entries = await trash.list('u1');
    expect(entries.map((entry) => entry.itemId), ['t2', 't1']);
  });

  test('no mezcla las papeleras de dos cuentas', () async {
    await trash.save(uid: 'u1', items: [item(id: 't1')]);
    await trash.save(uid: 'u2', items: [item(id: 't2')]);

    expect((await trash.list('u1')).map((e) => e.itemId), ['t1']);
    expect((await trash.list('u2')).map((e) => e.itemId), ['t2']);
  });

  test('latestGroup devuelve el grupo entero de un borrado con sus tareas',
      () async {
    await trash.save(uid: 'u1', items: [list(), item(id: 't1'), item(id: 't2')]);

    final group = await trash.latestGroup(uid: 'u1', kind: TrashKind.list);

    expect(group, hasLength(3));
    expect(group.map((entry) => entry.itemId), containsAll(['L1', 't1', 't2']));
  });

  test('latestGroup solo mira las tareas de la lista que se le pide', () async {
    await trash.save(uid: 'u1', items: [item(id: 't1', parentId: 'L1')]);
    await trash.save(uid: 'u1', items: [item(id: 't2', parentId: 'L2')]);

    final group = await trash.latestGroup(
      uid: 'u1',
      kind: TrashKind.todo,
      parentId: 'L1',
    );

    expect(group.map((entry) => entry.itemId), ['t1']);
  });

  test('latestGroup vacío cuando no queda nada de ese tipo', () async {
    await trash.save(uid: 'u1', items: [item()]);

    expect(
      await trash.latestGroup(uid: 'u1', kind: TrashKind.appointment),
      isEmpty,
    );
  });

  test('remove saca solo las filas que se le pasan', () async {
    await trash.save(uid: 'u1', items: [item(id: 't1'), item(id: 't2')]);

    final entries = await trash.list('u1');
    await trash.remove([entries.first.rowId]);

    expect((await trash.list('u1')).map((e) => e.itemId), ['t1']);
  });

  test('empty vacía la papelera de la cuenta', () async {
    await trash.save(uid: 'u1', items: [item(id: 't1')]);
    await trash.save(uid: 'u2', items: [item(id: 't2')]);

    await trash.empty('u1');

    expect(await trash.list('u1'), isEmpty);
    expect(await trash.list('u2'), hasLength(1));
  });

  test('watch emite la papelera cada vez que cambia', () async {
    final emissions = <List<TrashEntry>>[];
    final sub = trash.watch('u1').listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await trash.save(uid: 'u1', items: [item(id: 't1')]);
    await pumpEventQueue();

    expect(emissions.last.map((entry) => entry.itemId), ['t1']);
  });

  test('solo guarda los últimos borrados de la cuenta', () async {
    final items = [
      for (var i = 0; i < TrashDao.maxEntriesPerUid + 1; i++) item(id: 't$i'),
    ];
    await trash.save(uid: 'u1', items: items);

    final entries = await trash.list('u1');
    expect(entries, hasLength(TrashDao.maxEntriesPerUid));
    expect(entries.map((entry) => entry.itemId), isNot(contains('t0')));
  });
}
