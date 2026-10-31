import 'package:comfy_list/features/appointments/domain/reminder_minutes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeReminderMinutes', () {
    test('ordena y quita repetidos', () {
      expect(normalizeReminderMinutes([1440, 5, 30, 5]), [
        5,
        30,
        1440,
      ]);
    });

    test('se queda con los cinco más cercanos a la cita', () {
      expect(normalizeReminderMinutes([1440, 60, 30, 5, 10, 15]), [
        5,
        10,
        15,
        30,
        60,
      ]);
    });

    test('descarta los negativos y deja pasar la lista vacía', () {
      expect(normalizeReminderMinutes([-5, 30]), [30]);
      expect(normalizeReminderMinutes(const []), isEmpty);
    });
  });

  group('reminderMinutesToString', () {
    test('guarda la lista canónica separada por comas', () {
      expect(reminderMinutesToString([1440, 30, 30]), '30,1440');
      expect(reminderMinutesToString(const []), '');
    });
  });

  group('parseReminderMinutes', () {
    test('lee lo guardado', () {
      expect(parseReminderMinutes('5,30,1440'), [5, 30, 1440]);
    });

    test('un valor vacío es «sin avisos»', () {
      expect(parseReminderMinutes(''), isEmpty);
    });

    test('descarta lo que no se puede leer', () {
      expect(parseReminderMinutes('60,,vaya,30'), [30, 60]);
    });

    test('es la inversa de reminderMinutesToString (round-trip seguro)', () {
      const minutes = [5, 30, 1440];
      expect(
        parseReminderMinutes(
          reminderMinutesToString(minutes),
        ),
        minutes,
      );
    });
  });

  group('addReminderMinutes', () {
    test('añade el margen en su sitio', () {
      expect(addReminderMinutes([30], 60), [30, 60]);
      expect(addReminderMinutes([30, 60], 15), [15, 30, 60]);
    });

    test('no añade repetidos', () {
      expect(addReminderMinutes([30, 60], 30), [30, 60]);
    });

    test('no deja pasar de cinco', () {
      expect(addReminderMinutes([5, 10, 15, 30, 60], 1440), [
        5,
        10,
        15,
        30,
        60,
      ]);
    });
  });

  group('removeReminderMinutes', () {
    test('saca el margen y deja el resto', () {
      expect(removeReminderMinutes([5, 30, 1440], 30), [5, 1440]);
    });

    test('sin el margen puesto no cambia nada', () {
      expect(removeReminderMinutes([30], 60), [30]);
    });
  });
}
