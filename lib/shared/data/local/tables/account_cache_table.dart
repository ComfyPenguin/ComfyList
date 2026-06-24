import 'package:drift/drift.dart';

/// Cache local del perfil del usuario autenticado (no es la fuente de verdad
/// — esa es Identity Toolkit). Sirve para mostrar email/nombre offline.
@DataClassName('AccountCacheRow')
class AccountCacheTable extends Table {
  TextColumn get uid => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uid};
}
