import 'package:comfy_list/features/todo_lists/data/models/todo_list_dto.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoListDto', () {
    test('fromDocument decodes a Firestore REST document', () {
      final raw = <String, dynamic>{
        'name': 'projects/p/databases/(default)/documents/users/u1/todo_lists/abc',
        'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
          'name': 'Compras',
          'iconKey': 'cart',
          'createdAt': DateTime.utc(2026, 1, 1, 12),
          'updatedAt': DateTime.utc(2026, 1, 2, 12),
        })['fields'],
      };

      final list = TodoListDto.fromDocument(raw);

      expect(list.id, 'abc');
      expect(list.name, 'Compras');
      expect(list.iconKey, 'cart');
      expect(list.createdAt.toUtc(), DateTime.utc(2026, 1, 1, 12));
      expect(list.updatedAt.toUtc(), DateTime.utc(2026, 1, 2, 12));
    });

    test('toCreateBody encodes a complete body', () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final body = TodoListDto.toCreateBody(
        name: 'Compras',
        iconKey: 'cart',
        now: t,
      );

      final decoded = FirestoreValueCodec.decodeFields(body);
      expect(decoded['name'], 'Compras');
      expect(decoded['iconKey'], 'cart');
      expect(decoded['createdAt'], isA<DateTime>());
      expect(decoded['updatedAt'], isA<DateTime>());
      expect(
        (decoded['createdAt'] as DateTime).toUtc(),
        t,
      );
    });

    test('toPatchBody with only name builds a mask without iconKey', () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final (body, mask) = TodoListDto.toPatchBody(
        name: 'Nuevo',
        now: t,
      );

      expect(mask, contains('name'));
      expect(mask, isNot(contains('iconKey')));
      expect(mask, contains('updatedAt'));

      final decoded = FirestoreValueCodec.decodeFields(body);
      expect(decoded['name'], 'Nuevo');
      expect(decoded.containsKey('iconKey'), isFalse);
      expect(decoded['updatedAt'], isA<DateTime>());
    });

    test('toPatchBody without name or iconKey only updates updatedAt', () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final (body, mask) = TodoListDto.toPatchBody(now: t);

      expect(mask, isNot(contains('name')));
      expect(mask, isNot(contains('iconKey')));
      expect(mask, contains('updatedAt'));
    });
  });
}
