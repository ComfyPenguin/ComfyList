import 'package:comfy_list/features/appointments/domain/appointment_agenda.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  // Fechas locales, como las que llegan de la cuenta.
  DateTime at(int day, [int hour = 9]) => DateTime(2026, 6, day, hour);

  group('sortAppointments', () {
    test('ordena por fecha ascendente', () {
      final sorted = sortAppointments([
        buildAppointment(id: 'b', dateTime: at(3)),
        buildAppointment(id: 'a', dateTime: at(1)),
      ], completedToBottom: false);

      expect(sorted.map((a) => a.id), ['a', 'b']);
    });

    test('con completedToBottom las hechas van detrás de las pendientes', () {
      final sorted = sortAppointments([
        buildAppointment(id: 'hecha', isDone: true, dateTime: at(1)),
        buildAppointment(id: 'pendiente', dateTime: at(1, 18)),
      ], completedToBottom: true);

      expect(sorted.map((a) => a.id), ['pendiente', 'hecha']);
    });

    test('sin completedToBottom las hechas conservan su hora', () {
      final sorted = sortAppointments([
        buildAppointment(id: 'pendiente', dateTime: at(1, 18)),
        buildAppointment(id: 'hecha', isDone: true, dateTime: at(1)),
      ], completedToBottom: false);

      expect(sorted.map((a) => a.id), ['hecha', 'pendiente']);
    });
  });

  group('groupByDay', () {
    final today = DateTime(2026, 6, 10);

    List<DateTime> datesOf(List<AgendaDay> days) =>
        [for (final day in days) day.date];

    test('reparte por días de menor a mayor', () {
      final days = groupByDay([
        buildAppointment(id: 'b', dateTime: at(12)),
        buildAppointment(id: 'a', dateTime: at(11)),
      ], todayOnTop: false, today: today);

      expect(datesOf(days), [DateTime(2026, 6, 11), DateTime(2026, 6, 12)]);
    });

    test('conserva el orden de las citas dentro de cada día', () {
      final days = groupByDay([
        buildAppointment(id: 'primera', dateTime: at(11, 8)),
        buildAppointment(id: 'segunda', dateTime: at(11, 20)),
      ], todayOnTop: false, today: today);

      expect(days.single.appointments.map((a) => a.id), [
        'primera',
        'segunda',
      ]);
    });

    test('con todayOnTop, hoy va primero y mañana justo debajo', () {
      final days = groupByDay([
        buildAppointment(id: 'ayer', dateTime: at(8)),
        buildAppointment(id: 'hoy', dateTime: at(10)),
        buildAppointment(id: 'pasado', dateTime: at(12)),
        buildAppointment(id: 'manana', dateTime: at(11)),
      ], todayOnTop: true, today: today);

      expect(datesOf(days), [
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 11),
        DateTime(2026, 6, 8),
        DateTime(2026, 6, 12),
      ]);
    });

    test('sin todayOnTop, los días pasados quedan delante', () {
      final days = groupByDay([
        buildAppointment(id: 'hoy', dateTime: at(10)),
        buildAppointment(id: 'ayer', dateTime: at(8)),
      ], todayOnTop: false, today: today);

      expect(datesOf(days), [DateTime(2026, 6, 8), DateTime(2026, 6, 10)]);
    });

    test('si hoy no tiene citas no se mueve nada', () {
      final days = groupByDay([
        buildAppointment(id: 'ayer', dateTime: at(8)),
        buildAppointment(id: 'manana', dateTime: at(11)),
      ], todayOnTop: true, today: today);

      expect(datesOf(days), [DateTime(2026, 6, 8), DateTime(2026, 6, 11)]);
    });

    test('si mañana ya es el segundo día, queda donde está', () {
      final days = groupByDay([
        buildAppointment(id: 'hoy', dateTime: at(10)),
        buildAppointment(id: 'manana', dateTime: at(11)),
        buildAppointment(id: 'luego', dateTime: at(20)),
      ], todayOnTop: true, today: today);

      expect(datesOf(days), [
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 11),
        DateTime(2026, 6, 20),
      ]);
    });
  });

  test('dayAfter salta de mes y de año', () {
    expect(dayAfter(DateTime(2026, 6, 30)), DateTime(2026, 7, 1));
    expect(dayAfter(DateTime(2026, 12, 31)), DateTime(2027, 1, 1));
  });
}
