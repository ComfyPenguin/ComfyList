import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/account_cache_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/trash_dao.dart';

/// Singleton de [AppDatabase] al alcance de Riverpod.
/// Se sobreescribe en tests vía `ProviderScope(overrides: ...)`.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'Sobrescribe appDatabaseProvider en main() con la instancia inicializada.',
  ),
);

final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao,
);

final accountCacheDaoProvider = Provider<AccountCacheDao>(
  (ref) => ref.watch(appDatabaseProvider).accountCacheDao,
);

final trashDaoProvider = Provider<TrashDao>(
  (ref) => ref.watch(appDatabaseProvider).trashDao,
);
