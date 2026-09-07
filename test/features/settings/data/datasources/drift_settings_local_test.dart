import 'package:comfy_list/features/settings/data/datasources/drift_settings_local.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:comfy_list/shared/data/local/daos/settings_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsDao extends Mock implements SettingsDao {}

void main() {
  late _MockSettingsDao dao;
  late DriftSettingsLocal local;

  setUp(() {
    dao = _MockSettingsDao();
    local = DriftSettingsLocal(dao);
  });

  group('DriftSettingsLocal.getOrCreate', () {
    test('delega en el DAO y devuelve la misma fila', () async {
      final row = SettingsRow(
        id: 1,
        themeMode: 'dark',
        notificationsEnabled: true,
        appointmentsCompletionEnabled: false,
        completedToBottom: true,
        appointmentsCompletedToBottom: true,
        invertSwipeActions: false,
        use24HourFormat: true,
        updatedAt: DateTime.utc(2026, 6, 30, 12),
      );
      when(() => dao.getOrCreate()).thenAnswer((_) async => row);

      final result = await local.getOrCreate();

      expect(result.themeMode, 'dark');
      verify(() => dao.getOrCreate()).called(1);
    });
  });

  group('DriftSettingsLocal.updateThemeMode', () {
    test('reenvía el string al DAO sin transformación', () async {
      when(() => dao.updateThemeMode(any())).thenAnswer((_) async {});

      await local.updateThemeMode('dark');

      verify(() => dao.updateThemeMode('dark')).called(1);
    });

    test('reenvía "light" y "system" literalmente', () async {
      when(() => dao.updateThemeMode(any())).thenAnswer((_) async {});

      await local.updateThemeMode('light');
      await local.updateThemeMode('system');

      verify(() => dao.updateThemeMode('light')).called(1);
      verify(() => dao.updateThemeMode('system')).called(1);
    });
  });

  group('DriftSettingsLocal.update* booleanas', () {
    test('reenvían el bool al DAO', () async {
      when(() => dao.updateNotificationsEnabled(any())).thenAnswer((_) async {});
      when(() => dao.updateAppointmentsCompletionEnabled(any()))
          .thenAnswer((_) async {});
      when(() => dao.updateCompletedToBottom(any())).thenAnswer((_) async {});
      when(() => dao.updateAppointmentsCompletedToBottom(any()))
          .thenAnswer((_) async {});
      when(() => dao.updateInvertSwipeActions(any())).thenAnswer((_) async {});
      when(() => dao.updateUse24HourFormat(any())).thenAnswer((_) async {});

      await local.updateNotificationsEnabled(false);
      await local.updateAppointmentsCompletionEnabled(true);
      await local.updateCompletedToBottom(false);
      await local.updateAppointmentsCompletedToBottom(false);
      await local.updateInvertSwipeActions(true);
      await local.updateUse24HourFormat(false);

      verify(() => dao.updateNotificationsEnabled(false)).called(1);
      verify(() => dao.updateAppointmentsCompletionEnabled(true)).called(1);
      verify(() => dao.updateCompletedToBottom(false)).called(1);
      verify(() => dao.updateAppointmentsCompletedToBottom(false)).called(1);
      verify(() => dao.updateInvertSwipeActions(true)).called(1);
      verify(() => dao.updateUse24HourFormat(false)).called(1);
    });
  });
}
