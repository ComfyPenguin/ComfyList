import 'package:dio/dio.dart';

extension FirestorePages on Dio {
  /// Cuántos documentos se piden por vuelta.
  static const int pageSize = 300;

  /// Todos los documentos de la colección [url]. Firestore la corta en páginas
  /// y puede devolver menos de los pedidos, así que hay que seguir el
  /// `nextPageToken` hasta el final.
  Future<List<Map<String, dynamic>>> getAllDocuments(String url) async {
    final docs = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final res = await get<Map<String, dynamic>>(
        url,
        queryParameters: {'pageSize': pageSize, 'pageToken': ?pageToken},
      );
      docs.addAll(
        ((res.data?['documents'] as List?) ?? const [])
            .cast<Map<String, dynamic>>(),
      );
      pageToken = res.data?['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
    return docs;
  }
}
