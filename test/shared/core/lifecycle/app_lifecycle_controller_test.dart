import 'package:comfy_list/shared/core/lifecycle/app_lifecycle_controller.dart';
import 'package:comfy_list/shared/core/lifecycle/polling_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Member implements PollingMember {
  final List<String> calls = [];

  @override
  void pause() => calls.add('pause');

  @override
  void resume() => calls.add('resume');
}

void main() {
  late ProviderContainer container;
  late _Member member;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    container = ProviderContainer();
    member = _Member();
    container.read(pollingRegistryProvider).register(member);
    container.read(appLifecycleControllerProvider);
  });

  tearDown(() => container.dispose());

  void emit(AppLifecycleState state) =>
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(state);

  test('pauses the registry when the app goes to background', () {
    emit(AppLifecycleState.inactive);
    expect(member.calls, isEmpty);

    emit(AppLifecycleState.hidden);
    expect(member.calls, ['pause']);
  });

  test('resumes the registry when the app comes back', () {
    emit(AppLifecycleState.inactive);
    emit(AppLifecycleState.hidden);
    emit(AppLifecycleState.paused);
    member.calls.clear();

    emit(AppLifecycleState.hidden);
    emit(AppLifecycleState.inactive);
    emit(AppLifecycleState.resumed);

    // Al volver, el sistema pasa por `hidden` (que pausa de nuevo): lo que
    // cuenta es que el último aviso sea la reanudación.
    expect(member.calls.last, 'resume');
  });
}
