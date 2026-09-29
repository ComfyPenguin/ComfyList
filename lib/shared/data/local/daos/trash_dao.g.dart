// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_dao.dart';

// ignore_for_file: type=lint
mixin _$TrashDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrashTableTable get trashTable => attachedDatabase.trashTable;
  TrashDaoManager get managers => TrashDaoManager(this);
}

class TrashDaoManager {
  final _$TrashDaoMixin _db;
  TrashDaoManager(this._db);
  $$TrashTableTableTableManager get trashTable =>
      $$TrashTableTableTableManager(_db.attachedDatabase, _db.trashTable);
}
