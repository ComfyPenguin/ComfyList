import 'package:drift/drift.dart';

/// Tabla singleton (id=1) con la configuración local de la app.
@DataClassName('SettingsRow')
class SettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// 'system' | 'light' | 'dark'
  TextColumn get themeMode =>
      text().withDefault(const Constant('system')).withLength(min: 4, max: 8)();

  /// Los avisos vienen apagados de fábrica: el permiso del sistema se pide al
  /// encenderlos (ver `NotificationsService`).
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Si `true`, las tareas completadas van al final de la lista.
  BoolColumn get completedToBottom =>
      boolean().withDefault(const Constant(true))();

  /// Si `true`, las citas completadas van al final de la lista de su día.
  BoolColumn get appointmentsCompletedToBottom =>
      boolean().withDefault(const Constant(true))();

  /// Si `true`, el día de hoy va primero en la lista de citas, aunque haya
  /// días pasados por delante.
  BoolColumn get appointmentsTodayOnTop =>
      boolean().withDefault(const Constant(true))();

  /// Si `true`, las acciones del deslizamiento se invierten: eliminar queda
  /// a la izquierda y completar a la derecha (y viceversa en `false`).
  BoolColumn get invertSwipeActions =>
      boolean().withDefault(const Constant(false))();

  /// Si `true`, las horas de las citas se muestran en formato 24H.
  /// Si `false`, se muestran en formato 12H con AM/PM.
  BoolColumn get use24HourFormat =>
      boolean().withDefault(const Constant(true))();

  /// Minutos de antelación de los recordatorios de una cita (0 = a su hora),
  /// separados por comas y como mucho tres. Un valor vacío es «sin avisos».
  TextColumn get appointmentReminderMinutes =>
      text().withDefault(const Constant('30'))();

  /// Si `true`, ya se mostró la pista de mantener pulsada una tarjeta para
  /// editarla y no vuelve a aparecer.
  BoolColumn get longPressHintSeen =>
      boolean().withDefault(const Constant(false))();

  /// Días que aguanta un borrado en la papelera antes de que la app la vacíe
  /// sola. `0` es «nunca»; de fábrica, un mes.
  IntColumn get trashRetentionDays =>
      integer().withDefault(const Constant(30))();

  /// Nº de build que se descartó con «Ahora no»: sin recordarlo, el aviso de
  /// versión nueva volvería en cada arranque. `0` es «ninguna».
  IntColumn get skippedUpdateBuild =>
      integer().withDefault(const Constant(0))();

  /// Última comprobación de versiones, para no preguntar a GitHub en cada
  /// arranque.
  DateTimeColumn get lastUpdateCheckAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
