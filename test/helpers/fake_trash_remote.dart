import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';

/// Papelera en memoria: imita a [FirestoreTrashRemote] sin red. Los ids son
/// sintéticos (`doc0`, `doc1`...) porque en Firestore los pone el servidor.
class FakeTrashRemote implements FirestoreTrashRemote {
  final Map<String, TrashEntry> _entries = {};
  int _nextId = 0;

  /// Lo que hay guardado, para aserciones directas.
  List<TrashEntry> get entries => _entries.values.toList(growable: false);

  @override
  Future<List<TrashEntry>> listEntries(String uid) async => entries;

  @override
  Future<void> createEntries({
    required String uid,
    required String groupId,
    required List<TrashItem> items,
    required DateTime deletedAt,
  }) async {
    for (final item in items) {
      final entry = TrashEntry(
        id: 'doc${_nextId++}',
        uid: uid,
        groupId: groupId,
        item: item,
        deletedAt: deletedAt,
      );
      _entries[entry.id] = entry;
    }
  }

  @override
  Future<void> deleteEntries({
    required String uid,
    required List<String> ids,
  }) async {
    ids.forEach(_entries.remove);
  }
}
