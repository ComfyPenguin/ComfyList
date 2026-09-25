import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../../domain/entities/todo_list.dart';
import '../models/todo_list_dto.dart';

/// Datasource Firestore REST para `users/{uid}/todo_lists`.
class FirestoreListsRemote {
  FirestoreListsRemote(this._dio);

  final Dio _dio;

  String _collectionPath(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/todo_lists';

  Future<List<TodoList>> listLists(String uid) async {
    final res = await _dio.get<Map<String, dynamic>>(_collectionPath(uid));
    final docs = (res.data?['documents'] as List?) ?? const [];
    return docs
        .cast<Map<String, dynamic>>()
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

  Future<void> deleteList({
    required String uid,
    required String id,
  }) async {
    await _dio.delete<void>('${_collectionPath(uid)}/$id');
  }

  /// Vuelve a escribir el documento de [list] con su mismo id.
  Future<TodoList> restoreList({
    required String uid,
    required TodoList list,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '${_collectionPath(uid)}/${list.id}',
      data: TodoListDto.toRestoreBody(list),
    );
    return TodoListDto.fromDocument(res.data!);
  }

  /// Lista los IDs de los documentos de la subcolección `todos` de una
  /// lista. Útil para el cascade delete (Firestore no borra subcolecciones
  /// automáticamente al eliminar el documento padre).
  Future<List<String>> listTodoIdsOfList({
    required String uid,
    required String listId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '${_collectionPath(uid)}/$listId/todos',
    );
    final docs = (res.data?['documents'] as List?) ?? const [];
    return docs
        .cast<Map<String, dynamic>>()
        .map((d) {
          final name = d['name'] as String? ?? '';
          return name.split('/').last;
        })
        .toList(growable: false);
  }

  Future<void> deleteTodoOfList({
    required String uid,
    required String listId,
    required String todoId,
  }) async {
    await _dio.delete<void>(
      '${_collectionPath(uid)}/$listId/todos/$todoId',
    );
  }
}
