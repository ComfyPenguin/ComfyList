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

    group('toJson / fromJson', () {
      // Fechas locales, como las que devuelve el códec de Firestore.
      final local = DateTime(2026, 6, 1, 9);
      final entity = Todo(
          id: 't1',
          title: 'Comprar pan',
          isDone: false,
          createdAt: local,
          updatedAt: local,
        );

      test('guarda un instante absoluto aunque la fecha sea local', () {
        final json = entity.toJson();

        expect(json['createdAt'], endsWith('Z'));
        expect(json['updatedAt'], endsWith('Z'));
      });

      test('vuelve a leerse como el mismo instante, en hora local', () {
        final back = Todo.fromJson(entity.toJson());

        expect(back.createdAt, local);
        expect(back.createdAt.isUtc, isFalse);
        expect(back.updatedAt, local);
      });

      test('lo escrito desde otra zona horaria cae en el mismo instante', () {
        final json = entity.toJson()..['createdAt'] = '2026-06-01T07:00:00.000Z';

        final back = Todo.fromJson(json);

        expect(
          back.createdAt.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 7)),
          isTrue,
        );
      });

      test('un payload antiguo, sin zona, se lee como hora local', () {
        final json = entity.toJson()
          ..['createdAt'] = '2026-06-01T09:00:00.000'
          ..['updatedAt'] = '2026-06-01T09:00:00.000';

        final back = Todo.fromJson(json);

        expect(back.createdAt, DateTime(2026, 6, 1, 9));
      });
    });
  });
}
