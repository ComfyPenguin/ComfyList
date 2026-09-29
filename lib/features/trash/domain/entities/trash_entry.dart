import 'package:flutter/foundation.dart';

/// Lo que se puede devolver desde la papelera.
enum TrashKind {
  list('list'),
  todo('todo'),
  appointment('appointment');

  const TrashKind(this.value);

  final String value;

  /// Un tipo desconocido (base escrita por otra versión) se trata como tarea:
  /// no rompe la pantalla y el peor caso es un error al restaurarlo.
  static TrashKind parse(String value) => values.firstWhere(
        (kind) => kind.value == value,
        orElse: () => TrashKind.todo,
      );
}

/// Un documento borrado, tal y como se guarda en la papelera.
@immutable
class TrashItem {
  const TrashItem({
    required this.kind,
    required this.itemId,
    required this.label,
    required this.payload,
    this.parentId,
  });

  final TrashKind kind;

  /// Id que el documento tenía en Firestore, para devolverlo con el mismo.
  final String itemId;

  /// Lista a la que pertenece una tarea; `null` en listas y citas.
  final String? parentId;

  /// Lo que enseña la papelera: nombre de la lista o título del elemento.
  final String label;

  /// Entidad serializada (ver `toJson` de cada entidad de dominio).
  final Map<String, dynamic> payload;
}

/// Una fila de la papelera, ya guardada en local.
@immutable
class TrashEntry {
  const TrashEntry({
    required this.rowId,
    required this.uid,
    required this.groupId,
    required this.item,
    required this.deletedAt,
  });

  /// Id de la fila en la base local.
  final int rowId;

  final String uid;

  /// Lo que se borró de una vez (una lista se lleva sus tareas) comparte grupo.
  final String groupId;

  final TrashItem item;

  final DateTime deletedAt;

  TrashKind get kind => item.kind;
  String get itemId => item.itemId;
  String? get parentId => item.parentId;
  String get label => item.label;
  Map<String, dynamic> get payload => item.payload;
}
