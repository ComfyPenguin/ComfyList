import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:comfy_list/shared/core/env/firebase_endpoints.dart';
import 'package:comfy_list/shared/data/remote/auth_interceptor.dart';
import 'package:comfy_list/shared/data/remote/token_refresher.dart';

import '../../../helpers/dio_mock.dart';
import '../../../helpers/provider_scope.dart';

void main() {
  late MockSecureSessionStore session;
  late MockDio refreshClient;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    session = MockSecureSessionStore();
    refreshClient = MockDio();
    interceptor = AuthInterceptor(
      session: session,
      refreshClient: refreshClient,
      refresher: TokenRefresher(session: session, client: refreshClient),
    );

    when(() => session.readRefreshToken()).thenAnswer((_) async => 'old-refresh');
    when(() => session.readUid()).thenAnswer((_) async => 'u-1');
    when(() => session.readIdToken()).thenAnswer((_) async => 'new-id');
    when(() => session.saveSession(
          idToken: any(named: 'idToken'),
          refreshToken: any(named: 'refreshToken'),
          uid: any(named: 'uid'),
        )).thenAnswer((_) async {});
    when(() => session.updateIdToken(any())).thenAnswer((_) async {});
    when(() => refreshClient.fetch<dynamic>(any())).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
      ),
    );
  });

  DioException unauthorized({
    String url = '${FirebaseEndpoints.firestoreBase}/users/u-1/lists',
    int statusCode = 401,
    Map<String, dynamic>? extra,
  }) {
    final options = RequestOptions(path: url, extra: extra);
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(requestOptions: options, statusCode: statusCode),
    );
  }

  /// Dio completa `next` y `reject` como error del future y `resolve` como
  /// valor: en ambos casos se devuelve el `InterceptorState`.
  Future<dynamic> run(DioException err) async {
    final handler = ErrorInterceptorHandler();
    // ignore: invalid_use_of_protected_member
    final future = handler.future;
    final state = future.then<dynamic>((s) => s, onError: (Object s) => s);
    await interceptor.onError(err, handler);
    return state;
  }

  void expectOriginalError(dynamic state, DioException err) {
    expect(state.type.toString(), 'InterceptorResultType.next');
    expect(state.data, same(err));
  }

  void verifyNoRefreshAttempt() {
    verifyNever(() => refreshClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ));
    verifyNever(() => session.saveSession(
          idToken: any(named: 'idToken'),
          refreshToken: any(named: 'refreshToken'),
          uid: any(named: 'uid'),
        ));
  }

  group('refresco tras un 401 de Firestore', () {
    test('rota el par con el uid guardado y reintenta la petición', () async {
      stubDioPost(refreshClient, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
      });

      final state = await run(unauthorized());

      verify(() => session.saveSession(
            idToken: 'new-id',
            refreshToken: 'new-refresh',
            uid: 'u-1',
          )).called(1);
      expect(state.type.toString(), 'InterceptorResultType.resolve');
    });

    test('sin uid guardado ni user_id no guarda nada y deja pasar el 401',
        () async {
      when(() => session.readUid()).thenAnswer((_) async => null);
      stubDioPost(refreshClient, body: {
        'id_token': 'new-id',
        'refresh_token': 'new-refresh',
      });
      final err = unauthorized();

      expectOriginalError(await run(err), err);
      verifyNever(() => session.saveSession(
            idToken: any(named: 'idToken'),
            refreshToken: any(named: 'refreshToken'),
            uid: any(named: 'uid'),
          ));
    });

    test('reintenta con el idToken que acaba de recibir', () async {
      stubDioPost(refreshClient, body: {
        'id_token': 'rotated-id',
        'refresh_token': 'new-refresh',
      });
      final err = unauthorized();

      await run(err);

      final retried = verify(() => refreshClient.fetch<dynamic>(captureAny()))
          .captured
          .single as RequestOptions;
      expect(retried.headers['Authorization'], 'Bearer rotated-id');
    });

    test('si otro refresco ya cambió el idToken, reintenta sin pedir otro',
        () async {
      // La petición salió con 'old-id' y entretanto la sesión ya tiene 'new-id'.
      final options = RequestOptions(
        path: '${FirebaseEndpoints.firestoreBase}/users/u-1/lists',
        headers: {'Authorization': 'Bearer old-id'},
      );
      final err = DioException(
        requestOptions: options,
        response: Response<dynamic>(requestOptions: options, statusCode: 401),
      );

      final state = await run(err);

      verifyNoRefreshAttempt();
      expect(state.type.toString(), 'InterceptorResultType.resolve');
      final retried = verify(() => refreshClient.fetch<dynamic>(captureAny()))
          .captured
          .single as RequestOptions;
      expect(retried.headers['Authorization'], 'Bearer new-id');
    });
  });

  group('cuándo no refresca', () {
    for (final token in <String?>[null, '']) {
      test('refreshToken ${token == null ? 'ausente' : 'vacío'}', () async {
        when(() => session.readRefreshToken()).thenAnswer((_) async => token);
        final err = unauthorized();

        expectOriginalError(await run(err), err);
        verifyNoRefreshAttempt();
      });
    }

    test('la petición ya se había reintentado', () async {
      final err = unauthorized(extra: {'auth_retried': true});

      expectOriginalError(await run(err), err);
      verifyNoRefreshAttempt();
    });

    test('un 403 no es de caducidad', () async {
      final err = unauthorized(statusCode: 403);

      expectOriginalError(await run(err), err);
      verifyNoRefreshAttempt();
    });

    test('un error sin respuesta (red) no refresca', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: FirebaseEndpoints.firestoreBase),
        type: DioExceptionType.connectionError,
      );

      expectOriginalError(await run(err), err);
      verifyNoRefreshAttempt();
    });

    test('una URL que no es de Firestore no refresca', () async {
      final err = unauthorized(url: '${FirebaseEndpoints.identityBase}:lookup');

      expectOriginalError(await run(err), err);
      verifyNoRefreshAttempt();
    });
  });
}
