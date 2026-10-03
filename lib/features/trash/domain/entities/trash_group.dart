import 'package:flutter/foundation.dart';

import 'trash_entry.dart';

/// Un borrado entero: la lista con lo que se llevó dentro, o el elemento suelto.
///
/// La papelera guarda un documento por elemento, así que lo que se borró de una
/// vez se vuelve a juntar aquí para enseñarlo —y devolverlo— como una sola cosa.
/// A una lista se le cuelgan además las tareas que se hubieran borrado antes
/// que ella: solas no pueden volver, así que son parte del mismo borrado aunque
/// se hicieran en dos veces.
@immutable
class TrashGroup {
  const TrashGroup._({required this.header, required this.entries});

  /// Lo que representa el borrado: la lista si la lleva, si no el elemento
  /// suelto.
  final TrashEntry header;

  /// Todo lo que se borró junto, con [header] delante: la lista va antes que
  /// sus tareas, que cuelgan de ella.
  final List<TrashEntry> entries;

  TrashKind get kind => header.kind;
  String get groupId => header.groupId;
  DateTime get deletedAt => header.deletedAt;

  /// Lo que se llevó por dentro: las tareas de una lista, las de su cascada y
  /// las que ya estaban en la papelera y cuelgan de ella.
  List<TrashEntry> get contents => entries.skip(1).toList(growable: false);

  /// Reparte [entries] —lo último borrado primero— en sus borrados, cada uno
  /// con la cabecera delante.
  static List<TrashGroup> partition(List<TrashEntry> entries) {
    final byGroup = <String, List<TrashEntry>>{};
    for (final entry in entries) {
      byGroup.putIfAbsent(entry.groupId, () => []).add(entry);
    }

    final borrados = [for (final group in byGroup.values) TrashGroup._of(group)];

    // Una tarea borrada antes que su lista no vuelve sola: se escribiría bajo
    // una lista que no está y se quedaría invisible. Va con la lista, y al
    // volver la lista vuelve todo lo que tenía dentro.
    final lists = {
      for (final borrado in borrados)
        if (borrado.kind == TrashKind.list) borrado.header.itemId: borrado,
    };
    if (lists.isEmpty) return borrados;

    final absorbidos = <String>{};
    final colgando = <String, List<TrashEntry>>{};
    for (final borrado in borrados) {
      final parentId = borrado.header.parentId;
      if (borrado.kind == TrashKind.list || parentId == null) continue;
      if (!lists.containsKey(parentId)) continue;

      absorbidos.add(borrado.groupId);
      colgando.putIfAbsent(parentId, () => []).addAll(borrado.entries);
    }
    if (absorbidos.isEmpty) return borrados;

    final groups = <TrashGroup>[];
    for (final borrado in borrados) {
      if (absorbidos.contains(borrado.groupId)) continue;

      final extra = colgando[borrado.header.itemId];
      groups.add(
        extra == null
            ? borrado
            : TrashGroup._(
                header: borrado.header,
                entries: [...borrado.entries, ...extra],
              ),
      );
    }
    return groups;
  }

  static TrashGroup _of(List<TrashEntry> group) {
    final at = group.indexWhere((entry) => entry.kind == TrashKind.list);
    final headerIndex = at < 0 ? 0 : at;
    final header = group[headerIndex];

    return TrashGroup._(
      header: header,
      entries: [
        header,
        for (final (index, entry) in group.indexed)
          if (index != headerIndex) entry,
      ],
    );
  }
}
