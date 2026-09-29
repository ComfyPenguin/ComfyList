import '../../domain/entities/trash_entry.dart';
import '../../domain/repositories/trash_repository.dart';
import '../datasources/drift_trash_local.dart';

class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._local);

  final DriftTrashLocal _local;

  @override
  Future<void> save({required String uid, required List<TrashItem> items}) {
    if (items.isEmpty) return Future.value();
    return _local.insert(
      uid: uid,
      groupId: _newGroupId(),
      items: items,
      deletedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<TrashEntry>> latestGroup({
    required String uid,
    required TrashKind kind,
    String? parentId,
  }) {
    return _local.latestGroup(
      uid: uid,
      kind: kind.value,
      parentId: parentId,
    );
  }

  @override
  Future<List<TrashEntry>> list(String uid) => _local.listByUid(uid);

  @override
  Stream<List<TrashEntry>> watch(String uid) => _local.watchByUid(uid);

  @override
  Future<void> remove(List<int> rowIds) => _local.deleteRows(rowIds);

  @override
  Future<void> empty(String uid) => _local.deleteAllByUid(uid);

  /// Dos borrados seguidos no caen en el mismo microsegundo, así que el reloj
  /// basta como identificador de grupo.
  String _newGroupId() => DateTime.now().toUtc().microsecondsSinceEpoch.toString();
}
