import 'package:comfy_list/shared/platform/screen_security.dart';
import 'package:comfy_list/shared/ui/secure_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(ScreenSecurity.channelName),
      (call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(ScreenSecurity.channelName),
      null,
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SecureScreen(child: Scaffold(body: SizedBox.shrink())),
      ),
    );
    await tester.pump();
  }

  testWidgets('pide blindar la pantalla al montarse', (tester) async {
    await pumpScreen(tester);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'setSecure');
    expect(calls.single.arguments, {'secure': true});
  });

  testWidgets('levanta el blindaje al desmontarse', (tester) async {
    await pumpScreen(tester);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(calls.map((c) => c.arguments), [
      {'secure': true},
      {'secure': false},
    ]);
  });

  testWidgets('sin canal (otras plataformas) no revienta', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(ScreenSecurity.channelName),
      null,
    );

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
  });
}
