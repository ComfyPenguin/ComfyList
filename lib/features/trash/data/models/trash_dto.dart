import 'dart:convert';

import '../../../../shared/data/remote/firestore_value_codec.dart';
import '../../domain/entities/trash_entry.dart';

/// DTO entre el documento Firestore de `users/{uid}/trash` y [TrashEntry].
///
/// El elemento borrado va serializado en un campo de texto (`payload`): el
/// codec REST solo entiende valores planos, y así la entidad viaja tal cual.
class TrashDto {
  TrashDto._();

  /// [raw] es el JSON del documento (`name` + `fields`). El uid no se guarda
  /// como campo: viene de la ruta de la colección.
  static TrashEntry fromDocument(Map<String, dynamic> raw, {required String uid}) {
    final fields = FirestoreValueCodec.decodeFields(raw);
    return TrashEntry(
      id: FirestoreValueCodec.idFromName(raw['name'] as String? ?? ''),
      uid: uid,
      groupId: (fields['groupId'] as String?) ?? '',
      deletedAt: (fields['deletedAt'] as DateTime?) ?? DateTime.now(),
      item: TrashItem(
        kind: TrashKind.parse((fields['kind'] as String?) ?? ''),
        itemId: (fields['itemId'] as String?) ?? '',
        parentId: fields['parentId'] as String?,
        label: (fields['label'] as String?) ?? '',
        payload: _decodePayload(fields['payload']),
      ),
    );
  }

  /// Cuerpo `{ fields: {...} }` para `createDocument`.
  static Map<String, dynamic> toCreateBody({
    required String groupId,
    required TrashItem item,
    required DateTime deletedAt,
  }) {
    return FirestoreValueCodec.encodeFields({
      'groupId': groupId,
      'kind': item.kind.value,
      'itemId': item.itemId,
      'parentId': ?item.parentId,
      'label': item.label,
      'payload': jsonEncode(item.payload),
      'deletedAt': deletedAt,
    });
  }

  static Map<String, dynamic> _decodePayload(Object? raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      // Un documento escrito por otra versión no puede tumbar toda la lista.
      return const {};
    }
  }
}
