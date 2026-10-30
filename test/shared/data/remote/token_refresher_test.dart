import 'dart:async';

import 'package:comfy_list/shared/data/remote/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/dio_mock.dart';
import '../../../helpers/provider_scope.dart';

void main() {
  late MockSecureSessionStore session;
  late MockDio client;
  late TokenRefresher refresher;

  setUp(() {
    session = MockSecureSessionStore();
    client = MockDio();
    refresher = TokenRefresher(session: session, client: client);

    when(() => session.readRefreshToken())
        .thenAnswer((_) async => 'old-refresh');
    when(() => session.readUid()).thenAnswer((_) async => 'u-1');
    when(() => session.readIdToken()).thenAnswer((_) async => 'old-id');
    when(() => session.saveSession(
          idToken: any(named: 'idToken'),
          refreshToken: any(named: 'refreshToken'),
          uid: any(named: 'uid'),
        )).thenAnswer((_) async {});
    when(() => session.updateIdToken(any())).thenAnswer((_) async {});
  });

  DioException failure({int? status, DioExceptionType? type}) {
    final options = RequestOptions(path: '');
    return DioException(
      requestOptions: options,
      type: type ?? DioExceptionType.badResponse,
      response: status == null
          ? null
          : Response<dynamic>(requestOptions: options, statusCode: status),
    );
  }

  void stubRefreshThrows(DioException e) {
    when(() => client.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(e);
  }

  void verifyNothingSaved() {
    verifyNever(() => session.saveSession(
          idToken: any(named: 'idToken'),
          refreshToken: any(named: 'refreshToken'),
          uid: any(named: 'uid'),
        ));
    verifyNever(() => session.updateIdToken(any()));
  }

  void verifyPosts(int times) =>
      verify(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(times);

  void verifyNoPost() => verifyNever(() => client.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      ));

  group('un refresco que sale bien', () {
    test('rota el par con el uid guardado y lo devuelve', () async {
      stubDioPost(client, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
      });

      final outcome = await refresher.refresh();

      expect(outcome, isA<Refreshed>());
      final refreshed = outcome as Refreshed;
      expect(refreshed.idToken, 'new-id');
      expect(refreshed.refreshToken, 'new-refresh');
      verify(() => session.saveSession(
            idToken: 'new-id',
            refreshToken: 'new-refresh',
            uid: 'u-1',
          )).called(1);
    });

    test('sin uid guardado usa el user_id de la respuesta', () async {
      when(() => session.readUid()).thenAnswer((_) async => null);
      stubDioPost(client, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
        'user_id': 'u-9',
      });

      await refresher.refresh();

      verify(() => session.saveSession(
            idToken: 'new-id',
            refreshToken: 'new-refresh',
            uid: 'u-9',
          )).called(1);
    });

    test('si no llega refresh_token solo actualiza el idToken', () async {
      stubDioPost(client, body: {'id_token': 'new-id'});

      final outcome = await refresher.refresh();

      expect((outcome as Refreshed).refreshToken, 'old-refresh');
      verify(() => session.updateIdToken('new-id')).called(1);
      verifyNever(() => session.saveSession(
            idToken: any(named: 'idToken'),
            refreshToken: any(named: 'refreshToken'),
            uid: any(named: 'uid'),
          ));
    });
  });

  group('un refresco que no vale', () {
    test('sin uid guardado ni user_id no guarda nada', () async {
      when(() => session.readUid()).thenAnswer((_) async => null);
      stubDioPost(client, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
      });

      expect(await refresher.refresh(), isA<RefreshRejected>());
      verifyNothingSaved();
    });

    test('un uid guardado vacío tampoco se persiste', () async {
      when(() => session.readUid()).thenAnswer((_) async => '');
      stubDioPost(client, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
      });

      expect(await refresher.refresh(), isA<RefreshRejected>());
      verifyNothingSaved();
    });

    for (final token in <String?>[null, '']) {
      test('sin refreshToken guardado (${token ?? "ausente"})', () async {
        when(() => session.readRefreshToken()).thenAnswer((_) async => token);

        expect(await refresher.refresh(), isA<RefreshRejected>());
        verifyNoPost();
      });
    }

    test('una respuesta sin id_token se rechaza', () async {
      stubDioPost(client, body: {'refresh_token': 'new-refresh'});

      expect(await refresher.refresh(), isA<RefreshRejected>());
      verifyNothingSaved();
    });

    for (final status in [400, 401]) {
      test('el servidor responde $status: refreshToken rechazado', () async {
        stubRefreshThrows(failure(status: status));

        expect(await refresher.refresh(), isA<RefreshRejected>());
        verifyNothingSaved();
      });
    }
  });

  group('un refresco que no se pudo hacer', () {
    test('sin red devuelve el error para que quien llama decida', () async {
      final offline = failure(type: DioExceptionType.connectionError);
      stubRefreshThrows(offline);

      final outcome = await refresher.refresh();

      expect(outcome, isA<RefreshUnavailable>());
      expect((outcome as RefreshUnavailable).error, same(offline));
      verifyNothingSaved();
    });

    test('un 500 tampoco es un rechazo del refreshToken', () async {
      stubRefreshThrows(failure(status: 500));

      expect(await refresher.refresh(), isA<RefreshUnavailable>());
    });
  });

  group('varios refrescos a la vez', () {
    test('comparten una sola petición', () async {
      final gate = Completer<void>();
      when(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async {
        await gate.future;
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          data: {'id_token': 'new-id', 'refresh_token': 'new-refresh'},
          statusCode: 200,
        );
      });

      final first = refresher.refresh();
      final second = refresher.refresh();
      gate.complete();

      final outcomes = await Future.wait([first, second]);

      expect(outcomes.every((o) => o is Refreshed), isTrue);
      verify(() => client.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('un refresco posterior, ya terminado el primero, pide otro', () async {
      stubDioPost(client, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
      });

      await refresher.refresh();
      await refresher.refresh();

      verifyPosts(2);
    });
  });

  group('refrescar tras un 401', () {
    test('si el idToken ya cambió, usa el nuevo sin pedir otro', () async {
      when(() => session.readIdToken()).thenAnswer((_) async => 'fresh-id');

      final outcome = await refresher.refresh(staleIdToken: 'old-id');

      expect((outcome as Refreshed).idToken, 'fresh-id');
      expect(outcome.refreshToken, 'old-refresh');
      verifyNoPost();
    });

    test('si sigue siendo el mismo idToken, refresca', () async {
      stubDioPost(client, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
      });

      final outcome = await refresher.refresh(staleIdToken: 'old-id');

      expect((outcome as Refreshed).idToken, 'new-id');
      verifyPosts(1);
    });
  });
}
