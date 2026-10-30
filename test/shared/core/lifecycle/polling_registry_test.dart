import 'package:comfy_list/shared/core/lifecycle/polling_registry.dart';
import 'package:flutter_test/flutter_test.dart';

class _Member implements PollingMember {
  final List<String> calls = [];

  @override
  void pause() => calls.add('pause');

  @override
  void resume() => calls.add('resume');
}

class _SelfRemoving extends _Member {
  _SelfRemoving(this.registry);

  final PollingRegistry registry;

  @override
  void pause() {
    super.pause();
    registry.unregister(this);
  }
}

void main() {
  late PollingRegistry registry;

  setUp(() => registry = PollingRegistry());

  group('PollingRegistry', () {
    test('pause and resume reach every registered member', () {
      final a = _Member();
      final b = _Member();
      registry
        ..register(a)
        ..register(b);

      registry.pause();
      registry.resume();

      expect(a.calls, ['pause', 'resume']);
      expect(b.calls, ['pause', 'resume']);
    });

    test('isPaused follows pause and resume', () {
      expect(registry.isPaused, isFalse);

      registry.pause();
      expect(registry.isPaused, isTrue);

      registry.resume();
      expect(registry.isPaused, isFalse);
    });

    test('a member registered while paused sees isPaused and is not resumed '
        'until resume', () {
      registry.pause();
      final late = _Member();

      registry.register(late);

      expect(registry.isPaused, isTrue);
      expect(late.calls, isEmpty);

      registry.resume();
      expect(late.calls, ['resume']);
    });

    test('an unregistered member is no longer reached', () {
      final a = _Member();
      registry.register(a);

      registry.unregister(a);
      registry.pause();

      expect(a.calls, isEmpty);
    });

    test('registering twice does not duplicate calls', () {
      final a = _Member();
      registry
        ..register(a)
        ..register(a);

      registry.pause();

      expect(a.calls, ['pause']);
    });

    test('a member that unregisters itself while pausing does not break '
        'the others', () {
      final remover = _SelfRemoving(registry);
      final other = _Member();
      registry
        ..register(remover)
        ..register(other);

      registry.pause();

      expect(remover.calls, ['pause']);
      expect(other.calls, ['pause']);
    });
  });
}
