import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AccountCacheDao.upsert + findByUid', () {
    test('hace round-trip de los campos insertados', () async {
      final dao = db.accountCacheDao;
      await dao.upsert(uid: 'u1', email: 'a@b.c', displayName: 'Ana');

      final row = await dao.findByUid('u1');
      expect(row, isNotNull);
      expect(row!.uid, 'u1');
      expect(row.email, 'a@b.c');
      expect(row.displayName, 'Ana');
      expect(
        row.cachedAt.difference(DateTime.now().toUtc()).inSeconds.abs() < 5,
        isTrue,
        reason: 'cachedAt debe estar dentro de los últimos segundos.',
      );
    });

    test('reemplaza una fila existente (insertOnConflictUpdate)', () async {
      final dao = db.accountCacheDao;
      await dao.upsert(uid: 'u1', email: 'a@b.c', displayName: 'Ana');
      await dao.upsert(uid: 'u1', email: 'nuevo@b.c', displayName: null);

      final row = await dao.findByUid('u1');
      expect(row, isNotNull);
      expect(row!.email, 'nuevo@b.c');
      expect(row.displayName, isNull);

      final count = await db.managers.accountCacheTable.count();
      expect(count, 1, reason: 'upsert no debe crear duplicados por uid.');
    });
  });

  group('AccountCacheDao.findByUid', () {
    test('devuelve null para un uid desconocido', () async {
      final dao = db.accountCacheDao;
      final row = await dao.findByUid('nope');
      expect(row, isNull);
    });
  });

  group('AccountCacheDao.deleteAll', () {
    test('vacía la tabla tras insertar varias filas', () async {
      final dao = db.accountCacheDao;
      await dao.upsert(uid: 'u1', email: 'a@b.c', displayName: null);
      await dao.upsert(uid: 'u2', email: 'b@b.c', displayName: null);

      await dao.deleteAll();

      expect(await dao.findByUid('u1'), isNull);
      expect(await dao.findByUid('u2'), isNull);
    });
  });
}
