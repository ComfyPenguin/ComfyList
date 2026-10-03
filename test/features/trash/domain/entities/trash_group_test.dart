import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TrashEntry entry({
    required TrashKind kind,
    String group = 'g1',
    String id = 'e1',
    String label = 'algo',
    String? parentId,
  }) {
    return TrashEntry(
      id: id,
      uid: 'u1',
      groupId: group,
      deletedAt: DateTime.utc(2026, 6, 1, 9),
      item: TrashItem(
        kind: kind,
        itemId: id,
        parentId: parentId,
        label: label,
        payload: const {},
      ),
    );
  }

  test('cada borrado es un grupo, en el orden en que llegan', () {
    final groups = TrashGroup.partition([
      entry(kind: TrashKind.todo, group: 'g2', id: 'nuevo'),
      entry(kind: TrashKind.todo, group: 'g1', id: 'viejo'),
    ]);

    expect(groups.map((group) => group.groupId), ['g2', 'g1']);
    expect(groups.first.header.label, 'algo');
  });

  test('la lista manda y sus tareas van detrás', () {
    // Las tareas llegan antes que su lista: el grupo las coloca.
    final groups = TrashGroup.partition([
      entry(kind: TrashKind.todo, id: 't1', label: 'Pan'),
      entry(kind: TrashKind.list, id: 'L1', label: 'Compras'),
      entry(kind: TrashKind.todo, id: 't2', label: 'Leche'),
    ]);

    final group = groups.single;
    expect(group.kind, TrashKind.list);
    expect(group.header.label, 'Compras');
    expect(group.entries.map((entry) => entry.itemId), ['L1', 't1', 't2']);
    expect(group.contents.map((entry) => entry.label), ['Pan', 'Leche']);
  });

  test('una tarea borrada antes que su lista viaja con ella', () {
    // Dos borrados: la tarea primero y la lista después. Restaurada sola, la
    // tarea se escribiría bajo una lista que no está y no volvería.
    final groups = TrashGroup.partition([
      entry(kind: TrashKind.todo, group: 'g2', id: 't1', label: 'Pan', parentId: 'L1'),
      entry(kind: TrashKind.list, group: 'g1', id: 'L1', label: 'Compras'),
      entry(kind: TrashKind.todo, group: 'g1', id: 't2', label: 'Leche', parentId: 'L1'),
    ]);

    final group = groups.single;
    expect(group.header.label, 'Compras');
    expect(group.contents.map((entry) => entry.label), ['Leche', 'Pan']);
  });

  test('una tarea cuya lista no está en la papelera sale por su cuenta', () {
    final groups = TrashGroup.partition([
      entry(kind: TrashKind.todo, id: 't1', label: 'Pan', parentId: 'L1'),
    ]);

    expect(groups.single.kind, TrashKind.todo);
    expect(groups.single.contents, isEmpty);
  });

  test('una tarea de otra lista no se cuelga de esta', () {
    final groups = TrashGroup.partition([
      entry(kind: TrashKind.todo, group: 'g2', id: 't1', label: 'Pan', parentId: 'L2'),
      entry(kind: TrashKind.list, group: 'g1', id: 'L1', label: 'Compras'),
    ]);

    expect(groups, hasLength(2));
  });

  test('un elemento suelto es un grupo sin nada dentro', () {
    final groups = TrashGroup.partition([entry(kind: TrashKind.todo)]);

    expect(groups.single.contents, isEmpty);
  });

  test('sin nada borrado no hay grupos', () {
    expect(TrashGroup.partition(const []), isEmpty);
  });
}
