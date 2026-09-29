import '../../../../shared/core/result/result.dart';
import '../entities/trash_entry.dart';

/// Contrato de la papelera — la implementación vive en `data/`. Guarda en
/// Firestore (`users/{uid}/trash`), así que todo puede fallar por red.
abstract class TrashRepository {
  /// Guarda un borrado: un documento por elemento, todos con el mismo grupo.
  Future<Result<void>> save({required String uid, required List<TrashItem> items});

  /// El grupo borrado más recientemente de ese tipo (y de esa lista, si es una
  /// tarea), con todas sus filas. Vacío si no queda nada que deshacer.
  Future<Result<List<TrashEntry>>> latestGroup({
    required String uid,
    required TrashKind kind,
    String? parentId,
  });

  /// Toda la papelera de la cuenta, lo último borrado primero.
  Future<Result<List<TrashEntry>>> list(String uid);

  Stream<List<TrashEntry>> watch(String uid);

  Future<Result<void>> remove({
    required String uid,
    required List<String> ids,
  });

  Future<Result<void>> empty(String uid);

  /// Vacía sola lo que lleve más de [days] días en la papelera. `days <= 0` es
  /// «nunca»: no toca nada.
  Future<Result<void>> purgeExpired({required String uid, required int days});

  /// Pausa y reanuda el polling del watcher activo (ciclo de vida de la app).
  void pauseAll();
  void resumeAll();
}
