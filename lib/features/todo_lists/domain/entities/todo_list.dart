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

  /// Serialización para guardarla en local (papelera).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TodoList.fromJson(Map<String, dynamic> json) => TodoList(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

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
