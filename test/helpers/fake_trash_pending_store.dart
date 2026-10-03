import 'package:comfy_list/features/trash/data/datasources/trash_pending_store.dart';

/// Pendientes en memoria: imita a [TrashPendingStore] sin tocar disco. Vale
/// también para simular un reinicio: dos repositorios con el mismo fake
/// comparten lo apuntado.
class FakeTrashPendingStore implements TrashPendingStore {
  final Map<String, Set<String>> _pending = {};

  @override
  Future<List<String>> idsOf(String uid) async => [...?_pending[uid]];

  @override
  Future<void> add({required String uid, required String docId}) async {
    (_pending[uid] ??= {}).add(docId);
  }

  @override
  Future<void> remove({required String uid, required String docId}) async {
    _pending[uid]?.remove(docId);
  }

  @override
  Future<void> keepOnly({required String uid, required Set<String> ids}) async {
    _pending[uid]?.removeWhere((id) => !ids.contains(id));
  }
}
