import 'package:comfy_list/features/appointments/domain/entities/repeat_rule.dart';
import 'package:comfy_list/features/appointments/presentation/widgets/repeat_rule_picker.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pantalla mínima con un botón que abre el selector con la regla que le den.
class _Host extends StatelessWidget {
  const _Host({required this.initial});

  final RepeatRule initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showRepeatRulePicker(context, initial: initial),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  Future<void> open(WidgetTester tester, RepeatRule initial) async {
    await tester.pumpWidget(_Host(initial: initial));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('el título pide «Repetir cada»', (tester) async {
    await open(tester, const RepeatRule(interval: 2, unit: RepeatUnit.day));

    expect(find.text('Repetir cada'), findsOneWidget);
  });

  testWidgets('con cantidad 1 las unidades van en singular', (tester) async {
    await open(tester, const RepeatRule(interval: 1, unit: RepeatUnit.day));

    expect(find.text('día'), findsOneWidget);
    expect(find.text('semana'), findsOneWidget);
    expect(find.text('días'), findsNothing);
    expect(find.text('semanas'), findsNothing);
  });

  testWidgets('con otra cantidad van en plural', (tester) async {
    await open(tester, const RepeatRule(interval: 2, unit: RepeatUnit.week));

    expect(find.text('días'), findsOneWidget);
    expect(find.text('semanas'), findsOneWidget);
    expect(find.text('día'), findsNothing);
  });

  testWidgets('al mover la cantidad a 1 las unidades pasan a singular', (
    tester,
  ) async {
    await open(tester, const RepeatRule(interval: 2, unit: RepeatUnit.day));
    expect(find.text('días'), findsOneWidget);

    // Un paso abajo en la rueda de la cantidad deja el 1.
    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, 44),
    );
    await tester.pumpAndSettle();

    expect(find.text('día'), findsOneWidget);
    expect(find.text('días'), findsNothing);
  });
}
