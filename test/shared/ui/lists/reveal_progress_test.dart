import 'package:comfy_list/shared/ui/lists/reveal_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RevealProgress reveal;

  setUp(() => reveal = RevealProgress());

  group('separationFor', () {
    test('sin nada deslizado no separa', () {
      expect(
        reveal.separationFor('b', previousId: 'a', nextId: 'c'),
        (top: 0.0, bottom: 0.0),
      );
    });

    test('la tarjeta deslizada se separa por los dos lados', () {
      reveal.set('b', 0.6);

      expect(
        reveal.separationFor('b', previousId: 'a', nextId: 'c'),
        (top: 0.6, bottom: 0.6),
      );
    });

    test('la vecina de arriba solo separa su borde de abajo', () {
      reveal.set('a', 0.8);

      expect(
        reveal.separationFor('b', previousId: 'a', nextId: 'c'),
        (top: 0.8, bottom: 0.0),
      );
    });

    test('la vecina de abajo solo separa su borde de arriba', () {
      reveal.set('c', 0.4);

      expect(
        reveal.separationFor('b', previousId: 'a', nextId: 'c'),
        (top: 0.0, bottom: 0.4),
      );
    });

    test('con dos deslizadas gana la que más lo está', () {
      reveal
        ..set('a', 0.3)
        ..set('b', 0.9);

      expect(
        reveal.separationFor('b', previousId: 'a', nextId: 'c'),
        (top: 0.9, bottom: 0.9),
      );
    });

    test('en los extremos no mira más allá de la lista', () {
      reveal.set('a', 0.5);

      expect(reveal.separationFor('a', nextId: 'b'), (top: 0.5, bottom: 0.5));
      expect(
        reveal.separationFor('z', previousId: 'y'),
        (top: 0.0, bottom: 0.0),
      );
    });
  });

  group('set', () {
    test('recorta el progreso a [0, 1]', () {
      reveal
        ..set('a', 3)
        ..set('b', -1);

      expect(reveal.separationFor('a'), (top: 1.0, bottom: 1.0));
      expect(reveal.separationFor('b'), (top: 0.0, bottom: 0.0));
    });

    test('un progreso prácticamente cero olvida la tarjeta', () {
      reveal.set('a', 0.5);

      reveal.set('a', 0.0005);

      expect(reveal.separationFor('a'), (top: 0.0, bottom: 0.0));
    });
  });

  test('retainOnly olvida las tarjetas que ya no se ven', () {
    reveal
      ..set('a', 0.5)
      ..set('b', 0.7);

    reveal.retainOnly(['b']);

    expect(reveal.separationFor('a'), (top: 0.0, bottom: 0.0));
    expect(reveal.separationFor('b'), (top: 0.7, bottom: 0.7));
  });
}
