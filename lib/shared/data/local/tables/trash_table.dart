import 'package:drift/drift.dart';

/// Papelera local: guarda lo que se borra en la app para poder devolverlo.
///
/// Vive solo en el dispositivo (no se sube a Firestore) y es por cuenta: al
/// cerrar sesión no se mezclan los borrados de dos usuarios.
@DataClassName('TrashRow')
class TrashTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uid => text()();

  /// Agrupa lo que se borró de una vez: una lista se lleva sus tareas, así que
  /// comparten grupo para poder devolverlo todo junto.
  TextColumn get groupId => text()();

  /// 'list' | 'todo' | 'appointment'
  TextColumn get kind => text()();

  /// Id que el documento tenía en Firestore, para devolverlo con el mismo.
  TextColumn get itemId => text()();

  /// Lista a la que pertenece una tarea; `null` en listas y citas.
  TextColumn get parentId => text().nullable()();

  /// Lo que enseña la papelera: nombre de la lista o título del elemento.
  TextColumn get label => text()();

  /// Entidad serializada tal y como estaba antes de borrarse.
  TextColumn get payload => text()();

  DateTimeColumn get deletedAt => dateTime()();
}
