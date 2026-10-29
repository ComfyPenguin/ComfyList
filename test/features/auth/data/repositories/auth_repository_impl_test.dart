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
import '../../../../helpers/test_helpers.dart';

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

    when(() => session.saveEmailVerified(any())).thenAnswer((_) async {});
    when(() => session.clear()).thenAnswer((_) async {});
    when(() => session.readIdToken()).thenAnswer((_) async => null);
    when(() => accountCache.deleteAll()).thenAnswer((_) async {});
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
      when(() => remote.lookup('i-tok')).thenAnswer(
        (_) async => IdentityLookupUser(
          localId: 'u-1',
          email: 'a@b.c',
          displayName: 'Ana',
          emailVerified: true,
        ),
      );

      final res = await repo.signIn(email: 'a@b.c', password: 'pw!');

      expect(res.isOk, isTrue);
      final ok = res as Ok<AuthUser>;
      expect(ok.value.uid, 'u-1');
      expect(ok.value.email, 'a@b.c');
      expect(ok.value.displayName, 'Ana');
      expect(ok.value.emailVerified, isTrue);

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

    test('marca el correo como sin verificar si el lookup lo dice', () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => IdentityAuthResponse(
          idToken: 'i-tok',
          refreshToken: 'r-tok',
          localId: 'u-1',
          email: 'a@b.c',
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
      when(() => remote.lookup('i-tok')).thenAnswer(
        (_) async => IdentityLookupUser(
          localId: 'u-1',
          email: 'a@b.c',
          emailVerified: false,
        ),
      );

      final res = await repo.signIn(email: 'a@b.c', password: 'pw123456');

      expect((res as Ok<AuthUser>).value.emailVerified, isFalse);
      verify(() => session.saveEmailVerified(false)).called(1);
    });

    test('guarda que el correo está verificado cuando el lookup lo confirma',
        () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => IdentityAuthResponse(
          idToken: 'i-tok',
          refreshToken: 'r-tok',
          localId: 'u-1',
          email: 'a@b.c',
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
      when(() => remote.lookup('i-tok')).thenAnswer(
        (_) async => IdentityLookupUser(
          localId: 'u-1',
          email: 'a@b.c',
          emailVerified: true,
        ),
      );

      await repo.signIn(email: 'a@b.c', password: 'pw123456');

      verify(() => session.saveEmailVerified(true)).called(1);
    });

    test('sin respuesta del lookup guarda el correo como no verificado',
        () async {
      when(() => remote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => IdentityAuthResponse(
          idToken: 'i-tok',
          refreshToken: 'r-tok',
          localId: 'u-1',
          email: 'a@b.c',
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
      when(() => remote.lookup('i-tok')).thenAnswer((_) async => null);

      final res = await repo.signIn(email: 'a@b.c', password: 'pw123456');

      expect((res as Ok<AuthUser>).value.emailVerified, isFalse);
      verify(() => session.saveEmailVerified(false)).called(1);
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

    test('manda el correo de verificación y deja la cuenta pendiente',
        () async {
      when(() => remote.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => IdentityAuthResponse(
          idToken: 'i-tok',
          refreshToken: 'r-tok',
          localId: 'u-1',
          email: 'a@b.c',
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
      when(() => remote.sendEmailVerification('i-tok'))
          .thenAnswer((_) async {});

      final res = await repo.signUp(email: 'a@b.c', password: 'pw123456');

      expect((res as Ok<AuthUser>).value.emailVerified, isFalse);
      verify(() => session.saveEmailVerified(false)).called(1);
      verify(() => remote.sendEmailVerification('i-tok')).called(1);
    });

    test('el registro no se cae si el correo no llega a salir', () async {
      when(() => remote.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => IdentityAuthResponse(
          idToken: 'i-tok',
          refreshToken: 'r-tok',
          localId: 'u-1',
          email: 'a@b.c',
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
      when(() => remote.sendEmailVerification(any()))
          .thenThrow(badResponse('TOO_MANY_ATTEMPTS_TRY_LATER'));

      final res = await repo.signUp(email: 'a@b.c', password: 'pw123456');

      // La cuenta ya está creada: la pantalla de verificación puede reenviar.
      expect(res.isOk, isTrue);
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

    group('con la sesión guardada', () {
      DioException offline() => DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          );

      void stubStoredSession({String? uid = 'u-1', bool? emailVerified}) {
        when(() => session.hasSession()).thenAnswer((_) async => true);
        when(() => session.readRefreshToken())
            .thenAnswer((_) async => 'old-refresh');
        when(() => session.readUid()).thenAnswer((_) async => uid);
        when(() => session.readEmailVerified())
            .thenAnswer((_) async => emailVerified);
        when(() => accountCache.findByUid('u-1')).thenAnswer(
          (_) async => buildAccountCacheRow(uid: 'u-1', email: 'a@b.c'),
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
      }

      test('sin red usa el estado de verificación guardado (true)', () async {
        stubStoredSession(emailVerified: true);
        when(() => remote.refresh('old-refresh')).thenThrow(offline());

        final res = await repo.currentUser();

        expect((res as Ok<AuthUser?>).value!.emailVerified, isTrue);
      });

      test('sin red usa el estado de verificación guardado (false)', () async {
        stubStoredSession(emailVerified: false);
        when(() => remote.refresh('old-refresh')).thenThrow(offline());

        final res = await repo.currentUser();

        expect((res as Ok<AuthUser?>).value!.emailVerified, isFalse);
      });

      test('sin red y sin estado guardado queda en null, como antes',
          () async {
        stubStoredSession();
        when(() => remote.refresh('old-refresh')).thenThrow(offline());

        final res = await repo.currentUser();

        final user = (res as Ok<AuthUser?>).value!;
        expect(user.uid, 'u-1');
        expect(user.emailVerified, isNull);
      });

      for (final uid in <String?>[null, '']) {
        test('sin red y con uid ${uid == null ? 'ausente' : 'vacío'} no hidrata',
            () async {
          stubStoredSession(uid: uid, emailVerified: true);
          when(() => remote.refresh('old-refresh')).thenThrow(offline());

          final res = await repo.currentUser();

          expect((res as Err).failure, isA<NetworkFailure>());
        });
      }

      for (final verified in [true, false]) {
        test('con red guarda que el correo está verificado=$verified',
            () async {
          stubStoredSession();
          when(() => remote.refresh('old-refresh')).thenAnswer(
            (_) async => (idToken: 'new-id', refreshToken: 'new-refresh'),
          );
          when(() => remote.lookup('new-id')).thenAnswer(
            (_) async => IdentityLookupUser(
              localId: 'u-1',
              email: 'a@b.c',
              emailVerified: verified,
            ),
          );

          final res = await repo.currentUser();

          expect((res as Ok<AuthUser?>).value!.emailVerified, verified);
          verify(() => session.saveEmailVerified(verified)).called(1);
        });
      }

      test('con el refreshToken rechazado cierra la sesión local', () async {
        stubStoredSession(emailVerified: true);
        when(() => remote.refresh('old-refresh')).thenThrow(badResponse(
          'TOKEN_EXPIRED',
        ));

        final res = await repo.currentUser();

        expect((res as Ok<AuthUser?>).value, isNull);
        verify(() => session.clear()).called(1);
      });
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

  group('AuthRepositoryImpl.sendEmailVerification', () {
    test('usa el idToken que hay en la sesión', () async {
      when(() => session.readIdToken()).thenAnswer((_) async => 'i-tok');
      when(() => remote.sendEmailVerification('i-tok'))
          .thenAnswer((_) async {});

      final res = await repo.sendEmailVerification();

      expect(res.isOk, isTrue);
      verify(() => remote.sendEmailVerification('i-tok')).called(1);
    });

    test('sin idToken en la sesión devuelve Err', () async {
      when(() => session.readIdToken()).thenAnswer((_) async => null);

      final res = await repo.sendEmailVerification();

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<UnknownFailure>());
      verifyNever(() => remote.sendEmailVerification(any()));
    });

    test('traduce el error del servidor', () async {
      when(() => session.readIdToken()).thenAnswer((_) async => 'i-tok');
      when(() => remote.sendEmailVerification(any()))
          .thenThrow(badResponse('TOO_MANY_ATTEMPTS_TRY_LATER'));

      final res = await repo.sendEmailVerification();

      expect((res as Err).failure, isA<TooManyAttemptsFailure>());
    });
  });

  group('AuthRepositoryImpl.signOut', () {
    test('revoca los tokens del servidor antes de borrar la sesión', () async {
      when(() => session.readIdToken()).thenAnswer((_) async => 'i-tok');
      when(() => remote.revokeRefreshTokens('i-tok')).thenAnswer((_) async {});
      when(() => session.clear()).thenAnswer((_) async {});
      when(() => accountCache.deleteAll()).thenAnswer((_) async {});

      await repo.signOut();

      verify(() => remote.revokeRefreshTokens('i-tok')).called(1);
      verify(() => session.clear()).called(1);
      verify(() => accountCache.deleteAll()).called(1);
    });

    test('cierra la sesión igual si el servidor no contesta', () async {
      when(() => session.readIdToken()).thenAnswer((_) async => 'i-tok');
      when(() => remote.revokeRefreshTokens(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ),
      );
      when(() => session.clear()).thenAnswer((_) async {});
      when(() => accountCache.deleteAll()).thenAnswer((_) async {});

      await repo.signOut();

      verify(() => session.clear()).called(1);
    });

    test('sin idToken no llama al servidor y limpia igual', () async {
      when(() => session.readIdToken()).thenAnswer((_) async => null);
      when(() => session.clear()).thenAnswer((_) async {});
      when(() => accountCache.deleteAll()).thenAnswer((_) async {});

      await repo.signOut();

      verifyNever(() => remote.revokeRefreshTokens(any()));
      verify(() => session.clear()).called(1);
    });
  });
}
