import '../../../../shared/data/remote/firestore_patch.dart';
import '../../../../shared/data/remote/firestore_value_codec.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/reminder_minutes.dart';

/// DTO entre el formato de documento Firestore REST y la entidad de dominio.
class AppointmentDto {
  /// Construye un Appointment desde un documento Firestore REST.
  /// `raw` es el JSON tal cual viene en `documents` (con `name` y `fields`).
  static Appointment fromDocument(Map<String, dynamic> raw) {
    final id = FirestoreValueCodec.idFromName(raw['name'] as String? ?? '');
    final fields = FirestoreValueCodec.decodeFields(raw);
    return Appointment(
      id: id,
      title: (fields['title'] as String?) ?? '',
      description: fields['description'] as String?,
      location: fields['location'] as String?,
      repeatRule: RepeatRule.fromStored(
        interval: fields['repeatInterval'],
        unit: fields['repeatUnit'],
      ),
      reminderMinutes: switch (fields['reminderMinutes']) {
        final String stored => parseReminderMinutes(stored),
        // Sin el campo es una cita de antes de que cada una llevara los suyos.
        _ => defaultReminderMinutes,
      },
      dateTime:
          (fields['dateTime'] as DateTime?) ?? DateTime.now(),
      isDone: (fields['isDone'] as bool?) ?? false,
      createdAt:
          (fields['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt:
          (fields['updatedAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  /// Cuerpo `{ fields: {...} }` para `createDocument` o `patch`.
  static Map<String, dynamic> toCreateBody({
    required String title,
    String? description,
    String? location,
    RepeatRule? repeatRule,
    required List<int> reminderMinutes,
    required DateTime dateTime,
    bool isDone = false,
    required DateTime now,
  }) {
    return FirestoreValueCodec.encodeFields({
      'title': title,
      'description': ?description,
      'location': ?location,
      'repeatInterval': ?repeatRule?.interval,
      'repeatUnit': ?repeatRule?.unit.name,
      'reminderMinutes': reminderMinutesToString(reminderMinutes),
      'dateTime': dateTime,
      'isDone': isDone,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// Cuerpo para devolver a Firestore una cita borrada, tal y como estaba: el
  /// `patch` sobre un documento inexistente la vuelve a crear.
  static Map<String, dynamic> toRestoreBody(Appointment appointment) {
    return FirestoreValueCodec.encodeFields({
      'title': appointment.title,
      'description': ?appointment.description,
      'location': ?appointment.location,
      'repeatInterval': ?appointment.repeatRule?.interval,
      'repeatUnit': ?appointment.repeatRule?.unit.name,
      'reminderMinutes': reminderMinutesToString(appointment.reminderMinutes),
      'dateTime': appointment.dateTime,
      'isDone': appointment.isDone,
      'createdAt': appointment.createdAt,
      'updatedAt': appointment.updatedAt,
    });
  }

  /// Cuerpo para `patch` con campos parciales.
  static (Map<String, dynamic> body, List<String> updateMask) toPatchBody({
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    RepeatRule? repeatRule,
    bool clearRepeatRule = false,
    List<int>? reminderMinutes,
    DateTime? dateTime,
    bool? isDone,
    required DateTime now,
  }) {
    return (FirestorePatch()
          ..setIfNotNull('title', title)
          ..setOrClear('description', description, clear: clearDescription)
          ..setOrClear('location', location, clear: clearLocation)
          ..setOrClear(
            'repeatInterval',
            repeatRule?.interval,
            clear: clearRepeatRule,
          )
          ..setOrClear(
            'repeatUnit',
            repeatRule?.unit.name,
            clear: clearRepeatRule,
          )
          // Vaciar los márgenes escribe el texto vacío en vez de borrar el campo:
          // un campo ausente es una cita antigua y volvería a avisar a los 30.
          ..setIfNotNull(
            'reminderMinutes',
            reminderMinutes == null
                ? null
                : reminderMinutesToString(reminderMinutes),
          )
          ..setIfNotNull('dateTime', dateTime)
          ..setIfNotNull('isDone', isDone))
        .build(updatedAt: now);
  }
}
