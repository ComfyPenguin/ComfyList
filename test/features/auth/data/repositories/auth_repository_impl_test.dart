import 'package:comfy_list/features/auth/data/datasources/identity_toolkit_remote.dart';
import 'package:comfy_list/features/auth/data/models/auth_dto.dart';
import 'package:comfy_list/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:comfy_list/features/auth/domain/entities/auth_user.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/data/local/daos/account_cache_dao.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';

class _MockIdentityToolkitRemote extends Mock
    implements IdentityToolkitRemote {}

class _MockAccountCacheDao extends Mock implements AccountCacheDao {}

void main() {
  late _MockIdentityToolkitRemote remote;
  late MockSecureSessionStore session;
  late _MockAccountCacheDao accountCache;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockIdentityToolkitRemote();
    session = MockSecureSessionStore();
    accountCache = _MockAccountCacheDao();
    repo = AuthRepositoryImpl(
      remote: remote,
      session: session,
      accountCache: accountCache,
    );
  });

  /// Respuesta de error de Identity Toolkit con el código dado.
  DioException badResponse(String code) => DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: <String, dynamic>{
            'error': <String, dynamic>{
              'code': 400,
              'message': code,
              'status': 'INVALID_ARGUMENT',
            },
          },
        ),
      );

  group('AuthRepositoryImpl.signIn', () {
    test('returns Ok(AuthUser) and persists session + cache on success',
        () async {
      const user = AuthUser(uid: 'u-1', email: 'a@b.c', displayName: 'Ana');
      when(() => remote.signInWithPassword(
            email: 'a@b.c',
            password: 'pw!',
          )).thenAnswer(
        (_) async => IdentityAuthResponse(
          idToken: 'i-tok',
          refreshToken: 'r-tok',
          localId: 'u-1',
          email: 'a@b.c',
          displayName: 'Ana',
        ),
      );
      when(() => session.saveSession(
            idToken: any(named: 'idToken'),
            refreshToken: any(named: 'refreshToken'),
            uid: any(named: 'uid'),
          )).thenAnswer((_) async {});
      when(() => accountCache.upsert(
            uid: any(named: 'uid'),
            email: any(named: 'email'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async {});

      final res = await repo.signIn(email: 'a@b.c', password: 'pw!');

      expect(res.isOk, isTrue);
      final ok = res as Ok<AuthUser>;
      expect(ok.value.uid, 'u-1');
      expect(ok.value.email, 'a@b.c');
      expect(ok.value.displayName, 'Ana');

      verify(() => session.saveSession(
            idToken: 'i-tok',
            refreshToken: 'r-tok',
            uid: 'u-1',
          )).called(1);
      verify(() => accountCache.upsert(
            uid: 'u-1',
            email: 'a@b.c',
            displayName: 'Ana',
          )).called(1);
      expect(user, isA<AuthUser>());
    });

    test('returns Err(InvalidCredentialsFailure) on INVALID_LOGIN_CREDENTIALS',
        () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: <String, dynamic>{
              'error': <String, dynamic>{
                'code': 400,
                'message': 'INVALID_LOGIN_CREDENTIALS',
                'status': 'INVALID_LOGUMENT',
              },
            },
          ),
        ),
      );

      final res = await repo.signIn(email: 'a@b.c', password: 'wrong');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<InvalidCredentialsFailure>());
      verifyNever(() => session.saveSession(
            idToken: any(named: 'idToken'),
            refreshToken: any(named: 'refreshToken'),
            uid: any(named: 'uid'),
          ));
    });
  });

  group('AuthRepositoryImpl.signUp', () {
    test('returns Err(EmailAlreadyInUseFailure) on EMAIL_EXISTS', () async {
      when(() => remote.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: <String, dynamic>{
              'error': <String, dynamic>{
                'code': 400,
                'message': 'EMAIL_EXISTS',
                'status': 'INVALID_ARGUMENT',
              },
            },
          ),
        ),
      );

      final res = await repo.signUp(email: 'a@b.c', password: 'pw!');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<EmailAlreadyInUseFailure>());
    });
  });

  group('AuthRepositoryImpl traduce los códigos de Identity Toolkit', () {
    test('ninguno llega crudo a la pantalla', () async {
      final cases = <String, Type>{
        'TOO_MANY_ATTEMPTS_TRY_LATER': TooManyAttemptsFailure,
        'USER_DISABLED': AccountDisabledFailure,
        'PASSWORD_LOGIN_DISABLED': PasswordLoginDisabledFailure,
        'OPERATION_NOT_ALLOWED': PasswordLoginDisabledFailure,
        'INVALID_LOGIN_CREDENTIALS': InvalidCredentialsFailure,
        'EMAIL_EXISTS': EmailAlreadyInUseFailure,
      };

      for (final entry in cases.entries) {
        when(() => remote.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(badResponse(entry.key));

        final res = await repo.signIn(email: 'a@b.c', password: 'pw123456');

        expect(res.isErr, isTrue);
        expect(
          (res as Err).failure.runtimeType,
          entry.value,
          reason: 'El código ${entry.key} debe llegar traducido.',
        );
      }
    });

    test('un código desconocido cae en ServerFailure, no se inventa', () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(badResponse('SOMETHING_NEW'));

      final res = await repo.signIn(email: 'a@b.c', password: 'pw123456');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<ServerFailure>());
    });
  });

  group('AuthRepositoryImpl.currentUser', () {
    test('returns Ok(null) when there is no session', () async {
      when(() => session.hasSession()).thenAnswer((_) async => false);

      final res = await repo.currentUser();

      expect(res.isOk, isTrue);
      final ok = res as Ok<AuthUser?>;
      expect(ok.value, isNull);
      verifyNever(() => remote.refresh(any()));
    });

    test('returns Err(NetworkFailure) on connectionError when no cache',
        () async {
      when(() => session.hasSession()).thenAnswer((_) async => true);
      when(() => session.readRefreshToken())
          .thenAnswer((_) async => 'old-refresh');
      when(() => session.readUid()).thenAnswer((_) async => 'u-1');
      when(() => accountCache.findByUid('u-1'))
          .thenAnswer((_) async => null);
      when(() => remote.refresh('old-refresh')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ),
      );

      final res = await repo.currentUser();

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<NetworkFailure>());
    });
  });

  group('AuthRepositoryImpl.sendPasswordResetEmail', () {
    test('collapses EMAIL_NOT_FOUND into Ok(null) (privacy)', () async {
      when(() => remote.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: <String, dynamic>{
              'error': <String, dynamic>{
                'code': 400,
                'message': 'EMAIL_NOT_FOUND',
                'status': 'INVALID_ARGUMENT',
              },
            },
          ),
        ),
      );

      final res = await repo.sendPasswordResetEmail(email: 'missing@b.c');

      expect(res.isOk, isTrue);
      expect((res as Ok).value, isNull);
    });
  });
}
