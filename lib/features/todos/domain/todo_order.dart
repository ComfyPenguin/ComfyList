import 'entities/todo.dart';

/// Orden en que se enseñan las tareas de una lista.
///
/// - Con [completedToBottom]: las pendientes primero, por fecha de
///   actualización ascendente (lo recién desmarcado cae al final de las
///   pendientes, junto a las completadas); las completadas después, por fecha
///   de actualización descendente.
/// - Sin él: por fecha de creación ascendente, de modo que cada tarea mantiene
///   su posición al completarla.
List<Todo> sortTodos(
  Iterable<Todo> todos, {
  required bool completedToBottom,
}) =>
    [...todos]..sort((a, b) {
        if (completedToBottom) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          if (a.isDone) return b.updatedAt.compareTo(a.updatedAt);
          return a.updatedAt.compareTo(b.updatedAt);
        }
        return a.createdAt.compareTo(b.createdAt);
      });
