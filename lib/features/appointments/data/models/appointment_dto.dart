import '../../../../shared/data/remote/firestore_value_codec.dart';
import '../../domain/entities/appointment.dart';

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
    required DateTime dateTime,
    bool isDone = false,
    required DateTime now,
  }) {
    return FirestoreValueCodec.encodeFields({
      'title': title,
      'description': ?description,
      'location': ?location,
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
    DateTime? dateTime,
    bool? isDone,
    required DateTime now,
  }) {
    final fields = <String, dynamic>{};
    final mask = <String>[];

    if (title != null) {
      fields['title'] = title;
      mask.add('title');
    }
    if (clearDescription) {
      fields['description'] = null;
      mask.add('description');
    } else if (description != null) {
      fields['description'] = description;
      mask.add('description');
    }
    if (clearLocation) {
      fields['location'] = null;
      mask.add('location');
    } else if (location != null) {
      fields['location'] = location;
      mask.add('location');
    }
    if (dateTime != null) {
      fields['dateTime'] = dateTime;
      mask.add('dateTime');
    }
    if (isDone != null) {
      fields['isDone'] = isDone;
      mask.add('isDone');
    }
    fields['updatedAt'] = now;
    mask.add('updatedAt');

    return (FirestoreValueCodec.encodeFields(fields), mask);
  }
}
