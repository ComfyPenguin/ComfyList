import 'dart:async';

import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/lifecycle/polling_registry.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/data/remote/polled_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _tick = Duration(milliseconds: 20);
const _settle = Duration(milliseconds: 70);

DioException _dio(DioExceptionType type, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: status,
            ),
    );

void main() {
  late Map<String, int> fetches;
  late Map<String, List<int>> data;
  late PollingRegistry registry;
  late PolledCollection<String, int> collection;
  final subs = <StreamSubscription<dynamic>>[];

  Future<List<int>> fetch(String key) async {
    fetches[key] = (fetches[key] ?? 0) + 1;
    return data[key] ?? const [];
  }

  List<List<int>> listen(String key) {
    final seen = <List<int>>[];
    subs.add(collection.watch(key).listen(seen.add, onError: (Object _) {}));
    return seen;
  }

  setUp(() {
    fetches = {};
    data = {
      'a': [1],
      'b': [2],
    };
    registry = PollingRegistry();
    collection = PolledCollection<String, int>(
      fetch: fetch,
      interval: _tick,
      registry: registry,
    );
  });

  tearDown(() async {
    for (final sub in subs) {
      await sub.cancel();
    }
    subs.clear();
    collection.dispose();
  });

  group('PolledCollection.watch', () {
    test('does not fetch until someone listens', () async {
      collection.watch('a');
      await Future<void>.delayed(_settle);

      expect(fetches['a'], isNull);
    });

    test('emits the first list right after listening', () async {
      final seen = listen('a');
      await pumpEventQueue();

      expect(seen, [
        [1],
      ]);
    });

    test('fetches again on every tick while listened', () async {
      listen('a');
      await Future<void>.delayed(_settle);

      expect(fetches['a'], greaterThanOrEqualTo(3));
    });

    test('stops polling once the last listener leaves', () async {
      listen('a');
      await pumpEventQueue();
      for (final sub in subs) {
        await sub.cancel();
      }
      subs.clear();
      final before = fetches['a'];

      await Future<void>.delayed(_settle);

      expect(fetches['a'], before);
    });

    test('keys are independent and a key shares one watcher', () async {
      final a1 = listen('a');
      final a2 = listen('a');
      final b = listen('b');
      await pumpEventQueue();

      expect(a1.first, [1]);
      expect(a2.first, [1]);
      expect(b.first, [2]);
      expect(fetches['a'], 1);
      expect(fetches['b'], 1);
    });
  });

  group('PolledCollection.refresh', () {
    test('pushes the new list immediately', () async {
      final seen = listen('a');
      await pumpEventQueue();
      data['a'] = [1, 9];

      await collection.refresh('a');
      await pumpEventQueue();

      expect(seen.last, [1, 9]);
    });

    test('is a no-op for a key nobody watches', () async {
      await collection.refresh('zzz');

      expect(fetches['zzz'], isNull);
    });
  });

  group('PolledCollection.guard', () {
    test('returns Ok(value) and refreshes the key before returning', () async {
      final seen = listen('a');
      await pumpEventQueue();
      data['a'] = [7];

      final res = await collection.guard('a', () async => 'done');
      await pumpEventQueue();

      expect(res, isA<Ok<String>>());
      expect((res as Ok<String>).value, 'done');
      expect(seen.last, [7]);
    });

    test('keeps Ok when the refresh afterwards fails', () async {
      listen('a');
      await pumpEventQueue();
      final failing = PolledCollection<String, int>(
        fetch: (_) async => throw _dio(DioExceptionType.connectionError),
        interval: _tick,
        registry: registry,
      );
      addTearDown(failing.dispose);
      subs.add(failing.watch('a').listen((_) {}, onError: (Object _) {}));
      await pumpEventQueue();

      final res = await failing.guard('a', () async => 1);

      expect(res.isOk, isTrue);
    });

    test('does not refresh when the mutation fails', () async {
      listen('a');
      await pumpEventQueue();
      final before = fetches['a'];

      await collection.guard<void>(
        'a',
        () async => throw _dio(DioExceptionType.connectionError),
      );

      expect(fetches['a'], before);
    });

    final cases = <String, (DioException, Matcher)>{
      'connectionTimeout': (
        _dio(DioExceptionType.connectionTimeout),
        isA<TimeoutFailure>(),
      ),
      'receiveTimeout': (
        _dio(DioExceptionType.receiveTimeout),
        isA<TimeoutFailure>(),
      ),
      'sendTimeout': (
        _dio(DioExceptionType.sendTimeout),
        isA<TimeoutFailure>(),
      ),
      'connectionError': (
        _dio(DioExceptionType.connectionError),
        isA<NetworkFailure>(),
      ),
      '401': (
        _dio(DioExceptionType.badResponse, status: 401),
        isA<AuthFailure>(),
      ),
      '403': (
        _dio(DioExceptionType.badResponse, status: 403),
        isA<AuthFailure>(),
      ),
      '404': (
        _dio(DioExceptionType.badResponse, status: 404),
        isA<NotFoundFailure>(),
      ),
      '500': (
        _dio(DioExceptionType.badResponse, status: 500),
        isA<ServerFailure>(),
      ),
    };
    cases.forEach((name, spec) {
      test('maps $name to the matching Failure', () async {
        final res = await collection.guard<void>('a', () async => throw spec.$1);

        expect((res as Err<void>).failure, spec.$2);
      });
    });

    test('lets non-Dio errors through', () async {
      expect(
        collection.guard<void>('a', () async => throw StateError('bug')),
        throwsStateError,
      );
    });
  });

  group('PolledCollection.read', () {
    test('returns Ok(value) without refreshing', () async {
      listen('a');
      await pumpEventQueue();
      final before = fetches['a'];

      final res = await collection.read(() async => 5);

      expect((res as Ok<int>).value, 5);
      expect(fetches['a'], before);
    });

    test('maps Dio errors to Err', () async {
      final res = await collection.read<int>(
        () async => throw _dio(DioExceptionType.connectionError),
      );

      expect((res as Err<int>).failure, isA<NetworkFailure>());
    });
  });

  group('PolledCollection with the PollingRegistry', () {
    test('pause stops polling and resume fetches at once and keeps going',
        () async {
      listen('a');
      await pumpEventQueue();

      registry.pause();
      final paused = fetches['a'];
      await Future<void>.delayed(_settle);
      expect(fetches['a'], paused);

      registry.resume();
      await pumpEventQueue();
      expect(fetches['a'], paused! + 1);

      await Future<void>.delayed(_settle);
      expect(fetches['a'], greaterThan(paused + 1));
    });

    test('dispose closes the streams and leaves the registry', () async {
      var done = false;
      subs.add(collection.watch('a').listen((_) {}, onDone: () => done = true));
      await pumpEventQueue();

      collection.dispose();
      await pumpEventQueue();
      final after = fetches['a'];
      registry.resume();
      await Future<void>.delayed(_settle);

      expect(done, isTrue);
      expect(fetches['a'], after);
    });
  });
}
