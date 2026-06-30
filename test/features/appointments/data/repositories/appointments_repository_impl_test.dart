import 'package:comfy_list/features/appointments/data/datasources/firestore_appointments_remote.dart';
import 'package:comfy_list/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

class _MockRemote extends Mock implements FirestoreAppointmentsRemote {}

void main() {
  late _MockRemote remote;
  late AppointmentsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = AppointmentsRepositoryImpl(remote);
  });

  tearDown(() {
    repo.dispose();
  });

  group('AppointmentsRepositoryImpl', () {
    test('fetchAppointments returns Ok(list) on remote success', () async {
      when(() => remote.listAppointments(uid: 'u1'))
          .thenAnswer((_) async => [buildAppointment()]);

      final res = await repo.fetchAppointments('u1');

      expect(res.isOk, isTrue);
      final ok = res as Ok<List<Appointment>>;
      expect(ok.value, hasLength(1));
      expect(ok.value.first.id, 'a1');
    });

    test('fetchAppointments returns Err(NetworkFailure) on connectionError',
        () async {
      when(() => remote.listAppointments(uid: 'u1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ),
      );

      final res = await repo.fetchAppointments('u1');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<NetworkFailure>());
    });

    test('createAppointment returns Err(AuthFailure) on 403', () async {
      when(() => remote.createAppointment(
            uid: 'u1',
            title: any(named: 'title'),
            description: any(named: 'description'),
            location: any(named: 'location'),
            dateTime: any(named: 'dateTime'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
          ),
        ),
      );

      final res = await repo.createAppointment(
        uid: 'u1',
        title: 'Dentista',
        dateTime: DateTime.utc(2026, 6, 1, 9),
      );

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<AuthFailure>());
    });

    test('updateAppointment refreshes the watcher', () async {
      when(() => remote.listAppointments(uid: 'u1'))
          .thenAnswer((_) async => <Appointment>[buildAppointment()]);
      when(() => remote.updateAppointment(
            uid: 'u1',
            id: 'a1',
            title: any(named: 'title'),
            description: any(named: 'description'),
            clearDescription: any(named: 'clearDescription'),
            location: any(named: 'location'),
            clearLocation: any(named: 'clearLocation'),
            dateTime: any(named: 'dateTime'),
            isDone: any(named: 'isDone'),
          )).thenAnswer((_) async => buildAppointment(id: 'a1'));

      // Suscribimos al watcher antes de la mutación
      final emitted = <List<Appointment>>[];
      final sub = repo.watchAppointments('u1').listen(emitted.add);

      final res = await repo.updateAppointment(
        uid: 'u1',
        id: 'a1',
        isDone: true,
      );

      await Future<void>.delayed(Duration.zero);

      expect(res.isOk, isTrue);
      expect(emitted, isNotEmpty);

      await sub.cancel();
    });

    test('fetchAppointments returns Err(TimeoutFailure) on receiveTimeout',
        () async {
      when(() => remote.listAppointments(uid: 'u1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final res = await repo.fetchAppointments('u1');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<TimeoutFailure>());
    });
  });
}
