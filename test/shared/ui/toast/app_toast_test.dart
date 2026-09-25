import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Monta un host con la estética de la app y devuelve su contexto.
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    return tester.element(find.byType(Scaffold));
  }

  /// Avanza lo justo para que el aviso termine de salir: dispara el temporizador
  /// que lo oculta, deja acabar la animación de salida y retira el overlay.
  Future<void> settleToastAway(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  testWidgets('muestra el mensaje arriba y se va solo', (tester) async {
    final context = await pumpHost(tester);

    AppToast.show(context, 'Lista «Compras» eliminada.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Lista «Compras» eliminada.'), findsOneWidget);
    // Arriba: deja libre el borde inferior, donde viven la BottomBar y el FAB.
    final screen = tester.getSize(find.byType(Scaffold));
    expect(
      tester.getCenter(find.text('Lista «Compras» eliminada.')).dy,
      lessThan(screen.height / 2),
    );

    await settleToastAway(tester);

    expect(find.text('Lista «Compras» eliminada.'), findsNothing);
  });

  testWidgets('un aviso nuevo reemplaza al anterior', (tester) async {
    final context = await pumpHost(tester);

    AppToast.show(context, 'Primero');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Primero'), findsOneWidget);

    AppToast.show(context, 'Segundo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Segundo'), findsOneWidget);
    expect(find.text('Primero'), findsNothing);

    await settleToastAway(tester);
  });

  testWidgets('tocarlo lo descarta antes de tiempo', (tester) async {
    final context = await pumpHost(tester);

    AppToast.show(context, 'Tarea eliminada.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Tarea eliminada.'), findsOneWidget);

    await tester.tap(find.text('Tarea eliminada.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Tarea eliminada.'), findsNothing);
  });
}
