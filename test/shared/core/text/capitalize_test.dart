import 'package:comfy_list/shared/core/text/capitalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('capitalize', () {
    test('sube la inicial y respeta el resto', () {
      expect(capitalize('miércoles'), 'Miércoles');
      expect(capitalize('30 de septiembre'), '30 de septiembre');
    });

    test('deja igual una cadena vacía', () {
      expect(capitalize(''), '');
    });
  });
}
