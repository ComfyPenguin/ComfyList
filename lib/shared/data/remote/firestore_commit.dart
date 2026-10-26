import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/env/firebase_endpoints.dart';

/// Una escritura de un `commit` de Firestore. [path] es relativo a la raíz de
/// documentos, p. ej. `users/$uid/todo_lists/$id`.
class FirestoreWrite {
  const FirestoreWrite.update(this.path, Map<String, dynamic> this.body);
  const FirestoreWrite.delete(this.path) : body = null;

  final String path;
  final Map<String, dynamic>? body;

  static const String _root =
      'projects/${FirebaseEndpoints.projectId}/databases/(default)/documents';

  Map<String, dynamic> toJson() {
    final name = '$_root/$path';
    final fields = body;
    return fields == null
        ? {'delete': name}
        : {
            'update': {'name': name, ...fields},
          };
  }
}

extension FirestoreCommit on Dio {
  /// Firestore admite 500 escrituras por `commit`.
  static const int maxWritesPerCommit = 500;

  /// Manda [writes] en el menor número de peticiones, en orden. La atomicidad
  /// solo vale dentro de cada tanda de [maxWritesPerCommit].
  Future<void> commitWrites(List<FirestoreWrite> writes) async {
    for (var i = 0; i < writes.length; i += maxWritesPerCommit) {
      final chunk = writes.sublist(
        i,
        min(i + maxWritesPerCommit, writes.length),
      );
      await post<void>(
        '${FirebaseEndpoints.firestoreBase}:commit',
        data: {
          'writes': [for (final w in chunk) w.toJson()],
        },
      );
    }
  }
}

const _idAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// Id con el formato de los que reparte Firestore (20 caracteres
/// alfanuméricos), para los documentos cuyo nombre fija el cliente.
String generateFirestoreId() {
  final random = Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < 20; i++)
      _idAlphabet.codeUnitAt(random.nextInt(_idAlphabet.length)),
  ]);
}
