import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ no llama a debugPrint fuera de debug_log.dart', () {
    final call = RegExp(r'\bdebugPrint\s*\(');
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      if (path.endsWith('lib/shared/core/logging/debug_log.dart')) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (call.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Usa debugLog: debugPrint escribe en release',
    );
  });
}
