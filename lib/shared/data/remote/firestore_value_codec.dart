/// Codec mínimo entre el formato de valor de Firestore REST y JSON Dart.
///
/// Documentos REST tienen forma:
///   { "fields": { "title": { "stringValue": "..." }, "isDone": { "booleanValue": false } } }
///
/// Esta clase convierte:
///   - mapa Dart → mapa `{ "fields": {...} }` para enviar.
///   - mapa REST `{ fields: {...} }` → mapa Dart plano para deserializar.
///
/// Solo soporta los tipos que la app usa (string, int, bool, datetime, null).
class FirestoreValueCodec {
  FirestoreValueCodec._();

  /// Convierte un mapa plano Dart al formato `fields` esperado por Firestore.
  static Map<String, dynamic> encodeFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    data.forEach((key, value) => fields[key] = encodeValue(value));
    return {'fields': fields};
  }

  /// Convierte un único valor Dart al objeto tipado de Firestore.
  static Map<String, dynamic> encodeValue(Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    throw ArgumentError('Tipo no soportado: ${value.runtimeType}');
  }

  /// Decodifica un documento REST (con clave `fields`) a mapa plano.
  static Map<String, dynamic> decodeFields(Map<String, dynamic>? raw) {
    if (raw == null) return const {};
    final fields = raw['fields'] as Map<String, dynamic>?;
    if (fields == null) return const {};

    final out = <String, dynamic>{};
    fields.forEach((key, value) {
      out[key] = decodeValue(value as Map<String, dynamic>);
    });
    return out;
  }

  static Object? decodeValue(Map<String, dynamic> wrapped) {
    if (wrapped.containsKey('nullValue')) return null;
    if (wrapped.containsKey('stringValue')) return wrapped['stringValue'] as String;
    if (wrapped.containsKey('booleanValue')) {
      return wrapped['booleanValue'] as bool;
    }
    if (wrapped.containsKey('integerValue')) {
      return int.parse(wrapped['integerValue'] as String);
    }
    if (wrapped.containsKey('doubleValue')) {
      return (wrapped['doubleValue'] as num).toDouble();
    }
    if (wrapped.containsKey('timestampValue')) {
      // Firestore devuelve ISO 8601 con Z; `DateTime.parse` lo deja en UTC.
      // Convertimos a local porque `DateFormat.format` usa los componentes
      // del DateTime tal cual (no aplica timezone), y el dominio espera
      // poder formatear directamente la "hora del usuario". Dart consulta
      // tzdata del SO, así que DST (CET/CEST) se resuelve correctamente
      // para la fecha específica del timestamp.
      return DateTime.parse(wrapped['timestampValue'] as String).toLocal();
    }
    return null;
  }

  /// Extrae el id del documento desde el campo `name` que devuelve Firestore.
  /// Ej: "projects/comfy-list/databases/(default)/documents/users/{uid}/todos/abc123"
  static String idFromName(String name) {
    final parts = name.split('/');
    return parts.isEmpty ? '' : parts.last;
  }
}
