import 'package:comfy_list/shared/core/theme/app_spacing.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  /// Igual, pero para un aviso con acción: aguanta 8 s en pantalla.
  Future<void> settleToastAwayWithAction(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 9));
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

  testWidgets('un mensaje largo en pantalla estrecha no desborda', (
    tester,
  ) async {
    // 320 x 640 lógicos: lo más estrecho que se sigue usando.
    tester.view.physicalSize = const Size(960, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final context = await pumpHost(tester);
    const message = 'Sigue bloqueado: actívalos en los ajustes del sistema.';

    AppToast.show(context, message);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Un desborde llega aquí como excepción: no haberla es la comprobación.
    expect(tester.takeException(), isNull);
    // Y el aviso cabe entero dentro de la pantalla, sin cortarse por abajo.
    final screen = tester.getSize(find.byType(Scaffold));
    final toast = tester.getRect(find.text(message));
    expect(toast.bottom, lessThanOrEqualTo(screen.height));

    await settleToastAway(tester);
  });

  testWidgets('el aviso con acción también cabe en pantalla estrecha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final context = await pumpHost(tester);

    AppToast.showUndo(
      context,
      message: AppToast.appointmentDeleted,
      onUndo: () async => true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    final screen = tester.getSize(find.byType(Scaffold));
    // El mensaje cede el ancho que necesita la acción en vez de empujarla fuera.
    expect(
      tester.getRect(find.text(AppToast.undo)).right,
      lessThanOrEqualTo(screen.width - AppSpacing.lg),
    );

    await settleToastAwayWithAction(tester);
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

  testWidgets('el texto no hereda el subrayado de error del overlay', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    AppToast.show(context, 'Lista eliminada.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Fuera de un Material, el overlay raíz hereda el estilo de error de
    // Flutter: subrayado doble en amarillo bajo el texto.
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Lista eliminada.'),
    );
    expect(paragraph.text.style?.decoration, isNot(TextDecoration.underline));

    await settleToastAway(tester);
  });

  testWidgets('con «Deshacer» aguanta más tiempo en pantalla', (tester) async {
    final context = await pumpHost(tester);
    var undone = false;

    AppToast.showUndo(
      context,
      message: AppToast.todoDeleted,
      onUndo: () async {
        undone = true;
        return true;
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppToast.undo), findsOneWidget);
    // A los 3 s sigue ahí: hay tiempo para decidir.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(AppToast.todoDeleted), findsOneWidget);

    await tester.tap(find.text(AppToast.undo));
    await tester.pump();

    expect(undone, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text(AppToast.todoDeleted), findsNothing);
  });

  testWidgets('la acción es texto pulsable, separado del mensaje', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    AppToast.showUndo(
      context,
      message: AppToast.todoDeleted,
      onUndo: () async => true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Icono y texto sin relleno, pero con respuesta al tacto: Material + InkWell.
    final action = find.ancestor(
      of: find.text(AppToast.undo),
      matching: find.byType(InkWell),
    );
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(32));
    // El icono va delante de la etiqueta, dentro de la acción.
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(
      tester.getRect(find.byIcon(Icons.undo_rounded)).right,
      lessThan(tester.getRect(find.text(AppToast.undo)).left),
    );

    // Y una línea fina entre los dos bloques, al alto del texto: no llega a
    // cruzar el aviso de arriba abajo.
    final separator = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 1,
    );
    expect(separator, findsOneWidget);
    expect(
      tester.getRect(separator).height,
      lessThan(tester.getSize(action).height),
    );

    await settleToastAwayWithAction(tester);
  });

  testWidgets('si no se puede deshacer, lo dice en otro aviso', (tester) async {
    final context = await pumpHost(tester);

    AppToast.showUndo(
      context,
      message: AppToast.todoDeleted,
      onUndo: () async => false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text(AppToast.undo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppToast.undoFailed), findsOneWidget);

    await settleToastAway(tester);
    expect(find.text(AppToast.undoFailed), findsNothing);
  });

  testWidgets('con acción, tocar fuera del botón la ejecuta igual', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    var undone = false;

    AppToast.showUndo(
      context,
      message: AppToast.todoDeleted,
      onUndo: () async {
        undone = true;
        return true;
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Toda la tarjeta es la zona táctil (y pasa del mínimo de 48): el botón es
    // pequeño y un toque al lado no puede llevarse el aviso por delante.
    final card = find
        .ancestor(
          of: find.text(AppToast.todoDeleted),
          matching: find.byType(Material),
        )
        .first;
    expect(tester.getSize(card).height, greaterThanOrEqualTo(48));

    await tester.tap(find.text(AppToast.todoDeleted));
    await tester.pump();

    expect(undone, isTrue);
  });

  testWidgets('tocar fuera lo descarta y el toque llega a lo de debajo', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => taps++,
              child: const SizedBox(
                width: 200,
                height: 200,
                child: Text('Fila'),
              ),
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));

    AppToast.showUndo(
      context,
      message: AppToast.todoDeleted,
      onUndo: () async => true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text(AppToast.todoDeleted), findsOneWidget);

    await tester.tap(find.text('Fila'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text(AppToast.todoDeleted), findsNothing);
    expect(taps, 1);
  });

  testWidgets('sale en la franja de la barra, no debajo', (tester) async {
    final context = await pumpHost(tester);

    AppToast.show(context, 'Tarea eliminada.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // La barra del shell ocupa los primeros 56 px bajo el área segura.
    expect(tester.getTopLeft(find.byType(DecoratedBox).last).dy, lessThan(56));

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
