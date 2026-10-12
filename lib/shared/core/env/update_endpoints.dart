/// Endpoints de las releases de GitHub que consulta el comprobador de
/// actualizaciones.
///
/// Van sin token (el repo es público), así que la API limita a 60 peticiones
/// por hora y por IP — de sobra: la app pregunta una vez al día.
class UpdateEndpoints {
  UpdateEndpoints._();

  static const String repository = 'ComfyPenguin/ComfyList';

  static const String latestReleaseUrl =
      'https://api.github.com/repos/$repository/releases/latest';
}
