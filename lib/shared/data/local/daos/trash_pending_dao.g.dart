// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_pending_dao.dart';

// ignore_for_file: type=lint
mixin _$TrashPendingDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrashPendingTableTable get trashPendingTable =>
      attachedDatabase.trashPendingTable;
  TrashPendingDaoManager get managers => TrashPendingDaoManager(this);
}

class TrashPendingDaoManager {
  final _$TrashPendingDaoMixin _db;
  TrashPendingDaoManager(this._db);
  $$TrashPendingTableTableTableManager get trashPendingTable =>
      $$TrashPendingTableTableTableManager(
        _db.attachedDatabase,
        _db.trashPendingTable,
      );
}
