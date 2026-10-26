import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../../../../shared/data/remote/firestore_pages.dart';
import '../../domain/entities/todo.dart';
import '../models/todo_dto.dart';

/// Datasource Firestore REST para `users/{uid}/todo_lists/{listId}/todos`.
///
/// Cada lista de tareas vive en su propia subcolección bajo el documento
/// de la lista padre. Usa el cliente principal del [DioClient]
/// (con [AuthInterceptor]).
class FirestoreRestRemote {
  FirestoreRestRemote(this._dio);

  final Dio _dio;

  String _collectionPath(String uid, String listId) =>
      '${FirebaseEndpoints.firestoreBase}'
      '/users/$uid/todo_lists/$listId/todos';

  Future<List<Todo>> listTodos({
    required String uid,
    required String listId,
  }) async {
    final docs = await _dio.getAllDocuments(_collectionPath(uid, listId));
    return docs
        .map(TodoDto.fromDocument)
        .toList(growable: false);
  }

  Future<Todo> createTodo({
    required String uid,
    required String listId,
    required String title,
    String? description,
  }) async {
    final now = DateTime.now().toUtc();
    final body = TodoDto.toCreateBody(
      title: title,
      description: description,
      now: now,
    );
    final res = await _dio.post<Map<String, dynamic>>(
      _collectionPath(uid, listId),
      data: body,
    );
    return TodoDto.fromDocument(res.data!);
  }

  Future<Todo> updateTodo({
    required String uid,
    required String listId,
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    bool? isDone,
  }) async {
    final now = DateTime.now().toUtc();
    final (body, mask) = TodoDto.toPatchBody(
      title: title,
      description: description,
      clearDescription: clearDescription,
      isDone: isDone,
      now: now,
    );

    final res = await _dio.patch<Map<String, dynamic>>(
      '${_collectionPath(uid, listId)}/$id',
      data: body,
      queryParameters: {
        if (mask.isNotEmpty) 'updateMask.fieldPaths': mask,
      },
    );
    return TodoDto.fromDocument(res.data!);
  }

  Future<void> deleteTodo({
    required String uid,
    required String listId,
    required String id,
  }) async {
    await _dio.delete<void>('${_collectionPath(uid, listId)}/$id');
  }

  /// Vuelve a escribir el documento de [todo] con su mismo id.
  Future<Todo> restoreTodo({
    required String uid,
    required String listId,
    required Todo todo,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '${_collectionPath(uid, listId)}/${todo.id}',
      data: TodoDto.toRestoreBody(todo),
    );
    return TodoDto.fromDocument(res.data!);
  }
}
