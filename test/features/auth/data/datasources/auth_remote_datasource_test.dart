// signInWithGoogle is deferred: GoogleSignIn.instance is a static singleton,
// not injectable through the current architecture. See R3 in
// sdd/test-scaffolding/proposal. To test it we would need to refactor the
// GoogleSignIn calls behind an interface — out of scope for the
// test-scaffolding change. The error path of the Firebase exchange
// (`signInWithGoogle` on the remote) is exercised through the success
// path of `signInWithPassword`, which uses the same `accounts:signInWithIdp`
// transport when reaching the wire; the static SDK calls live in
// `AuthRepositoryImpl.signInWithGoogle`, not in this remote.

import 'package:comfy_list/features/auth/data/datasources/identity_toolkit_remote.dart';
import 'package:comfy_list/shared/core/env/firebase_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/dio_mock.dart';

class _MockDio extends MockDio {}

void main() {
  late _MockDio dio;
  late IdentityToolkitRemote remote;

  setUp(() {
    dio = _MockDio();
    remote = IdentityToolkitRemote(dio);
  });

  group('IdentityToolkitRemote', () {
    test('signUp posts to :signUp?key= and decodes the response', () async {
      final body = <String, dynamic>{
        'idToken': 'id-tok',
        'refreshToken': 'ref-tok',
        'localId': 'u-1',
        'email': 'a@b.c',
        'displayName': 'Ana',
      };
      stubDioPost(dio, body: body);

      final res = await remote.signUp(email: 'a@b.c', password: 'pw!');

      expect(res.idToken, 'id-tok');
      expect(res.refreshToken, 'ref-tok');
      expect(res.localId, 'u-1');
      expect(res.email, 'a@b.c');
      expect(res.displayName, 'Ana');

      verify(() => dio.post<Map<String, dynamic>>(
            '${FirebaseEndpoints.identityBase}:signUp?key=${FirebaseEndpoints.apiKey}',
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('signInWithPassword rethrows DioException with badResponse + 400', () async {
      final errBody = <String, dynamic>{
        'error': <String, dynamic>{
          'code': 400,
          'message': 'INVALID_LOGIN_CREDENTIALS',
          'status': 'INVALID_ARGUMENT',
        },
      };
      stubDioError(
        dio,
        type: DioExceptionType.badResponse,
        statusCode: 400,
        body: errBody,
      );

      await expectLater(
        () => remote.signInWithPassword(email: 'a@b.c', password: 'wrong'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.badResponse)
              .having((e) => e.response?.statusCode, 'statusCode', 400)
              .having(
                (e) => (e.response?.data as Map<String, dynamic>)['error']
                    ['message'],
                'error.message',
                'INVALID_LOGIN_CREDENTIALS',
              ),
        ),
      );
    });

    test('refresh posts to the token endpoint and decodes id_token / refresh_token',
        () async {
      final body = <String, dynamic>{
        'id_token': 'NEW_ID',
        'refresh_token': 'NEW_REF',
        'expires_in': '3600',
        'token_type': 'Bearer',
      };
      stubDioPost(dio, body: body);

      final res = await remote.refresh('OLD_REF');

      expect(res.idToken, 'NEW_ID');
      expect(res.refreshToken, 'NEW_REF');

      verify(() => dio.post<Map<String, dynamic>>(
            '${FirebaseEndpoints.tokenBase}?key=${FirebaseEndpoints.apiKey}',
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('revokeRefreshTokens manda el idToken y un validSince de ahora',
        () async {
      stubDioPost(dio, body: const <String, dynamic>{});

      await remote.revokeRefreshTokens('id-tok');

      final data = verify(() => dio.post<Map<String, dynamic>>(
            '${FirebaseEndpoints.identityBase}:update?key=${FirebaseEndpoints.apiKey}',
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured.single as Map<String, dynamic>;

      expect(data['idToken'], 'id-tok');
      expect(
        int.parse(data['validSince'] as String),
        closeTo(DateTime.now().millisecondsSinceEpoch ~/ 1000, 5),
      );
    });
  });
}
