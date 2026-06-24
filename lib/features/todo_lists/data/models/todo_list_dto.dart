import '../../../../shared/data/remote/firestore_value_codec.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/entities/todo_list_icons.dart';

/// DTO entre el formato de documento Firestore REST y [TodoList].
class TodoListDto {
  static TodoList fromDocument(Map<String, dynamic> raw) {
    final id = FirestoreValueCodec.idFromName(raw['name'] as String? ?? '');
    final fields = FirestoreValueCodec.decodeFields(raw);
    return TodoList(
      id: id,
      name: (fields['name'] as String?) ?? '',
      iconKey: (fields['iconKey'] as String?) ?? TodoListIcons.defaultKey,
      createdAt: (fields['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: (fields['updatedAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toCreateBody({
    required String name,
    required String iconKey,
    required DateTime now,
  }) {
    return FirestoreValueCodec.encodeFields({
      'name': name,
      'iconKey': iconKey,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static (Map<String, dynamic> body, List<String> updateMask) toPatchBody({
    String? name,
    String? iconKey,
    required DateTime now,
  }) {
    final fields = <String, dynamic>{};
    final mask = <String>[];

    if (name != null) {
      fields['name'] = name;
      mask.add('name');
    }
    if (iconKey != null) {
      fields['iconKey'] = iconKey;
      mask.add('iconKey');
    }
    fields['updatedAt'] = now;
    mask.add('updatedAt');

    return (FirestoreValueCodec.encodeFields(fields), mask);
  }
}
