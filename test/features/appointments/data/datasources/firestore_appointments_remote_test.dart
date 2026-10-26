import 'package:comfy_list/features/appointments/data/datasources/firestore_appointments_remote.dart';
import 'package:comfy_list/shared/core/env/firebase_endpoints.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/dio_mock.dart';
import '../../../../helpers/test_helpers.dart';

class _MockDio extends MockDio {}

void main() {
  late _MockDio dio;
  late FirestoreAppointmentsRemote remote;

  setUp(() {
    dio = _MockDio();
    remote = FirestoreAppointmentsRemote(dio);
  });

  String expectedCollection(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/appointments';

  Map<String, dynamic> buildDocBody({
    required String name,
    required String title,
    String? description,
    String? location,
  }) {
    return <String, dynamic>{
      'name': name,
      'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
        'title': title,
        'description': ?description,
        'location': ?location,
        'dateTime': DateTime.utc(2026, 6, 1, 9),
        'isDone': false,
        'createdAt': DateTime.utc(2026, 1, 1),
        'updatedAt': DateTime.utc(2026, 1, 1),
      })['fields'],
    };
  }

  group('FirestoreAppointmentsRemote', () {
    test('listAppointments returns parsed entities', () async {
      final body = <String, dynamic>{
        'documents': [
          buildDocBody(
            name:
                'projects/p/databases/(default)/documents/users/u1/appointments/a1',
            title: 'Dentista',
            location: 'Calle Mayor 1',
          ),
        ],
      };
      stubDioGet(dio, body: body, withQueryParameters: true);

      final appointments = await remote.listAppointments(uid: 'u1');

      expect(appointments, hasLength(1));
      expect(appointments.first.id, 'a1');
      expect(appointments.first.title, 'Dentista');
      expect(appointments.first.location, 'Calle Mayor 1');
      verify(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).called(1);
    });

    test('createAppointment posts and decodes', () async {
      final body = buildDocBody(
        name:
            'projects/p/databases/(default)/documents/users/u1/appointments/a2',
        title: 'Médico',
        description: 'Revisión',
      );
      stubDioPost(dio, body: body);

      final created = await remote.createAppointment(
        uid: 'u1',
        title: 'Médico',
        description: 'Revisión',
        dateTime: DateTime.utc(2026, 6, 1, 9),
      );

      expect(created.id, 'a2');
      expect(created.title, 'Médico');
      expect(created.description, 'Revisión');
      verify(() => dio.post<Map<String, dynamic>>(
            expectedCollection('u1'),
            data: any(named: 'data'),
          )).called(1);
    });

    test('updateAppointment sends an updateMask with only the patched fields',
        () async {
      final body = buildDocBody(
        name:
            'projects/p/databases/(default)/documents/users/u1/appointments/a1',
        title: 'Dentista',
      );
      stubDioPatch(dio, body: body);

      await remote.updateAppointment(
        uid: 'u1',
        id: 'a1',
        isDone: true,
      );

      verify(() => dio.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(
              named: 'queryParameters',
              that: predicate<Map<String, dynamic>>(
                (q) {
                  final mask = q['updateMask.fieldPaths'] as List<dynamic>?;
                  if (mask == null) return false;
                  final list = mask.cast<String>();
                  return list.contains('isDone') &&
                      list.contains('updatedAt') &&
                      !list.contains('title') &&
                      !list.contains('location');
                },
              ),
            ),
          )).called(1);
    });

    test('deleteAppointment calls the right URL', () async {
      stubDioDelete(dio);

      await remote.deleteAppointment(uid: 'u1', id: 'a1');

      verify(() => dio.delete<void>('${expectedCollection('u1')}/a1'))
          .called(1);
    });

    test('restoreAppointment vuelve a escribir el documento con su id',
        () async {
      final body = buildDocBody(
        name:
            'projects/p/databases/(default)/documents/users/u1/appointments/a1',
        title: 'Dentista',
      );
      stubDioPatch(dio, body: body);

      final restored = await remote.restoreAppointment(
        uid: 'u1',
        appointment: buildAppointment(id: 'a1'),
      );

      expect(restored.id, 'a1');
      verify(() => dio.patch<Map<String, dynamic>>(
            '${expectedCollection('u1')}/a1',
            data: any(named: 'data'),
          )).called(1);
    });
  });
}
