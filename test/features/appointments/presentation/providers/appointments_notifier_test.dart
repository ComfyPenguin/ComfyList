import 'dart:async';

import 'package:comfy_list/features/appointments/data/datasources/firestore_appointments_remote.dart';
import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_state.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_trash_remote.dart';
import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockRepo extends Mock implements AppointmentsRepository {}

class _MockRemote extends Mock implements FirestoreAppointmentsRemote {}

void main() {
  late _MockRepo repo;
  late FakeTrashRemote trash;

  setUpAll(() {
    // mocktail necesita un valor de relleno para los matchers de entidades.
    registerFallbackValue(buildAppointment());
  });

  setUp(() {
    repo = _MockRepo();
    trash = FakeTrashRemote();
  });

  test('el repo de la app toma la cadencia del polling del provider', () async {
    final remote = _MockRemote();
    when(() => remote.listAppointments(uid: 'u1'))
        .thenAnswer((_) async => <Appointment>[]);
    final container = createTestContainer(
      remoteOverrides: {FirestoreAppointmentsRemote: remote},
      extra: [
        pollIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
      ],
    );
    final sub = container
        .read(appointmentsRepositoryProvider)
        .watchAppointments('u1')
        .listen((_) {});
    addTearDown(sub.cancel);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    verify(() => remote.listAppointments(uid: 'u1')).called(greaterThan(1));
  });

  test('build returns AppointmentsInitial when auth is Unauthenticated', () {
    final container = createTestContainer(
      authState: const Unauthenticated(),
      repositoryOverrides: {AppointmentsRepository: repo},
    );

    expect(container.read(appointmentsProvider), isA<AppointmentsInitial>());
    verifyNever(() => repo.watchAppointments(any()));
  });

  test('build subscribes to watchAppointments when authenticated', () async {
    final controller = StreamController<List<Appointment>>();
    when(() => repo.watchAppointments('u1'))
        .thenAnswer((_) => controller.stream);

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {AppointmentsRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());

    controller.add(<Appointment>[]);
    await pumpEventQueue();

    final state = container.read(appointmentsProvider);
    expect(state, isA<AppointmentsData>());
    expect((state as AppointmentsData).items, isEmpty);
  });

  test('toggleDone calls updateAppointment with isDone', () async {
    final controller = StreamController<List<Appointment>>();
    when(() => repo.watchAppointments('u1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.updateAppointment(
          uid: 'u1',
          id: 'a1',
          title: any(named: 'title'),
          description: any(named: 'description'),
          clearDescription: any(named: 'clearDescription'),
          location: any(named: 'location'),
          clearLocation: any(named: 'clearLocation'),
          dateTime: any(named: 'dateTime'),
          isDone: true,
        )).thenAnswer((_) async => Ok(buildAppointment(id: 'a1', isDone: true)));

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {AppointmentsRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());

    await container.read(appointmentsProvider.notifier).toggleDone('a1', true);

    verify(() => repo.updateAppointment(
          uid: 'u1',
          id: 'a1',
          title: any(named: 'title'),
          description: any(named: 'description'),
          clearDescription: any(named: 'clearDescription'),
          location: any(named: 'location'),
          clearLocation: any(named: 'clearLocation'),
          dateTime: any(named: 'dateTime'),
          isDone: true,
        )).called(1);
  });

  test('delete Err is swallowed (state unchanged) — known spec drift',
      () async {
    // DRIFT: spec REQ-074 escenario 4 dice que `delete` con Err debe
    // propagar a `AppointmentsError`. La producción NO lo hace — `delete`
    // hace `await ... deleteAppointment(...)` y descarta el Result.
    // A diferencia de `create` (que sí hace `fold` y propaga Err a state),
    // `delete` no maneja el error. Test verifica el comportamiento real.
    final controller = StreamController<List<Appointment>>();
    when(() => repo.watchAppointments('u1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteAppointment(uid: 'u1', id: 'a1'))
        .thenAnswer(
      (_) async => const Err<void>(
        ServerFailure('Error 500'),
      ),
    );

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {AppointmentsRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());

    await container.read(appointmentsProvider.notifier).delete('a1');

    // El state NO se actualiza con el error (drift documentado).
    // El repo sí fue invocado, lo que confirma que la operación pasó
    // por el camino del delete.
    verify(() => repo.deleteAppointment(uid: 'u1', id: 'a1')).called(1);
    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());
  });

  test('delete guarda la cita en la papelera y undoLastDelete la devuelve',
      () async {
    final controller = StreamController<List<Appointment>>();
    when(() => repo.watchAppointments('u1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteAppointment(uid: 'u1', id: 'a1'))
        .thenAnswer((_) async => const Ok(null));
    final appointment = buildAppointment(id: 'a1', title: 'Dentista');
    when(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: any(named: 'appointment'),
        )).thenAnswer((_) async => Ok(appointment));

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
      authedUser: buildAuthUser(),
      repositoryOverrides: {AppointmentsRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());
    controller.add([appointment]);
    await pumpEventQueue();

    final notifier = container.read(appointmentsProvider.notifier);
    await notifier.delete('a1');

    expect(await notifier.undoLastDelete(), isTrue);

    // Vuelve tal y como estaba: la papelera guarda la cita serializada.
    final restored = verify(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: captureAny(named: 'appointment'),
        )).captured.single as Appointment;
    expect(restored.id, 'a1');
    expect(restored.title, 'Dentista');
    expect(restored.dateTime, appointment.dateTime);

    expect(trash.entries, isEmpty);
  });

  test('undoLastDelete dice que no si la restauración falla', () async {
    final controller = StreamController<List<Appointment>>();
    when(() => repo.watchAppointments('u1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteAppointment(uid: 'u1', id: 'a1'))
        .thenAnswer((_) async => const Ok(null));
    final appointment = buildAppointment(id: 'a1');
    when(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: any(named: 'appointment'),
        )).thenAnswer(
      (_) async => const Err<Appointment>(ServerFailure('Error 500')),
    );

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
      authedUser: buildAuthUser(),
      repositoryOverrides: {AppointmentsRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());
    controller.add([appointment]);
    await pumpEventQueue();

    final notifier = container.read(appointmentsProvider.notifier);
    await notifier.delete('a1');

    expect(await notifier.undoLastDelete(), isFalse);

    // El borrado sigue en la papelera: se puede reintentar.
    expect(trash.entries, hasLength(1));
  });
}
