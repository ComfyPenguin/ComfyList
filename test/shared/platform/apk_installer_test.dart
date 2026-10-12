import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/platform/apk_installer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const installer = ApkInstaller();
  const channel = MethodChannel(ApkInstaller.channelName);
  final calls = <MethodCall>[];

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void stubChannel(Future<Object?> Function(MethodCall call) handler) {
    calls.clear();
    messenger().setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  tearDown(() => messenger().setMockMethodCallHandler(channel, null));

  test('manda la ruta del APK al canal nativo', () async {
    stubChannel((_) async => null);

    final result = await installer.install('/tmp/comfylist-2026.10.11.231.apk');

    expect(result.isOk, isTrue);
    expect(calls.single.method, 'installApk');
    expect(calls.single.arguments, {'path': '/tmp/comfylist-2026.10.11.231.apk'});
  });

  test('sin permiso para instalar lo explica en vez de fallar en silencio', () async {
    stubChannel(
      (_) async => throw PlatformException(code: 'unknownSources'),
    );

    final result = await installer.install('/tmp/a.apk');

    expect(result, isA<Err<void>>());
    expect(
      (result as Err<void>).failure.message,
      contains('apps desconocidas'),
    );
  });

  test('si el APK ya no está, lo dice', () async {
    stubChannel((_) async => throw PlatformException(code: 'noFile'));

    final result = await installer.install('/tmp/a.apk');

    expect((result as Err<void>).failure.message, contains('ya no está'));
  });

  test('donde no existe el canal no se rompe nada', () async {
    // Sin handler registrado, el canal no existe: es lo que pasa fuera de
    // Android.
    final result = await installer.install('/tmp/a.apk');

    expect(result, isA<Err<void>>());
    expect(
      (result as Err<void>).failure.message,
      contains('no sabe instalar'),
    );
  });
}
