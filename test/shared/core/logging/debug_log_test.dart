import 'package:comfy_list/shared/core/logging/debug_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reenvía el mensaje a debugPrint', () {
    final messages = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => messages.add(message);
    addTearDown(() => debugPrint = original);

    debugLog('hola');

    expect(messages, ['hola']);
  });
}
