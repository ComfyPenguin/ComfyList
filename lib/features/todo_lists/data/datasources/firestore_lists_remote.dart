import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../../../../shared/data/remote/firestore_commit.dart';
import '../../../../shared/data/remote/firestore_pages.dart';
import '../../../todos/data/models/todo_dto.dart';
import '../../../todos/domain/entities/todo.dart';
import '../../domain/entities/todo_list.dart';
import '../models/todo_list_dto.dart';

/// Datasource Firestore REST para `users/{uid}/todo_lists`.
class FirestoreListsRemote {
  FirestoreListsRemote(this._dio);

  final Dio _dio;

  String _collectionPath(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/todo_lists';

  Future<List<TodoList>> listLists(String uid) async {
    final docs = await _dio.getAllDocuments(_collectionPath(uid));
    return docs
        .map(TodoListDto.fromDocument)
        .toList(growable: false);
  }

  Future<TodoList> createList({
    required String uid,
    required String name,
    required String iconKey,
  }) async {
    final now = DateTime.now().toUtc();
    final body = TodoListDto.toCreateBody(
      name: name,
      iconKey: iconKey,
      now: now,
    );
    final res = await _dio.post<Map<String, dynamic>>(
      _collectionPath(uid),
      data: body,
    );
    return TodoListDto.fromDocument(res.data!);
  }

  Future<TodoList> updateList({
    required String uid,
    required String id,
    String? name,
    String? iconKey,
  }) async {
    final now = DateTime.now().toUtc();
    final (body, mask) = TodoListDto.toPatchBody(
      name: name,
      iconKey: iconKey,
      now: now,
    );

    final res = await _dio.patch<Map<String, dynamic>>(
      '${_collectionPath(uid)}/$id',
      data: body,
      queryParameters: {
        if (mask.isNotEmpty) 'updateMask.fieldPaths': mask,
      },
    );
    return TodoListDto.fromDocument(res.data!);
  }

  /// Borra la lista y sus tareas en un solo `commit`: Firestore no borra las
  /// subcolecciones al eliminar el documento padre. La lista va la última.
  Future<void> deleteListWithTodos({
    required String uid,
    required String id,
    required List<String> todoIds,
  }) {
    final listPath = 'users/$uid/todo_lists/$id';
    return _dio.commitWrites([
      for (final todoId in todoIds)
        FirestoreWrite.delete('$listPath/todos/$todoId'),
      FirestoreWrite.delete(listPath),
    ]);
  }

  /// Vuelve a escribir la lista y sus tareas, con sus mismos ids, en un solo
  /// `commit`.
  Future<void> restoreListWithTodos({
    required String uid,
    required TodoList list,
    required List<Todo> todos,
  }) {
    final listPath = 'users/$uid/todo_lists/${list.id}';
    return _dio.commitWrites([
      FirestoreWrite.update(listPath, TodoListDto.toRestoreBody(list)),
      for (final todo in todos)
        FirestoreWrite.update(
          '$listPath/todos/${todo.id}',
          TodoDto.toRestoreBody(todo),
        ),
    ]);
  }
}
