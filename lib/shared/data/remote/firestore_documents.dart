import 'package:dio/dio.dart';

extension FirestoreDocuments on Dio {
  /// Crea un documento en la colección [collectionUrl]; el id lo reparte
  /// Firestore. Devuelve el documento tal y como queda.
  Future<Map<String, dynamic>> createDocument(
    String collectionUrl,
    Map<String, dynamic> body,
  ) async {
    final res = await post<Map<String, dynamic>>(collectionUrl, data: body);
    return res.data!;
  }

  /// Escribe [body] en el documento [documentUrl] y devuelve cómo queda.
  ///
  /// Con [updateMask] solo se tocan esos campos; sin ella el documento se
  /// reescribe entero, y si no existe se crea con ese id.
  Future<Map<String, dynamic>> patchDocument(
    String documentUrl,
    Map<String, dynamic> body, {
    List<String> updateMask = const [],
  }) async {
    final res = updateMask.isEmpty
        ? await patch<Map<String, dynamic>>(documentUrl, data: body)
        : await patch<Map<String, dynamic>>(
            documentUrl,
            data: body,
            queryParameters: {'updateMask.fieldPaths': updateMask},
          );
    return res.data!;
  }
}
