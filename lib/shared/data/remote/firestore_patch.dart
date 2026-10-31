import 'firestore_value_codec.dart';

/// Un `patch` parcial de Firestore: el cuerpo con los campos que cambian y la
/// `updateMask` que dice cuáles son. Firestore solo toca los campos de la
/// máscara, así que lo que no se anota no se pisa.
///
/// Todo parche toca `updatedAt`: lo pone [build], no cada llamante.
class FirestorePatch {
  final Map<String, Object?> _fields = {};

  /// Anota [field] siempre, aunque [value] sea `null` (que lo borra).
  void set(String field, Object? value) => _fields[field] = value;

  /// Anota [field] solo si hay [value]; `null` es «no se cambia».
  void setIfNotNull(String field, Object? value) {
    if (value != null) _fields[field] = value;
  }

  /// Para un campo opcional: con [clear] lo borra aunque llegue un valor; si no,
  /// lo anota solo si hay [value]. Es lo que hacen los `clearX` de los
  /// `copyWith`: «no tocar» y «poner a null» son cosas distintas.
  void setOrClear(String field, Object? value, {required bool clear}) {
    if (clear) {
      _fields[field] = null;
    } else {
      setIfNotNull(field, value);
    }
  }

  /// El cuerpo `{ fields: {...} }` y la máscara, en el orden en que se anotaron
  /// los campos, con `updatedAt` al final.
  (Map<String, dynamic> body, List<String> updateMask) build({
    required DateTime updatedAt,
  }) {
    final fields = {..._fields, 'updatedAt': updatedAt};
    return (FirestoreValueCodec.encodeFields(fields), fields.keys.toList());
  }
}
