import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/core/theme/app_typography.dart';
import 'package:comfy_list/shared/ui/animations/unfold_down.dart';
import 'package:comfy_list/shared/ui/buttons/primary_button.dart';
import 'package:comfy_list/shared/ui/cards/app_card.dart';
import 'package:comfy_list/shared/ui/inputs/app_chip.dart';
import 'package:comfy_list/shared/ui/inputs/app_segmented_control.dart';
import 'package:comfy_list/shared/ui/inputs/app_switch.dart';
import 'package:comfy_list/shared/ui/inputs/app_text_field.dart';
import 'package:comfy_list/shared/ui/text/animated_strikethrough_text.dart';
import 'package:comfy_list/shared/ui/text/app_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los widgets del DS miden lo que miden: con el alto libre (una `Column`, que
/// es como los monta la app) y con el alto acotado pero holgado (un `Center` a
/// pantalla completa) el alto es el mismo.
///
/// Lo que vigila es un `Center`/`Align` que se estira, que es el fallo silencioso
/// de este árbol: un `Align` sin factores ocupa todo el alto disponible, así que
/// un widget que debía medir su contenido se estira con el hueco.
void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );

  Future<void> expectNoVerticalStretch(
    WidgetTester tester,
    String name,
    Widget Function(Key key) build,
  ) async {
    final key = ValueKey(name);

    await tester.pumpWidget(
      harness(Column(mainAxisSize: MainAxisSize.min, children: [build(key)])),
    );
    final free = tester.getSize(find.byKey(key)).height;

    await tester.pumpWidget(harness(Center(child: build(key))));
    final bounded = tester.getSize(find.byKey(key)).height;

    expect(
      bounded,
      free,
      reason: '$name se estira a lo alto cuando el hueco está acotado',
    );
  }

  final widgets = <String, Widget Function(Key key)>{
    'PrimaryButton': (key) =>
        PrimaryButton(key: key, label: 'Añadir', onPressed: () {}),
    'PrimaryButton dense': (key) =>
        PrimaryButton(key: key, label: 'Añadir', onPressed: () {}, dense: true),
    'AppChip': (key) => AppChip(key: key, label: '45 min', onDelete: () {}),
    'AppSwitch': (key) => AppSwitch(key: key, value: true, onChanged: (_) {}),
    'AppSegmentedControl': (key) => AppSegmentedControl<String>(
      key: key,
      options: const [
        AppSegmentOption(value: '12', label: '12 h'),
        AppSegmentOption(value: '24', label: '24 h'),
      ],
      selectedIndex: 0,
      onSelected: (_) {},
    ),
    'AppTag': (key) => AppTag(key: key, label: 'Hoy'),
    'AppCard': (key) => AppCard(key: key, child: const Text('Contenido')),
    'AppTextField': (key) => AppTextField(key: key, hint: 'Escribe aquí'),
    'AnimatedStrikethroughText': (key) => AnimatedStrikethroughText(
      key: key,
      text: 'Hecho',
      style: AppTypography.bodyMd,
      done: true,
    ),
    'UnfoldDown': (key) =>
        UnfoldDown(key: key, open: true, child: const Text('Contenido')),
  };

  for (final entry in widgets.entries) {
    testWidgets('${entry.key} no se estira a lo alto', (tester) async {
      await expectNoVerticalStretch(tester, entry.key, entry.value);
    });
  }

  /// Ancho del hueco de un `Column` en la pantalla del test, que es todo el que
  /// hay: un widget que mida su contenido tiene que quedarse muy por debajo.
  const slotWidth = 800.0;

  /// Los que miden su contenido tampoco pueden llenar el ancho: el `Column` les
  /// da el ancho máximo sin apretarlos, así que un `Align` sin `widthFactor`
  /// dentro los estira hasta el borde.
  ///
  /// El control segmentado no está aquí a propósito: llena la fila, que es lo
  /// que se le pide.
  final hugWidth = <String, Widget Function(Key key)>{
    'PrimaryButton': (key) =>
        PrimaryButton(key: key, label: 'Editar', onPressed: () {}),
    'PrimaryButton dense': (key) =>
        PrimaryButton(key: key, label: 'Añadir', onPressed: () {}, dense: true),
    'AppChip': (key) => AppChip(key: key, label: '45 min', onDelete: () {}),
    'AppSwitch': (key) => AppSwitch(key: key, value: true, onChanged: (_) {}),
    'AppTag': (key) => AppTag(key: key, label: 'Hoy'),
  };

  for (final entry in hugWidth.entries) {
    testWidgets('${entry.key} mide su contenido a lo ancho', (tester) async {
      final key = ValueKey(entry.key);
      await tester.pumpWidget(harness(Column(children: [entry.value(key)])));

      expect(tester.getSize(find.byKey(key)).width, lessThan(slotWidth));
    });
  }
}
