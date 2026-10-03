import 'package:comfy_list/shared/core/text/date_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  group('formatLongDate', () {
    test('compone la fecha larga con día y mes en mayúscula', () {
      expect(
        formatLongDate(DateTime(2026, 9, 30)),
        'Miércoles, 30 Septiembre 2026',
      );
    });

    test('mantiene el día real del mes', () {
      expect(
        formatLongDate(DateTime(2026, 1, 1)),
        'Jueves, 1 Enero 2026',
      );
    });
  });

  group('formatClockTime', () {
    test('en 24 h usa HH:mm sin periodo', () {
      final time = DateTime(2026, 9, 30, 14, 5);
      expect(formatClockTime(time, use24HourFormat: true), '14:05');
      expect(formatClockPeriod(time, use24HourFormat: true), isEmpty);
      expect(
        formatClockTimeWithPeriod(time, use24HourFormat: true),
        '14:05',
      );
    });

    test('en 12 h añade el periodo normalizado', () {
      final time = DateTime(2026, 9, 30, 14, 5);
      expect(formatClockTime(time, use24HourFormat: false), '02:05');
      expect(formatClockPeriod(time, use24HourFormat: false), 'PM');
      expect(
        formatClockTimeWithPeriod(time, use24HourFormat: false),
        '02:05 PM',
      );
    });

    test('la medianoche sale como AM', () {
      final time = DateTime(2026, 9, 30);
      expect(formatClockPeriod(time, use24HourFormat: false), 'AM');
      expect(
        formatClockTimeWithPeriod(time, use24HourFormat: false),
        '12:00 AM',
      );
    });
  });
}
