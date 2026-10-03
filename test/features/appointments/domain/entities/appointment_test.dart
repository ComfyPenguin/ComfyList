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
  });
}
