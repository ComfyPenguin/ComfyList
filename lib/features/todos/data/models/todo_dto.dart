import '../../../../shared/data/remote/firestore_value_codec.dart';
import '../../domain/entities/todo.dart';

/// DTO entre el formato de documento Firestore REST y la entidad de dominio.
class TodoDto {
  /// Construye un Todo desde un documento Firestore REST.
  /// `raw` es el JSON tal cual viene en `documents` (con `name` y `fields`).
  static Todo fromDocument(Map<String, dynamic> raw) {
    final id = FirestoreValueCodec.idFromName(raw['name'] as String? ?? '');
    final fields = FirestoreValueCodec.decodeFields(raw);
    return Todo(
      id: id,
      title: (fields['title'] as String?) ?? '',
      description: fields['description'] as String?,
      isDone: (fields['isDone'] as bool?) ?? false,
      createdAt: (fields['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: (fields['updatedAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  /// Cuerpo `{ fields: {...} }` para `createDocument` o `patch`.
  static Map<String, dynamic> toCreateBody({
    required String title,
    String? description,
    bool isDone = false,
    required DateTime now,
  }) {
    return FirestoreValueCodec.encodeFields({
      'title': title,
      'description': ?description,
      'isDone': isDone,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// Cuerpo para devolver a Firestore un todo borrado, tal y como estaba: el
  /// `patch` sobre un documento inexistente lo vuelve a crear.
  static Map<String, dynamic> toRestoreBody(Todo todo) {
    return FirestoreValueCodec.encodeFields({
      'title': todo.title,
      'description': ?todo.description,
      'isDone': todo.isDone,
      'createdAt': todo.createdAt,
      'updatedAt': todo.updatedAt,
    });
  }

  /// Cuerpo para `patch` con campos parciales.
  static (Map<String, dynamic> body, List<String> updateMask) toPatchBody({
    String? title,
    String? description,
    bool clearDescription = false,
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
    if (isDone != null) {
      fields['isDone'] = isDone;
      mask.add('isDone');
    }
    fields['updatedAt'] = now;
    mask.add('updatedAt');

    return (FirestoreValueCodec.encodeFields(fields), mask);
  }
}
