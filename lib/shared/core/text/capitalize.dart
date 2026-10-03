/// Devuelve [value] con la inicial en mayúscula.
///
/// En español `DateFormat` da los nombres de día y mes en minúscula, así que
/// los textos de fecha de la app los suben con esto.
String capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
