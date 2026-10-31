import 'dart:async';

import 'package:flutter/foundation.dart';

/// Retiene un momento el orden de una lista cuando el cambio de un único
/// elemento la reordenaría, para que su animación (el tachado de una tarea
/// completada) se vea en el sitio donde se hizo el gesto y no en el que caerá.
///
/// En cada build la pantalla llama a [resolve] con los elementos y el orden que
/// querría; si hay que retener, devuelve el orden que ya se estaba enseñando y
/// avisa con [onRelease] cuando pasa [delay], para que la pantalla se vuelva a
/// pintar con el orden bueno.
class HeldReorder<T> {
  HeldReorder({
    required this.idOf,
    required this.flagOf,
    required this.onRelease,
    this.delay = const Duration(milliseconds: 600),
  });

  /// Id estable de un elemento.
  final String Function(T item) idOf;

  /// Lo que cambia en el elemento que dispara la retención (p. ej. `isDone`).
  final bool Function(T item) flagOf;

  /// Se llama al terminar la retención.
  final VoidCallback onRelease;

  /// Cuánto se retiene el orden anterior.
  final Duration delay;

  List<String>? _displayedIds;
  List<T>? _lastItems;
  bool _holding = false;
  Timer? _timer;

  /// Orden a enseñar. [items] son los elementos tal como llegan y [desired] el
  /// mismo conjunto en el orden que se querría.
  ///
  /// Se retiene cuando exactamente un elemento cambia de [flagOf] desde la
  /// última llamada y eso reordenaría la lista. Una alta o una baja corta la
  /// retención: se reordena en el acto.
  List<T> resolve({required List<T> items, required List<T> desired}) {
    final currentIds = [for (final item in items) idOf(item)];
    final previous = _lastItems;
    _lastItems = items;

    final toggled = previous != null && _exactlyOneFlipped(previous, items);
    final canKeepLayout =
        _displayedIds != null && _sameIdSet(_displayedIds!, currentIds);
    final desiredIds = [for (final item in desired) idOf(item)];
    final wouldReorder =
        toggled && canKeepLayout && !listEquals(_displayedIds, desiredIds);

    if (wouldReorder && !_holding) {
      _holding = true;
      _timer?.cancel();
      _timer = Timer(delay, () {
        _holding = false;
        onRelease();
      });
    }

    if (_holding) {
      if (canKeepLayout) {
        final byId = {for (final item in items) idOf(item): item};
        return [for (final id in _displayedIds!) byId[id]!];
      }
      // El conjunto de ids cambió (alta/baja): reordenar ya.
      _holding = false;
      _timer?.cancel();
      _timer = null;
    }

    _displayedIds = desiredIds;
    return desired;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  bool _exactlyOneFlipped(List<T> previous, List<T> items) {
    final before = {for (final item in previous) idOf(item): flagOf(item)};
    var flips = 0;
    for (final item in items) {
      final was = before[idOf(item)];
      if (was != null && was != flagOf(item)) flips++;
    }
    return flips == 1;
  }

  /// Compara como conjunto, sin importar el orden: solo cuenta que no haya
  /// altas ni bajas.
  bool _sameIdSet(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final bSet = b.toSet();
    return a.every(bSet.contains);
  }
}
