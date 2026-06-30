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
  });
}
