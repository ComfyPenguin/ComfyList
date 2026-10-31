import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment', () {
    final base = Appointment(
      id: 'a1',
      title: 'Dentista',
      description: 'Limpieza',
      location: 'Calle Mayor 1',
      dateTime: DateTime.utc(2026, 6, 1, 9),
      isDone: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    test('copyWith with description sets the new value', () {
      final updated = base.copyWith(description: 'd2');

      expect(updated.description, 'd2');
      expect(updated.title, 'Dentista');
      expect(updated.location, 'Calle Mayor 1');
    });

    test('copyWith with clearDescription:true sets null', () {
      final updated = base.copyWith(clearDescription: true);

      expect(updated.description, isNull);
      expect(updated.location, 'Calle Mayor 1');
      expect(updated.title, 'Dentista');
    });

    test('copyWith with clearLocation:true sets null', () {
      final updated = base.copyWith(clearLocation: true);

      expect(updated.location, isNull);
      expect(updated.description, 'Limpieza');
      expect(updated.title, 'Dentista');
    });

    test('copyWith without description or clearDescription keeps the original',
        () {
      final updated = base.copyWith(title: 'Médico');

      expect(updated.title, 'Médico');
      expect(updated.description, 'Limpieza');
      expect(updated.location, 'Calle Mayor 1');
    });

    test('copyWith with isDone toggles only isDone', () {
      final updated = base.copyWith(isDone: true);

      expect(updated.isDone, isTrue);
      expect(updated.title, 'Dentista');
      expect(updated.id, 'a1');
    });

    group('toJson / fromJson', () {
      // Fechas locales, como las que devuelve el códec de Firestore.
      final local = DateTime(2026, 6, 1, 9);
      final appointment = base.copyWith(
        dateTime: local,
        createdAt: local,
        updatedAt: local,
      );

      test('guarda un instante absoluto aunque la fecha sea local', () {
        final json = appointment.toJson();

        expect(json['dateTime'], endsWith('Z'));
        expect(json['createdAt'], endsWith('Z'));
        expect(json['updatedAt'], endsWith('Z'));
      });

      test('vuelve a leerse como el mismo instante, en hora local', () {
        final back = Appointment.fromJson(appointment.toJson());

        expect(back.dateTime, local);
        expect(back.dateTime.isUtc, isFalse);
        expect(back.createdAt, local);
        expect(back.updatedAt, local);
      });

      test('lo escrito desde otra zona horaria cae en el mismo instante', () {
        final json = appointment.toJson()
          ..['dateTime'] = '2026-06-01T07:00:00.000Z';

        final back = Appointment.fromJson(json);

        expect(
          back.dateTime.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 7)),
          isTrue,
        );
      });

      test('un payload antiguo, sin zona, se lee como hora local', () {
        final json = appointment.toJson()
          ..['dateTime'] = '2026-06-01T09:00:00.000'
          ..['createdAt'] = '2026-01-01T00:00:00.000'
          ..['updatedAt'] = '2026-01-01T00:00:00.000';

        final back = Appointment.fromJson(json);

        expect(back.dateTime, DateTime(2026, 6, 1, 9));
        expect(back.createdAt, DateTime(2026, 1, 1));
      });
    });
  });
}
