import 'package:comfy_list/shared/ui/lists/held_reorder.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  const _Item(this.id, {this.done = false});

  final String id;
  final bool done;
}

void main() {
  late int releases;
  late HeldReorder<_Item> held;

  /// Pendientes primero, como `completedToBottom`.
  List<_Item> pendingFirst(List<_Item> items) =>
      [...items]..sort((a, b) => a.done == b.done ? 0 : (a.done ? 1 : -1));

  List<String> ids(List<_Item> items) => [for (final i in items) i.id];

  List<_Item> resolve(List<_Item> items) =>
      held.resolve(items: items, desired: pendingFirst(items));

  setUp(() {
    releases = 0;
    held = HeldReorder<_Item>(
      idOf: (item) => item.id,
      flagOf: (item) => item.done,
      onRelease: () => releases++,
    );
  });

  tearDown(() => held.dispose());

  testWidgets('la primera vez devuelve el orden deseado', (tester) async {
    final result = resolve(const [_Item('a'), _Item('b', done: true)]);

    expect(ids(result), ['a', 'b']);
  });

  testWidgets('retiene el orden anterior al completar un elemento',
      (tester) async {
    resolve(const [_Item('a'), _Item('b'), _Item('c')]);

    final result = resolve(const [_Item('a', done: true), _Item('b'), _Item('c')]);

    // `a` iría al final, pero se queda donde estaba mientras se anima.
    expect(ids(result), ['a', 'b', 'c']);
    expect(releases, 0);
    // El test no puede acabar con el temporizador de la retención pendiente.
    held.dispose();
  });

  testWidgets('pasado el retardo avisa y el siguiente build reordena',
      (tester) async {
    resolve(const [_Item('a'), _Item('b'), _Item('c')]);
    const toggled = [_Item('a', done: true), _Item('b'), _Item('c')];
    resolve(toggled);

    await tester.pump(const Duration(milliseconds: 600));

    expect(releases, 1);
    expect(ids(resolve(toggled)), ['b', 'c', 'a']);
  });

  testWidgets('sigue retenido hasta que pasa el retardo', (tester) async {
    resolve(const [_Item('a'), _Item('b')]);
    const toggled = [_Item('a', done: true), _Item('b')];
    resolve(toggled);

    await tester.pump(const Duration(milliseconds: 300));

    expect(releases, 0);
    expect(ids(resolve(toggled)), ['a', 'b']);
    held.dispose();
  });

  testWidgets('si el cambio no reordena, no retiene', (tester) async {
    resolve(const [_Item('a'), _Item('b', done: true)]);

    // Desmarcar `b`, que ya iba al final, deja el mismo orden: nada que retener.
    final result = resolve(const [_Item('a'), _Item('b')]);
    await tester.pump(const Duration(seconds: 1));

    expect(ids(result), ['a', 'b']);
    expect(releases, 0);
  });

  testWidgets('dos cambios a la vez no retienen', (tester) async {
    resolve(const [_Item('a'), _Item('b'), _Item('c')]);

    final result = resolve(
      const [_Item('a', done: true), _Item('b', done: true), _Item('c')],
    );

    expect(ids(result), ['c', 'a', 'b']);
    expect(releases, 0);
  });

  testWidgets('una alta durante la retención reordena en el acto',
      (tester) async {
    resolve(const [_Item('a'), _Item('b')]);
    resolve(const [_Item('a', done: true), _Item('b')]);

    final result = resolve(
      const [_Item('a', done: true), _Item('b'), _Item('nueva')],
    );

    expect(ids(result), ['b', 'nueva', 'a']);
    await tester.pump(const Duration(seconds: 1));
    expect(releases, 0);
  });

  testWidgets('una baja durante la retención reordena en el acto',
      (tester) async {
    resolve(const [_Item('a'), _Item('b'), _Item('c')]);
    resolve(const [_Item('a', done: true), _Item('b'), _Item('c')]);

    final result = resolve(const [_Item('a', done: true), _Item('c')]);

    expect(ids(result), ['c', 'a']);
  });

  testWidgets('dispose cancela el aviso pendiente', (tester) async {
    resolve(const [_Item('a'), _Item('b')]);
    resolve(const [_Item('a', done: true), _Item('b')]);

    held.dispose();
    await tester.pump(const Duration(seconds: 1));

    expect(releases, 0);
  });
}
