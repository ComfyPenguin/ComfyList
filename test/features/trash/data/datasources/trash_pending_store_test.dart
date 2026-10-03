import 'package:comfy_list/features/trash/data/datasources/trash_pending_store.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTrashPendingStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftTrashPendingStore(db.trashPendingDao);
  });

  test('apunta, lee, poda y quita pendientes', () async {
    await store.add(uid: 'u1', docId: 'd1');
    await store.add(uid: 'u1', docId: 'd2');
    await store.add(uid: 'u2', docId: 'd3');

    expect(await store.idsOf('u1'), containsAll(['d1', 'd2']));
    expect(await store.idsOf('u2'), ['d3']);

    await store.keepOnly(uid: 'u1', ids: {'d1'});
    expect(await store.idsOf('u1'), ['d1']);
    expect(await store.idsOf('u2'), ['d3']);

    await store.remove(uid: 'u1', docId: 'd1');
    expect(await store.idsOf('u1'), isEmpty);

    await db.close();
  });

  test('si la base no responde, la restauración no se rompe', () async {
    await db.close();

    expect(await store.idsOf('u1'), isEmpty);
    await store.add(uid: 'u1', docId: 'd1');
    await store.remove(uid: 'u1', docId: 'd1');
    await store.keepOnly(uid: 'u1', ids: const {});
  });
}
