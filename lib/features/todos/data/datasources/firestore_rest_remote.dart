import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/data/remote/firestore_documents.dart';
import '../../../../shared/data/remote/firestore_pages.dart';
import '../../domain/entities/todo.dart';
import '../models/todo_dto.dart';

/// Datasource Firestore REST para `users/{uid}/todo_lists/{listId}/todos`.
///
/// Cada lista de tareas vive en su propia subcolección bajo el documento
/// de la lista padre. Usa el cliente principal del [DioClient]
/// (con [AuthInterceptor]). [now] da el «ahora» de `createdAt` y `updatedAt`;
/// en la app es el reloj de la app.
class FirestoreRestRemote {
  FirestoreRestRemote(this._dio, {Now now = DateTime.now}) : _now = now;

  final Dio _dio;
  final Now _now;

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
    final body = TodoDto.toCreateBody(
      title: title,
      description: description,
      now: _now().toUtc(),
    );
    return TodoDto.fromDocument(
      await _dio.createDocument(_collectionPath(uid, listId), body),
    );
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
    final (body, mask) = TodoDto.toPatchBody(
      title: title,
      description: description,
      clearDescription: clearDescription,
      isDone: isDone,
      now: _now().toUtc(),
    );
    return TodoDto.fromDocument(
      await _dio.patchDocument(
        '${_collectionPath(uid, listId)}/$id',
        body,
        updateMask: mask,
      ),
    );
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
    return TodoDto.fromDocument(
      await _dio.patchDocument(
        '${_collectionPath(uid, listId)}/${todo.id}',
        TodoDto.toRestoreBody(todo),
      ),
    );
  }
}
