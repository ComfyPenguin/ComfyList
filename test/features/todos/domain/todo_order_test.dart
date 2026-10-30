import 'package:comfy_list/features/todos/domain/todo_order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  DateTime at(int day) => DateTime.utc(2026, 6, day);

  group('sortTodos con las completadas al final', () {
    test('las pendientes van primero, por actualización ascendente', () {
      final sorted = sortTodos([
        buildTodo(id: 'tarde', updatedAt: at(5)),
        buildTodo(id: 'pronto', updatedAt: at(2)),
      ], completedToBottom: true);

      expect(sorted.map((t) => t.id), ['pronto', 'tarde']);
    });

    test('las completadas van después, por actualización descendente', () {
      final sorted = sortTodos([
        buildTodo(id: 'hecha-vieja', isDone: true, updatedAt: at(1)),
        buildTodo(id: 'pendiente', updatedAt: at(9)),
        buildTodo(id: 'hecha-nueva', isDone: true, updatedAt: at(8)),
      ], completedToBottom: true);

      expect(sorted.map((t) => t.id), [
        'pendiente',
        'hecha-nueva',
        'hecha-vieja',
      ]);
    });

    test('lo recién desmarcado cae al final de las pendientes', () {
      final sorted = sortTodos([
        buildTodo(id: 'recien-desmarcada', updatedAt: at(9)),
        buildTodo(id: 'antigua', updatedAt: at(1)),
      ], completedToBottom: true);

      expect(sorted.last.id, 'recien-desmarcada');
    });
  });

  group('sortTodos sin las completadas al final', () {
    test('van por creación ascendente, hechas o no', () {
      final sorted = sortTodos([
        buildTodo(id: 'b', isDone: true, createdAt: at(3)),
        buildTodo(id: 'c', createdAt: at(5)),
        buildTodo(id: 'a', createdAt: at(1), updatedAt: at(9)),
      ], completedToBottom: false);

      expect(sorted.map((t) => t.id), ['a', 'b', 'c']);
    });
  });

  test('sortTodos no modifica la lista que recibe', () {
    final input = [
      buildTodo(id: 'b', createdAt: at(2)),
      buildTodo(id: 'a', createdAt: at(1)),
    ];

    sortTodos(input, completedToBottom: false);

    expect(input.map((t) => t.id), ['b', 'a']);
  });
}
