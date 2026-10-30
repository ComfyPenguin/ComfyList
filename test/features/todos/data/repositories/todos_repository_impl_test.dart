import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

class _MockRemote extends Mock implements FirestoreRestRemote {}

void main() {
  late _MockRemote remote;
  late TodosRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = TodosRepositoryImpl(remote);
  });

  tearDown(() {
    repo.dispose();
  });

  group('TodosRepositoryImpl', () {
    test('fetchTodos returns Ok(list) on remote success', () async {
      when(() => remote.listTodos(uid: 'u1', listId: 'L1'))
          .thenAnswer((_) async => [buildTodo()]);

      final res = await repo.fetchTodos(uid: 'u1', listId: 'L1');

      expect(res.isOk, isTrue);
      final ok = res as Ok<List<Todo>>;
      expect(ok.value, hasLength(1));
      expect(ok.value.first.id, 't1');
    });

    test('el watcher vuelve a pedir la lista en cada tick', () async {
      when(() => remote.listTodos(uid: 'u1', listId: 'L1'))
          .thenAnswer((_) async => <Todo>[buildTodo()]);

      final polled = TodosRepositoryImpl(
        remote,
        pollInterval: const Duration(milliseconds: 20),
      );
      addTearDown(polled.dispose);

      final sub = polled.watchTodos(uid: 'u1', listId: 'L1').listen((_) {});

      // Margen de sobra para el fetch inicial y varios ticks.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await sub.cancel();

      verify(() => remote.listTodos(uid: 'u1', listId: 'L1'))
          .called(greaterThan(1));
    });

    test('cada lista tiene su propio watcher y refresh solo toca la suya',
        () async {
      when(() => remote.listTodos(uid: 'u1', listId: any(named: 'listId')))
          .thenAnswer((_) async => <Todo>[buildTodo()]);

      final subs = [
        repo.watchTodos(uid: 'u1', listId: 'L1').listen((_) {}),
        repo.watchTodos(uid: 'u1', listId: 'L2').listen((_) {}),
      ];
      await pumpEventQueue();
      clearInteractions(remote);

      await repo.refresh(uid: 'u1', listId: 'L2');

      verify(() => remote.listTodos(uid: 'u1', listId: 'L2')).called(1);
      verifyNever(() => remote.listTodos(uid: 'u1', listId: 'L1'));
      for (final sub in subs) {
        await sub.cancel();
      }
    });
  });
}
