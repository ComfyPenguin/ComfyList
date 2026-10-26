import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
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

  Future<TrashEntry> createEntry({
    required String uid,
    required String groupId,
    required TrashItem item,
    required DateTime deletedAt,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _collectionPath(uid),
      data: TrashDto.toCreateBody(
        groupId: groupId,
        item: item,
        deletedAt: deletedAt,
      ),
    );
    return TrashDto.fromDocument(res.data!, uid: uid);
  }

  Future<void> deleteEntry({
    required String uid,
    required String id,
  }) async {
    await _dio.delete<void>('${_collectionPath(uid)}/$id');
  }
}
