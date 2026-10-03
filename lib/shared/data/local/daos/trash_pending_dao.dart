import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/trash_pending_table.dart';

part 'trash_pending_dao.g.dart';

@DriftAccessor(tables: [TrashPendingTable])
class TrashPendingDao extends DatabaseAccessor<AppDatabase>
    with _$TrashPendingDaoMixin {
  TrashPendingDao(super.db);

  Future<List<String>> idsOf(String uid) async {
    final rows =
        await (select(trashPendingTable)..where((t) => t.uid.equals(uid))).get();
    return [for (final row in rows) row.docId];
  }

  Future<void> add({required String uid, required String docId}) {
    return into(trashPendingTable).insertOnConflictUpdate(
      TrashPendingTableCompanion.insert(
        uid: uid,
        docId: docId,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> remove({required String uid, required String docId}) {
    return (delete(trashPendingTable)
          ..where((t) => t.uid.equals(uid) & t.docId.equals(docId)))
        .go();
  }

  /// Deja solo [ids] pendientes de ese uid: lo que ya no está en la papelera no
  /// hay que tirarlo.
  Future<void> keepOnly({required String uid, required Set<String> ids}) {
    final query = delete(trashPendingTable)..where((t) => t.uid.equals(uid));
    if (ids.isNotEmpty) query.where((t) => t.docId.isNotIn(ids));
    return query.go();
  }
}
