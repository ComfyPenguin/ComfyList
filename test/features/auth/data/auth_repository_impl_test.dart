import 'package:comfy_list/features/auth/data/datasources/identity_toolkit_remote.dart';
import 'package:comfy_list/features/auth/data/models/auth_dto.dart';
import 'package:comfy_list/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:comfy_list/shared/data/local/daos/account_cache_dao.dart';
import 'package:comfy_list/shared/data/secure/secure_session_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements IdentityToolkitRemote {}

class _MockSession extends Mock implements SecureSessionStore {}

class _MockAccountDao extends Mock implements AccountCacheDao {}

void main() {
  late _MockRemote remote;
  late _MockSession session;
  late _MockAccountDao dao;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    session = _MockSession();
    dao = _MockAccountDao();
    repo = AuthRepositoryImpl(
      remote: remote,
      session: session,
      accountCache: dao,
    );

    when(() => session.saveSession(
          idToken: any(named: 'idToken'),
          refreshToken: any(named: 'refreshToken'),
          uid: any(named: 'uid'),
        )).thenAnswer((_) async {});
    when(() => session.clear()).thenAnswer((_) async {});
    when(() => dao.upsert(
          uid: any(named: 'uid'),
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async {});
    when(() => dao.deleteAll()).thenAnswer((_) async {});
  });

  group('signIn', () {
    test('devuelve Ok(AuthUser) y persiste sesión + cache en éxito', () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => IdentityAuthResponse(
            idToken: 'ID',
            refreshToken: 'REF',
            localId: 'u1',
            email: 'a@b.com',
            displayName: 'Andy',
          ));

      final result = await repo.signIn(email: 'a@b.com', password: 'secret');

      expect(result, isA<Ok>());
      result.fold(
        onOk: (u) {
          expect(u.uid, 'u1');
          expect(u.email, 'a@b.com');
          expect(u.displayName, 'Andy');
        },
        onErr: (_) => fail('Esperaba Ok'),
      );
      verify(() => session.saveSession(
            idToken: 'ID',
            refreshToken: 'REF',
            uid: 'u1',
          )).called(1);
      verify(() => dao.upsert(
            uid: 'u1',
            email: 'a@b.com',
            displayName: 'Andy',
          )).called(1);
    });

    test('mapea EMAIL_NOT_FOUND a InvalidCredentialsFailure', () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(_dioErrorWithCode('EMAIL_NOT_FOUND'));

      final result = await repo.signIn(email: 'x', password: 'y');
      expect(result, isA<Err>());
      result.fold(
        onOk: (_) => fail('Esperaba Err'),
        onErr: (f) => expect(f, isA<InvalidCredentialsFailure>()),
      );
    });

    test('mapea timeout a TimeoutFailure', () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await repo.signIn(email: 'x', password: 'y');
      result.fold(
        onOk: (_) => fail('Esperaba Err'),
        onErr: (f) => expect(f, isA<TimeoutFailure>()),
      );
    });
  });

  group('signUp', () {
    test('mapea EMAIL_EXISTS a EmailAlreadyInUseFailure', () async {
      when(() => remote.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(_dioErrorWithCode('EMAIL_EXISTS'));

      final result = await repo.signUp(email: 'a@b.com', password: 'secret');
      result.fold(
        onOk: (_) => fail('Esperaba Err'),
        onErr: (f) => expect(f, isA<EmailAlreadyInUseFailure>()),
      );
    });
  });

  group('signOut', () {
    test('limpia sesión y cache de cuenta', () async {
      await repo.signOut();
      verify(() => session.clear()).called(1);
      verify(() => dao.deleteAll()).called(1);
    });
  });

  group('currentUser', () {
    test('devuelve null si no hay sesión guardada', () async {
      when(() => session.hasSession()).thenAnswer((_) async => false);

      final result = await repo.currentUser();
      result.fold(
        onOk: (u) => expect(u, isNull),
        onErr: (_) => fail('Esperaba Ok(null)'),
      );
    });

    test('refresca, lookup y persiste cuando hay refreshToken', () async {
      when(() => session.hasSession()).thenAnswer((_) async => true);
      when(() => session.readRefreshToken()).thenAnswer((_) async => 'REF');
      when(() => remote.refresh('REF'))
          .thenAnswer((_) async => (idToken: 'NEW_ID', refreshToken: 'NEW_REF'));
      when(() => remote.lookup('NEW_ID')).thenAnswer(
        (_) async => IdentityLookupUser(localId: 'u1', email: 'a@b.com'),
      );

      final result = await repo.currentUser();
      result.fold(
        onOk: (u) {
          expect(u, isNotNull);
          expect(u!.uid, 'u1');
        },
        onErr: (_) => fail('Esperaba Ok'),
      );
      verify(() => session.saveSession(
            idToken: 'NEW_ID',
            refreshToken: 'NEW_REF',
            uid: 'u1',
          )).called(1);
    });

    test('hidrata desde cache local cuando el refresco falla por red', () async {
      when(() => session.hasSession()).thenAnswer((_) async => true);
      when(() => session.readRefreshToken()).thenAnswer((_) async => 'REF');
      when(() => session.readUid()).thenAnswer((_) async => 'u1');
      when(() => remote.refresh('REF')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );
      when(() => dao.findByUid('u1')).thenAnswer(
        (_) async => AccountCacheRow(
          uid: 'u1',
          email: 'a@b.com',
          displayName: 'Andy',
          cachedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final result = await repo.currentUser();
      result.fold(
        onOk: (u) {
          expect(u, isNotNull);
          expect(u!.uid, 'u1');
          expect(u.email, 'a@b.com');
          expect(u.displayName, 'Andy');
        },
        onErr: (_) => fail('Esperaba Ok con AuthUser cacheado'),
      );
      verifyNever(() => session.saveSession(
            idToken: any(named: 'idToken'),
            refreshToken: any(named: 'refreshToken'),
            uid: any(named: 'uid'),
          ));
    });

    test('cierra sesión si el refreshToken es rechazado (400)', () async {
      when(() => session.hasSession()).thenAnswer((_) async => true);
      when(() => session.readRefreshToken()).thenAnswer((_) async => 'REF');
      when(() => remote.refresh('REF')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 400,
            data: {
              'error': {'message': 'TOKEN_EXPIRED'},
            },
          ),
        ),
      );

      final result = await repo.currentUser();
      result.fold(
        onOk: (u) => expect(u, isNull),
        onErr: (_) => fail('Esperaba Ok(null) tras limpiar sesión'),
      );
      verify(() => session.clear()).called(1);
    });
  });
}

DioException _dioErrorWithCode(String code) {
  return DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 400,
      data: {
        'error': {'message': code},
      },
    ),
  );
}
