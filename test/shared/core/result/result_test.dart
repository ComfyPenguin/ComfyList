import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result.fold', () {
    test('Ok aplica onOk con el valor', () {
      const result = Ok<int>(42);
      final folded = result.fold(
        onOk: (v) => 'ok=$v',
        onErr: (_) => 'err',
      );
      expect(folded, 'ok=42');
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
    });

    test('Err aplica onErr con el failure', () {
      const result = Err<int>(NetworkFailure());
      final folded = result.fold(
        onOk: (_) => 'ok',
        onErr: (f) => 'err=${f.runtimeType}',
      );
      expect(folded, 'err=NetworkFailure');
      expect(result.isErr, isTrue);
    });
  });
}
