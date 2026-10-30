/// Cuánto lleva deslizada cada tarjeta de una lista unida (de 0 a 1), y con
/// ello cuánto se separan de sus vecinas.
///
/// Las tarjetas de una lista van pegadas y redondean sus esquinas contra la
/// vecina. Al deslizar una, los dos bordes que la tocan se separan en
/// proporción a lo que se ha deslizado; cada pantalla de lista lleva un
/// [RevealProgress] y avisa con `setState` cuando [set] cambia algo.
class RevealProgress {
  /// Por debajo de esto una tarjeta cuenta como no deslizada.
  static const double _epsilon = 0.001;

  final Map<String, double> _byId = {};

  /// Anota el progreso de la tarjeta [id], recortado a [0, 1]. Si es
  /// prácticamente cero, la olvida.
  void set(String id, double progress) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    if (value <= _epsilon) {
      _byId.remove(id);
    } else {
      _byId[id] = value;
    }
  }

  /// Olvida las tarjetas que ya no se ven.
  void retainOnly(Iterable<String> visibleIds) {
    final visible = visibleIds.toSet();
    _byId.removeWhere((id, _) => !visible.contains(id));
  }

  /// Separación de los bordes superior e inferior de la tarjeta [id]: el mayor
  /// progreso entre ella y su vecina de ese lado. [previousId] y [nextId] son
  /// `null` en los extremos de la lista.
  ({double top, double bottom}) separationFor(
    String id, {
    String? previousId,
    String? nextId,
  }) {
    if (_byId.isEmpty) return (top: 0.0, bottom: 0.0);

    final mine = _byId[id] ?? 0.0;
    final previous = previousId == null ? 0.0 : (_byId[previousId] ?? 0.0);
    final next = nextId == null ? 0.0 : (_byId[nextId] ?? 0.0);
    return (
      top: mine > previous ? mine : previous,
      bottom: mine > next ? mine : next,
    );
  }
}
