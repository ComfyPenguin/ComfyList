import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../../../../shared/data/remote/firestore_commit.dart';
import '../../../../shared/data/remote/firestore_pages.dart';
import '../../domain/entities/trash_entry.dart';
import '../models/trash_dto.dart';

/// Datasource Firestore REST para `users/{uid}/trash`.
class FirestoreTrashRemote {
  FirestoreTrashRemote(this._dio);

  final Dio _dio;

  String _collectionPath(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/trash';

  /// Todas las entradas de la cuenta, en el orden que devuelva Firestore.
  Future<List<TrashEntry>> listEntries(String uid) async {
    final docs = await _dio.getAllDocuments(_collectionPath(uid));
    return docs
        .map((doc) => TrashDto.fromDocument(doc, uid: uid))
        .toList(growable: false);
  }

  /// Guarda [items] en un solo `commit`. El id lo pone el cliente porque con
  /// `createDocument` lo reparte el servidor y haría falta una petición por
  /// elemento.
  Future<void> createEntries({
    required String uid,
    required String groupId,
    required List<TrashItem> items,
    required DateTime deletedAt,
  }) {
    return _dio.commitWrites([
      for (final item in items)
        FirestoreWrite.update(
          'users/$uid/trash/${generateFirestoreId()}',
          TrashDto.toCreateBody(
            groupId: groupId,
            item: item,
            deletedAt: deletedAt,
          ),
        ),
    ]);
  }

  Future<void> deleteEntries({
    required String uid,
    required List<String> ids,
  }) {
    return _dio.commitWrites([
      for (final id in ids) FirestoreWrite.delete('users/$uid/trash/$id'),
    ]);
  }
}
