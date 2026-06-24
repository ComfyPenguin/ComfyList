import 'package:flutter/material.dart';

/// Catálogo cerrado de iconos disponibles para las listas.
///
/// Usamos un mapa de claves simbólicas → [IconData] constantes para que
/// Flutter pueda tree-shakear los iconos no usados (a diferencia de
/// instanciar IconData con codePoints dinámicos).
class TodoListIcons {
  TodoListIcons._();

  static const String defaultKey = 'inbox';

  static const Map<String, IconData> all = {
    'inbox': Icons.inbox_outlined,
    'home': Icons.home_outlined,
    'work': Icons.work_outline,
    'cart': Icons.shopping_cart_outlined,
    'travel': Icons.flight_takeoff_outlined,
    'fitness': Icons.fitness_center_outlined,
    'book': Icons.menu_book_outlined,
    'star': Icons.star_outline,
    'heart': Icons.favorite_outline,
    'school': Icons.school_outlined,
    'gift': Icons.card_giftcard_outlined,
    'lightbulb': Icons.lightbulb_outline,
  };

  /// Devuelve el icono asociado o el por defecto si la clave no existe.
  static IconData resolve(String key) =>
      all[key] ?? all[defaultKey]!;
}
