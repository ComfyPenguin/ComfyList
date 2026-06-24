import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/account_cache_table.dart';

part 'account_cache_dao.g.dart';

@DriftAccessor(tables: [AccountCacheTable])
class AccountCacheDao extends DatabaseAccessor<AppDatabase>
    with _$AccountCacheDaoMixin {
  AccountCacheDao(super.db);

  Future<AccountCacheRow?> findByUid(String uid) {
    return (select(accountCacheTable)..where((t) => t.uid.equals(uid)))
        .getSingleOrNull();
  }

  Future<void> upsert({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    await into(accountCacheTable).insertOnConflictUpdate(
      AccountCacheTableCompanion.insert(
        uid: uid,
        email: email,
        displayName: Value(displayName),
        cachedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> deleteAll() async {
    await delete(accountCacheTable).go();
  }
}
