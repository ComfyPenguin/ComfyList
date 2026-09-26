import 'package:comfy_list/features/auth/domain/entities/auth_user.dart';
import 'package:comfy_list/features/auth/domain/repositories/auth_repository.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_provider.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';

/// Cuenta que espera en la pantalla de verificación.
const _pending = AuthUser(
  uid: 'u-1',
  email: 'a@b.c',
  displayName: 'Ana',
  emailVerified: false,
);

/// La misma cuenta, ya confirmada por el servidor.
const _verified = AuthUser(
  uid: 'u-1',
  email: 'a@b.c',
  displayName: 'Ana',
  emailVerified: true,
);

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(() => repo.currentUser())
        .thenAnswer((_) async => const Ok<AuthUser?>(_pending));
    when(() => repo.sendEmailVerification())
        .thenAnswer((_) async => const Ok(null));
    when(() => repo.signOut()).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(
            () => StaticAuthNotifier(const AuthUnverifiedEmail(_pending)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const VerifyEmailScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Deja correr la acción pulsada: un pump para el estado de carga y otro
  /// para el futuro que resuelve.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('enseña el correo y las tres salidas posibles', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('a@b.c', findRichText: true), findsOneWidget);
    expect(find.text('YA LO HE VERIFICADO'), findsOneWidget);
    expect(find.text('Reenviar correo'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('si el enlace no se ha abierto, lo dice sin dejar pasar', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('YA LO HE VERIFICADO'));
    await settle(tester);

    expect(find.textContaining('Todavía no aparece'), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
  });

  testWidgets('cuando el servidor confirma, no hay aviso de espera', (
    tester,
  ) async {
    when(() => repo.currentUser())
        .thenAnswer((_) async => const Ok<AuthUser?>(_verified));

    await pumpScreen(tester);

    await tester.tap(find.text('YA LO HE VERIFICADO'));
    await settle(tester);

    expect(find.textContaining('Todavía no aparece'), findsNothing);
  });

  testWidgets('reenviar avisa de que ha salido otro correo', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Reenviar correo'));
    await settle(tester);

    expect(find.text('Te hemos enviado otro correo.'), findsOneWidget);
    verify(() => repo.sendEmailVerification()).called(1);
  });

  testWidgets('si el reenvío falla, enseña el motivo', (tester) async {
    when(() => repo.sendEmailVerification())
        .thenAnswer((_) async => const Err<void>(TooManyAttemptsFailure()));

    await pumpScreen(tester);

    await tester.tap(find.text('Reenviar correo'));
    await settle(tester);

    expect(
      find.text(const TooManyAttemptsFailure().message),
      findsOneWidget,
    );
  });

  testWidgets('cerrar sesión sale de la cuenta', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Cerrar sesión'));
    await settle(tester);

    verify(() => repo.signOut()).called(1);
  });
}
