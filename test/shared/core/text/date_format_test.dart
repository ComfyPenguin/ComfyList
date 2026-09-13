import 'package:comfy_list/shared/core/text/date_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  group('formatLongDate', () {
    test('compone la fecha larga con día y mes en mayúscula', () {
      expect(
        formatLongDate(DateTime(2026, 9, 30)),
        'Miércoles, 30 de Septiembre de 2026',
      );
    });

    test('mantiene el día real del mes', () {
      expect(
        formatLongDate(DateTime(2026, 1, 1)),
        'Jueves, 1 de Enero de 2026',
      );
    });
  });
}
