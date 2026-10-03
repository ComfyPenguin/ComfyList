import 'package:drift/drift.dart';

/// Borrados que no se pudieron quitar de la papelera (se cayó la red justo
/// después de restaurarlos). Viven en local para reintentarlos aunque la app se
/// cierre por medio: en Firestore los documentos ya están de vuelta, así que
/// solo queda tirar sus filas.
@DataClassName('TrashPendingRow')
class TrashPendingTable extends Table {
  TextColumn get uid => text()();

  /// Id del documento en `users/{uid}/trash`.
  TextColumn get docId => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uid, docId};
}
