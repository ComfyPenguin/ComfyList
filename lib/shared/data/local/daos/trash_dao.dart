import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/trash_table.dart';

part 'trash_dao.g.dart';

@DriftAccessor(tables: [TrashTable])
class TrashDao extends DatabaseAccessor<AppDatabase> with _$TrashDaoMixin {
  TrashDao(super.db);

  /// Cuántos borrados se guardan por cuenta: más allá de esto solo hace bulto.
  static const int maxEntriesPerUid = 100;

  Future<void> insertAll(List<TrashTableCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAll(trashTable, rows));
    final uid = rows.first.uid.value;
    await _trim(uid);
  }

  /// Lo más reciente primero.
  Future<List<TrashRow>> listByUid(String uid) {
    return _sortedByRecency(
      select(trashTable)..where((t) => t.uid.equals(uid)),
    ).get();
  }

  Stream<List<TrashRow>> watchByUid(String uid) {
    return _sortedByRecency(
      select(trashTable)..where((t) => t.uid.equals(uid)),
    ).watch();
  }

  /// El grupo borrado más recientemente que encaje con [kind] (y con
  /// [parentId], para las tareas de una lista concreta), con todas sus filas.
  Future<List<TrashRow>> latestGroup({
    required String uid,
    required String kind,
    String? parentId,
  }) async {
    final newest = await _sortedByRecency(
      select(trashTable)
        ..where((t) {
          var predicate = t.uid.equals(uid) & t.kind.equals(kind);
          if (parentId != null) {
            predicate = predicate & t.parentId.equals(parentId);
          }
          return predicate;
        })
        ..limit(1),
    ).getSingleOrNull();
    if (newest == null) return const [];
    return rowsOfGroup(uid: uid, groupId: newest.groupId);
  }

  Future<List<TrashRow>> rowsOfGroup({
    required String uid,
    required String groupId,
  }) {
    return _sortedByRecency(
      select(trashTable)
        ..where((t) => t.uid.equals(uid) & t.groupId.equals(groupId)),
    ).get();
  }

  Future<void> deleteRows(List<int> ids) async {
    if (ids.isEmpty) return;
    await (delete(trashTable)..where((t) => t.id.isIn(ids))).go();
  }

  Future<void> deleteAllByUid(String uid) async {
    await (delete(trashTable)..where((t) => t.uid.equals(uid))).go();
  }

  /// Las dos consultas ordenan igual: lo último borrado, primero.
  SimpleSelectStatement<TrashTable, TrashRow> _sortedByRecency(
    SimpleSelectStatement<TrashTable, TrashRow> query,
  ) {
    return query
      ..orderBy([
        (t) => OrderingTerm.desc(t.deletedAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
  }

  Future<void> _trim(String uid) async {
    final excess = await listByUid(uid);
    if (excess.length <= maxEntriesPerUid) return;
    final ids = excess
        .skip(maxEntriesPerUid)
        .map((row) => row.id)
        .toList(growable: false);
    await deleteRows(ids);
  }
}
