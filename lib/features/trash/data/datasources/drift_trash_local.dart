import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../shared/data/local/app_database.dart';
import '../../../../shared/data/local/daos/trash_dao.dart';
import '../../domain/entities/trash_entry.dart';

/// Adaptador sobre [TrashDao]. Mantiene la dependencia con Drift confinada a
/// `data/datasources/`.
class DriftTrashLocal {
  DriftTrashLocal(this._dao);

  final TrashDao _dao;

  Future<void> insert({
    required String uid,
    required String groupId,
    required List<TrashItem> items,
    required DateTime deletedAt,
  }) {
    return _dao.insertAll([
      for (final item in items)
        TrashTableCompanion.insert(
          uid: uid,
          groupId: groupId,
          kind: item.kind.value,
          itemId: item.itemId,
          parentId: Value(item.parentId),
          label: item.label,
          payload: jsonEncode(item.payload),
          deletedAt: deletedAt,
        ),
    ]);
  }

  Future<List<TrashEntry>> listByUid(String uid) async {
    final rows = await _dao.listByUid(uid);
    return rows.map(_toEntry).toList(growable: false);
  }

  Stream<List<TrashEntry>> watchByUid(String uid) {
    return _dao
        .watchByUid(uid)
        .map((rows) => rows.map(_toEntry).toList(growable: false));
  }

  Future<List<TrashEntry>> latestGroup({
    required String uid,
    required String kind,
    String? parentId,
  }) async {
    final rows = await _dao.latestGroup(
      uid: uid,
      kind: kind,
      parentId: parentId,
    );
    return rows.map(_toEntry).toList(growable: false);
  }

  Future<void> deleteRows(List<int> rowIds) => _dao.deleteRows(rowIds);

  Future<void> deleteAllByUid(String uid) => _dao.deleteAllByUid(uid);

  TrashEntry _toEntry(TrashRow row) => TrashEntry(
        rowId: row.id,
        uid: row.uid,
        groupId: row.groupId,
        deletedAt: row.deletedAt,
        item: TrashItem(
          kind: TrashKind.parse(row.kind),
          itemId: row.itemId,
          parentId: row.parentId,
          label: row.label,
          payload: jsonDecode(row.payload) as Map<String, dynamic>,
        ),
      );
}
