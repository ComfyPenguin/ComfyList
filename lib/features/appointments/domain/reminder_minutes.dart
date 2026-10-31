/// Cuántos recordatorios puede llevar una cita.
const int maxAppointmentReminders = 5;

/// Márgenes con los que avisa una cita recién creada, y los que se les suponen
/// a las citas guardadas antes de que cada una llevara los suyos.
const List<int> defaultReminderMinutes = [30];

/// Margen de un aviso que ofrece el selector de una cita, en minutos antes de
/// la hora.
///
/// Lo que no salga de aquí se elige a mano en la rueda del personalizado.
enum AppointmentReminderPreset {
  atTime(0),
  fiveMinutes(5),
  tenMinutes(10),
  fifteenMinutes(15),
  thirtyMinutes(30),
  oneHour(60),
  oneDay(1440);

  const AppointmentReminderPreset(this.minutes);

  final int minutes;
}

/// Forma canónica de los márgenes de una cita, en minutos antes de su hora (0 =
/// a su hora): sin repetidos, de menor a mayor y como mucho
/// [maxAppointmentReminders]. Al recortar al máximo se quedan los más cercanos a
/// la cita, que son los que primero suenan.
List<int> normalizeReminderMinutes(Iterable<int> minutes) {
  final canonical = minutes.where((lead) => lead >= 0).toSet().toList()..sort();
  return canonical.length > maxAppointmentReminders
      ? canonical.sublist(0, maxAppointmentReminders)
      : canonical;
}

/// Márgenes tal como se guardan: la lista canónica separada por comas. Sin
/// márgenes es el texto vacío.
String reminderMinutesToString(List<int> minutes) =>
    normalizeReminderMinutes(minutes).join(',');

/// Márgenes guardados. El texto vacío es «sin avisos» y lo que no se pueda leer
/// se descarta.
List<int> parseReminderMinutes(String value) => normalizeReminderMinutes(
  value.split(',').map(int.tryParse).whereType<int>(),
);

/// Márgenes de [minutes] con [lead] añadido, en su forma canónica.
List<int> addReminderMinutes(List<int> minutes, int lead) =>
    normalizeReminderMinutes([...minutes, lead]);

/// Márgenes de [minutes] sin [lead].
List<int> removeReminderMinutes(List<int> minutes, int lead) =>
    minutes.where((minutes) => minutes != lead).toList();
