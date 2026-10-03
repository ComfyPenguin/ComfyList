import '../../../../shared/core/logging/debug_log.dart';
import '../../../../shared/data/local/daos/trash_pending_dao.dart';

/// Dónde se apuntan los borrados que quedaron sin quitar de la papelera (se
/// cayó la red justo después de restaurarlos). Viven en local para reintentarlos
/// aunque la app se cierre por medio.
///
/// Es best-effort: nada de aquí puede tumbar una restauración, así que las
/// implementaciones no lanzan — el peor caso es perder el reintento y que la
/// fila se quede hasta que el usuario la toque.
abstract class TrashPendingStore {
  /// Ids de los documentos de [uid] que siguen pendientes.
  Future<List<String>> idsOf(String uid);

  Future<void> add({required String uid, required String docId});

  Future<void> remove({required String uid, required String docId});

  /// Deja solo [ids] pendientes de [uid].
  Future<void> keepOnly({required String uid, required Set<String> ids});
}

/// Los pendientes en la base local.
class DriftTrashPendingStore implements TrashPendingStore {
  DriftTrashPendingStore(this._dao);

  final TrashPendingDao _dao;

  @override
  Future<List<String>> idsOf(String uid) => _reads(
        'leer los pendientes',
        () => _dao.idsOf(uid),
      );

  @override
  Future<void> add({required String uid, required String docId}) => _writes(
        'apuntar un pendiente',
        () => _dao.add(uid: uid, docId: docId),
      );

  @override
  Future<void> remove({required String uid, required String docId}) => _writes(
        'quitar un pendiente',
        () => _dao.remove(uid: uid, docId: docId),
      );

  @override
  Future<void> keepOnly({required String uid, required Set<String> ids}) =>
      _writes(
        'podar los pendientes',
        () => _dao.keepOnly(uid: uid, ids: ids),
      );

  Future<List<String>> _reads(
    String what,
    Future<List<String>> Function() read,
  ) async {
    try {
      return await read();
    } catch (e) {
      debugLog('La papelera no pudo $what: $e');
      return const [];
    }
  }

  Future<void> _writes(String what, Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugLog('La papelera no pudo $what: $e');
    }
  }
}
