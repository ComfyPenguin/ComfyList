// Smoke tests sencillos. Los flujos completos (auth + go_router) tienen
// tests de unidad por capa en data/ y domain/.
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme.light() construye un ThemeData válido', () {
    final theme = AppTheme.light();
    expect(theme.brightness, Brightness.light);
    expect(theme.useMaterial3, isTrue);
  });

  test('AppTheme.dark() construye un ThemeData válido', () {
    final theme = AppTheme.dark();
    expect(theme.brightness, Brightness.dark);
  });
}
