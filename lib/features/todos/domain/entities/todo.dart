import 'package:flutter/foundation.dart';

@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
