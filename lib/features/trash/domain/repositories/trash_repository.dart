import '../entities/trash_entry.dart';

/// Contrato de la papelera — la implementación vive en `data/`.
abstract class TrashRepository {
  /// Guarda un borrado: una fila por documento, todas con el mismo grupo.
  Future<void> save({required String uid, required List<TrashItem> items});

  /// El grupo borrado más recientemente de ese tipo (y de esa lista, si es una
  /// tarea), con todas sus filas. Vacío si no queda nada que deshacer.
  Future<List<TrashEntry>> latestGroup({
    required String uid,
    required TrashKind kind,
    String? parentId,
  });

  /// Toda la papelera de la cuenta, lo último borrado primero.
  Future<List<TrashEntry>> list(String uid);

  Stream<List<TrashEntry>> watch(String uid);

  Future<void> remove(List<int> rowIds);

  Future<void> empty(String uid);
}
