import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/data/local/database_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../data/datasources/firestore_trash_remote.dart';
import '../../data/datasources/trash_pending_store.dart';
import '../../data/repositories/trash_repository_impl.dart';
import '../../domain/entities/trash_entry.dart';
import '../../domain/repositories/trash_repository.dart';
import 'trash_state.dart';

final firestoreTrashRemoteProvider = Provider<FirestoreTrashRemote>((ref) {
  return FirestoreTrashRemote(ref.watch(dioClientProvider).instance);
});

final trashRepositoryProvider = Provider<TrashRepository>((ref) {
  final repo = TrashRepositoryImpl(
    ref.watch(firestoreTrashRemoteProvider),
    pending: DriftTrashPendingStore(ref.watch(trashPendingDaoProvider)),
    pollInterval: ref.watch(pollIntervalProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// La papelera de la cuenta activa, reactiva a lo que se vaya borrando.
class TrashNotifier extends Notifier<TrashState> {
  StreamSubscription<List<TrashEntry>>? _sub;

  @override
  TrashState build() {
    final auth = ref.watch(authProvider);
    if (auth is! Authenticated) return const TrashInitial();

    _sub?.cancel();
    _sub = ref.read(trashRepositoryProvider).watch(auth.user.uid).listen(
          (entries) => state = TrashData(entries),
          onError: (Object e, StackTrace st) {
            if (state is! TrashData) {
              state = TrashError(e is Failure ? e : const UnknownFailure());
            }
            // Si ya hay papelera en pantalla, descartamos el error transitorio
            // (siguiente poll lo arreglará).
          },
        );
    ref.onDispose(() => _sub?.cancel());

    return const TrashLoading();
  }

  /// Saca de la papelera lo que se acaba de devolver a Firestore.
  Future<void> remove(List<TrashEntry> entries) async {
    await ref.read(trashRepositoryProvider).remove(
          uid: _uid,
          ids: entries.map((entry) => entry.id).toList(growable: false),
        );
  }

  Future<void> empty() async {
    await ref.read(trashRepositoryProvider).empty(_uid);
  }

  String get _uid => (ref.read(authProvider) as Authenticated).user.uid;
}

final trashProvider = NotifierProvider<TrashNotifier, TrashState>(
  TrashNotifier.new,
);

/// Vacía la papelera sola cuando le toca.
///
/// Lo activa `app.dart`, así que corre al abrir la app con sesión y cada vez que
/// cambia el plazo elegido: no hace falta entrar en la papelera para que la
/// cuenta se vaya limpiando. Best-effort — si falla, la próxima apertura lo
/// vuelve a intentar.
final trashPurgeProvider = Provider<void>((ref) {
  final repo = ref.watch(trashRepositoryProvider);

  void purge() {
    // Sin preferencias leídas no se sabe qué plazo hay guardado, y purgar con
    // el de fábrica borraría de más a quien tenga «nunca».
    final days = switch (ref.read(settingsProvider)) {
      SettingsData(:final settings) => settings.trashRetentionDays,
      _ => null,
    };
    final uid = switch (ref.read(authProvider)) {
      Authenticated(:final user) => user.uid,
      _ => null,
    };
    if (days == null || uid == null) return;

    unawaited(repo.purgeExpired(uid: uid, days: days));
  }

  ref.listen(authProvider, (_, _) => purge());
  ref.listen(settingsProvider, (_, _) => purge());
  purge();
});
