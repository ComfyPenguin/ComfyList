import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Todo', () {
    test('copyWith with description sets the new value', () {
      final original = Todo(
        id: 't1',
        title: 'Comprar pan',
        description: 'old',
        isDone: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final updated = original.copyWith(description: 'new');

      expect(updated.description, 'new');
      expect(updated.id, 't1');
      expect(updated.title, 'Comprar pan');
    });

    test('copyWith with clearDescription:true sets null', () {
      final original = Todo(
        id: 't1',
        title: 'Comprar pan',
        description: 'old',
        isDone: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final updated = original.copyWith(clearDescription: true);

      expect(updated.description, isNull);
      expect(updated.id, 't1');
      expect(updated.title, 'Comprar pan');
      expect(updated.isDone, isFalse);
    });

    test('copyWith without description or clearDescription keeps the original',
        () {
      final original = Todo(
        id: 't1',
        title: 'Comprar pan',
        description: 'old',
        isDone: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final updated = original.copyWith(title: 'Comprar leche');

      expect(updated.description, 'old');
      expect(updated.title, 'Comprar leche');
    });

    test('copyWith with isDone toggles only isDone', () {
      final original = Todo(
        id: 't1',
        title: 'Comprar pan',
        isDone: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final updated = original.copyWith(isDone: true);

      expect(updated.isDone, isTrue);
      expect(updated.title, 'Comprar pan');
      expect(updated.id, 't1');
    });
  });
}
