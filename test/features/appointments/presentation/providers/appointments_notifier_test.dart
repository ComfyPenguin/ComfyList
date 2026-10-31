import 'dart:async';

import 'package:comfy_list/features/appointments/data/datasources/firestore_appointments_remote.dart';
import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_state.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/features/trash/domain/repositories/trash_repository.dart';
import 'package:comfy_list/features/trash/presentation/providers/trash_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _MockTrash extends Mock implements TrashRepository {}

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

  /// Un contenedor con la lista de citas ya cargada y la papelera en memoria.
  Future<(ProviderContainer, StreamController<List<Appointment>>)> loaded(
    List<Appointment> appointments,
  ) async {
    final controller = StreamController<List<Appointment>>();
    when(() => repo.watchAppointments('u1'))
        .thenAnswer((_) => controller.stream);
    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
      authedUser: buildAuthUser(),
      repositoryOverrides: {AppointmentsRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());
    controller.add(appointments);
    await pumpEventQueue();
    return (container, controller);
  }

  test('delete guarda la cita en la papelera y undo la devuelve', () async {
    when(() => repo.deleteAppointment(uid: 'u1', id: 'a1'))
        .thenAnswer((_) async => const Ok(null));
    final appointment = buildAppointment(id: 'a1', title: 'Dentista');
    when(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: any(named: 'appointment'),
        )).thenAnswer((_) async => Ok(appointment));
    final (container, _) = await loaded([appointment]);
    final notifier = container.read(appointmentsProvider.notifier);

    final deleted = await notifier.delete('a1');

    expect(deleted, isNotNull);
    expect(trash.entries, hasLength(1));
    expect(await notifier.undo(deleted!), isTrue);

    // Vuelve tal y como estaba: la papelera guarda la cita serializada.
    final restored = verify(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: captureAny(named: 'appointment'),
        )).captured.single as Appointment;
    expect(restored.id, 'a1');
    expect(restored.title, 'Dentista');
    expect(restored.dateTime.isAtSameMomentAs(appointment.dateTime), isTrue);

    expect(trash.entries, isEmpty);
  });

  test('undo devuelve el borrado que se le da, no el último de las citas',
      () async {
    when(() => repo.deleteAppointment(
          uid: 'u1',
          id: any(named: 'id'),
        )).thenAnswer((_) async => const Ok(null));
    when(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: any(named: 'appointment'),
        )).thenAnswer((invocation) async =>
        Ok(invocation.namedArguments[#appointment] as Appointment));
    final (container, _) = await loaded([
      buildAppointment(id: 'a1', title: 'Dentista'),
      buildAppointment(id: 'a2', title: 'Peluquería'),
    ]);
    final notifier = container.read(appointmentsProvider.notifier);
    final first = await notifier.delete('a1');
    await notifier.delete('a2');

    expect(await notifier.undo(first!), isTrue);

    final restored = verify(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: captureAny(named: 'appointment'),
        )).captured.single as Appointment;
    expect(restored.id, 'a1');
    // La otra sigue en la papelera.
    expect(trash.entries.map((e) => e.itemId), ['a2']);
  });

  test('si el borrado falla, delete devuelve null y no deja copia', () async {
    when(() => repo.deleteAppointment(uid: 'u1', id: 'a1'))
        .thenAnswer((_) async => const Err<void>(ServerFailure('Error 500')));
    final (container, _) = await loaded([buildAppointment(id: 'a1')]);

    final deleted =
        await container.read(appointmentsProvider.notifier).delete('a1');

    expect(deleted, isNull);
    verify(() => repo.deleteAppointment(uid: 'u1', id: 'a1')).called(1);
    expect(trash.entries, isEmpty);
  });

  test('si no se puede guardar la copia, delete no borra la cita', () async {
    registerFallbackValue(<TrashItem>[]);
    final trashRepo = _MockTrash();
    when(() => trashRepo.save(
          uid: any(named: 'uid'),
          items: any(named: 'items'),
        )).thenAnswer((_) async => const Err(NetworkFailure()));
    final controller = StreamController<List<Appointment>>();
    when(() => repo.watchAppointments('u1'))
        .thenAnswer((_) => controller.stream);
    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {AppointmentsRepository: repo},
      extra: [trashRepositoryProvider.overrideWithValue(trashRepo)],
    );
    addTearDown(controller.close);
    expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());
    controller.add([buildAppointment(id: 'a1')]);
    await pumpEventQueue();

    final deleted =
        await container.read(appointmentsProvider.notifier).delete('a1');

    expect(deleted, isNull);
    verifyNever(() => repo.deleteAppointment(
          uid: any(named: 'uid'),
          id: any(named: 'id'),
        ));
  });

  test('delete de una cita que no está cargada no borra nada', () async {
    final (container, _) = await loaded([buildAppointment(id: 'a1')]);

    final deleted =
        await container.read(appointmentsProvider.notifier).delete('otra');

    expect(deleted, isNull);
    verifyNever(() => repo.deleteAppointment(
          uid: any(named: 'uid'),
          id: any(named: 'id'),
        ));
  });

  test('undo dice que no si la restauración falla', () async {
    when(() => repo.deleteAppointment(uid: 'u1', id: 'a1'))
        .thenAnswer((_) async => const Ok(null));
    when(() => repo.restoreAppointment(
          uid: 'u1',
          appointment: any(named: 'appointment'),
        )).thenAnswer(
      (_) async => const Err<Appointment>(ServerFailure('Error 500')),
    );
    final (container, _) = await loaded([buildAppointment(id: 'a1')]);
    final notifier = container.read(appointmentsProvider.notifier);
    final deleted = await notifier.delete('a1');

    expect(await notifier.undo(deleted!), isFalse);

    // El borrado sigue en la papelera: se puede reintentar.
    expect(trash.entries, hasLength(1));
  });

  group('mutaciones', () {
    late ProviderContainer container;

    setUp(() async {
      final controller = StreamController<List<Appointment>>();
      when(() => repo.watchAppointments('u1'))
          .thenAnswer((_) => controller.stream);
      container = createTestContainer(
        authedUser: buildAuthUser(),
        repositoryOverrides: {AppointmentsRepository: repo},
      );
      addTearDown(controller.close);
      expect(container.read(appointmentsProvider), isA<AppointmentsLoading>());
      controller.add([buildAppointment(id: 'a1')]);
      await pumpEventQueue();
    });

    AppointmentsNotifier notifier() =>
        container.read(appointmentsProvider.notifier);

    test('create devuelve true si sale bien', () async {
      when(() => repo.createAppointment(
            uid: 'u1',
            title: any(named: 'title'),
            description: any(named: 'description'),
            location: any(named: 'location'),
            dateTime: any(named: 'dateTime'),
          )).thenAnswer((_) async => Ok(buildAppointment(id: 'a2')));

      final ok = await notifier().create(
        title: 'Dentista',
        dateTime: DateTime.utc(2026, 6, 1, 9),
      );

      expect(ok, isTrue);
    });

    test('create devuelve false si falla y no vacía la lista', () async {
      when(() => repo.createAppointment(
            uid: 'u1',
            title: any(named: 'title'),
            description: any(named: 'description'),
            location: any(named: 'location'),
            dateTime: any(named: 'dateTime'),
          )).thenAnswer(
        (_) async => const Err<Appointment>(ServerFailure('Error 500')),
      );

      final ok = await notifier().create(
        title: 'Dentista',
        dateTime: DateTime.utc(2026, 6, 1, 9),
      );

      expect(ok, isFalse);
      final state = container.read(appointmentsProvider);
      expect(state, isA<AppointmentsData>());
      expect((state as AppointmentsData).items.map((a) => a.id), ['a1']);
    });

    test('toggleDone y updateFields devuelven false si fallan', () async {
      when(() => repo.updateAppointment(
            uid: 'u1',
            id: 'a1',
            title: any(named: 'title'),
            description: any(named: 'description'),
            clearDescription: any(named: 'clearDescription'),
            location: any(named: 'location'),
            clearLocation: any(named: 'clearLocation'),
            dateTime: any(named: 'dateTime'),
            isDone: any(named: 'isDone'),
          )).thenAnswer((_) async => const Err<Appointment>(NetworkFailure()));

      expect(await notifier().toggleDone('a1', true), isFalse);
      expect(await notifier().updateFields(id: 'a1', title: 'Nuevo'), isFalse);
    });
  });
}
