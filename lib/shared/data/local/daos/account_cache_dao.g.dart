// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$AccountCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountCacheTableTable get accountCacheTable =>
      attachedDatabase.accountCacheTable;
  AccountCacheDaoManager get managers => AccountCacheDaoManager(this);
}

class AccountCacheDaoManager {
  final _$AccountCacheDaoMixin _db;
  AccountCacheDaoManager(this._db);
  $$AccountCacheTableTableTableManager get accountCacheTable =>
      $$AccountCacheTableTableTableManager(
        _db.attachedDatabase,
        _db.accountCacheTable,
      );
}
