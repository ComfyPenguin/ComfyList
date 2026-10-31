import 'package:comfy_list/features/appointments/domain/entities/repeat_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const daily = RepeatRule(interval: 1, unit: RepeatUnit.day);

  group('RepeatRule.nextAfter', () {
    test('cada día salta a la misma hora del día siguiente', () {
      final next = daily.nextAfter(
        DateTime(2026, 1, 10, 9),
        now: DateTime(2026, 1, 10, 8),
      );

      expect(next, DateTime(2026, 1, 11, 9));
    });

    test('con intervalo mayor que 1 salta de N en N', () {
      const everyThreeDays = RepeatRule(interval: 3, unit: RepeatUnit.day);

      final next = everyThreeDays.nextAfter(
        DateTime(2026, 1, 10, 9),
        now: DateTime(2026, 1, 10, 8),
      );

      expect(next, DateTime(2026, 1, 13, 9));
    });

    test('cada N semanas conserva el día de la semana', () {
      const everyTwoWeeks = RepeatRule(interval: 2, unit: RepeatUnit.week);

      final next = everyTwoWeeks.nextAfter(
        DateTime(2026, 9, 7, 10),
        now: DateTime(2026, 9, 7, 9),
      );

      expect(next, DateTime(2026, 9, 21, 10));
      expect(next.weekday, DateTime.monday);
    });

    test('cada mes conserva el día del mes', () {
      const monthly = RepeatRule(interval: 1, unit: RepeatUnit.month);

      expect(
        monthly.nextAfter(DateTime(2026, 1, 15, 9), now: DateTime(2026, 1, 1)),
        DateTime(2026, 2, 15, 9),
      );
    });

    test('un mensual de diciembre pasa al enero del año siguiente', () {
      const monthly = RepeatRule(interval: 1, unit: RepeatUnit.month);

      expect(
        monthly.nextAfter(DateTime(2026, 12, 15, 9), now: DateTime(2026, 12)),
        DateTime(2027, 1, 15, 9),
      );
    });

    test('cada año conserva el día y el mes', () {
      const yearly = RepeatRule(interval: 1, unit: RepeatUnit.year);

      expect(
        yearly.nextAfter(DateTime(2026, 5, 4, 18), now: DateTime(2026, 5)),
        DateTime(2027, 5, 4, 18),
      );
    });

    test('una cita atrasada varias ocurrencias salta a la primera futura', () {
      const weekly = RepeatRule(interval: 1, unit: RepeatUnit.week);

      // Lunes 7 de septiembre, completada el jueves 24: los lunes 14 y 21 ya
      // pasaron, así que el siguiente es el 28.
      final next = weekly.nextAfter(
        DateTime(2026, 9, 7, 10),
        now: DateTime(2026, 9, 24, 12),
      );

      expect(next, DateTime(2026, 9, 28, 10));
    });

    test('una ocurrencia que cae justo ahora ya no cuenta como futura', () {
      final next = daily.nextAfter(
        DateTime(2026, 1, 10, 9),
        now: DateTime(2026, 1, 11, 9),
      );

      expect(next, DateTime(2026, 1, 12, 9));
    });

    test('una cita futura completada antes de tiempo avanza un solo paso', () {
      final next = daily.nextAfter(
        DateTime(2026, 1, 20, 9),
        now: DateTime(2026, 1, 10, 9),
      );

      expect(next, DateTime(2026, 1, 21, 9));
    });

    group('fin de mes', () {
      const monthly = RepeatRule(interval: 1, unit: RepeatUnit.month);

      test('un día que no existe cae en el último del mes', () {
        expect(
          monthly.nextAfter(DateTime(2026, 1, 31, 9), now: DateTime(2026, 1)),
          DateTime(2026, 2, 28, 9),
        );
      });

      test('en año bisiesto febrero llega al 29', () {
        expect(
          monthly.nextAfter(DateTime(2028, 1, 31, 9), now: DateTime(2028, 1)),
          DateTime(2028, 2, 29, 9),
        );
      });

      test('al saltar varias ocurrencias no se arrastra el recorte', () {
        // El 28 de febrero ya pasó; el siguiente es el 31 de marzo, no el 28.
        expect(
          monthly.nextAfter(DateTime(2026, 1, 31, 9), now: DateTime(2026, 3, 1)),
          DateTime(2026, 3, 31, 9),
        );
      });

      test('el 29 de febrero anual cae en el 28 los años no bisiestos', () {
        const yearly = RepeatRule(interval: 1, unit: RepeatUnit.year);

        expect(
          yearly.nextAfter(DateTime(2028, 2, 29, 9), now: DateTime(2028, 3)),
          DateTime(2029, 2, 28, 9),
        );
      });
    });

    test('conserva la hora local aunque por medio cambie el horario', () {
      // Cruza el cambio de hora de marzo y el de octubre en las zonas que lo
      // tienen; en las que no, es trivialmente cierto.
      const weekly = RepeatRule(interval: 1, unit: RepeatUnit.week);
      final from = DateTime(2026, 3, 20, 9, 15);

      for (final now in [DateTime(2026, 4, 10), DateTime(2026, 11, 10)]) {
        final next = weekly.nextAfter(from, now: now);

        expect(next.isAfter(now), isTrue);
        expect([next.hour, next.minute], [9, 15]);
      }
    });
  });

  test('un intervalo menor que 1 no es una regla', () {
    expect(
      () => RepeatRule(interval: 0, unit: RepeatUnit.day),
      throwsAssertionError,
    );
  });
}
