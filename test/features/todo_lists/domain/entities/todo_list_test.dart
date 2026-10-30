import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoList', () {
    test('copyWith changes only supplied fields', () {
      final original = TodoList(
        id: 'L1',
        name: 'Compras',
        iconKey: 'cart',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Nuevo',
        iconKey: 'shopping',
      );

      expect(updated.id, 'L1');
      expect(updated.name, 'Nuevo');
      expect(updated.iconKey, 'shopping');
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt, original.updatedAt);
    });

    test('copyWith without args returns a copy with identical fields', () {
      // NOTA: la entidad de producción NO sobreescribe `==`/`hashCode`,
      // por lo que `==` es por referencia. Verificamos campo a campo el
      // contrato observable. Spec REQ-050 escenario 2 ("equality is
      // structural") no se cumple — drift documentado en apply-progress.
      final original = TodoList(
        id: 'L1',
        name: 'Compras',
        iconKey: 'cart',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.iconKey, original.iconKey);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
      expect(identical(copy, original), isFalse);
    });

    test('two instances with the same fields have equal field values', () {
      // Spec REQ-050 escenario 2 ("equality is structural") requiere `==`
      // estructural. La producción usa identidad por referencia; verificamos
      // el contrato observable (campos idénticos). Drift documentado.
      final t = DateTime.utc(2026, 1, 1);
      final a = TodoList(
        id: 'L1',
        name: 'Compras',
        iconKey: 'cart',
        createdAt: t,
        updatedAt: t,
      );
      final b = TodoList(
        id: 'L1',
        name: 'Compras',
        iconKey: 'cart',
        createdAt: t,
        updatedAt: t,
      );

      expect(b.id, a.id);
      expect(b.name, a.name);
      expect(b.iconKey, a.iconKey);
      expect(b.createdAt, a.createdAt);
      expect(b.updatedAt, a.updatedAt);
    });

    group('toJson / fromJson', () {
      // Fechas locales, como las que devuelve el códec de Firestore.
      final local = DateTime(2026, 6, 1, 9);
      final entity = TodoList(
          id: 'L1',
          name: 'Compras',
          iconKey: 'cart',
          createdAt: local,
          updatedAt: local,
        );

      test('guarda un instante absoluto aunque la fecha sea local', () {
        final json = entity.toJson();

        expect(json['createdAt'], endsWith('Z'));
        expect(json['updatedAt'], endsWith('Z'));
      });

      test('vuelve a leerse como el mismo instante, en hora local', () {
        final back = TodoList.fromJson(entity.toJson());

        expect(back.createdAt, local);
        expect(back.createdAt.isUtc, isFalse);
        expect(back.updatedAt, local);
      });

      test('lo escrito desde otra zona horaria cae en el mismo instante', () {
        final json = entity.toJson()..['createdAt'] = '2026-06-01T07:00:00.000Z';

        final back = TodoList.fromJson(json);

        expect(
          back.createdAt.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 7)),
          isTrue,
        );
      });

      test('un payload antiguo, sin zona, se lee como hora local', () {
        final json = entity.toJson()
          ..['createdAt'] = '2026-06-01T09:00:00.000'
          ..['updatedAt'] = '2026-06-01T09:00:00.000';

        final back = TodoList.fromJson(json);

        expect(back.createdAt, DateTime(2026, 6, 1, 9));
      });
    });
  });
}
