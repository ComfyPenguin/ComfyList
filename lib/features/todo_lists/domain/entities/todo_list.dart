import 'package:flutter/foundation.dart';

@immutable
class TodoList {
  const TodoList({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Clave simbólica del icono (ver [TodoListIcons]). Guardamos un string
  /// en Firestore en vez de un codePoint para evitar problemas de
  /// tree-shaking con iconos dinámicos.
  final String iconKey;

  final DateTime createdAt;
  final DateTime updatedAt;

  TodoList copyWith({
    String? id,
    String? name,
    String? iconKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoList(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
