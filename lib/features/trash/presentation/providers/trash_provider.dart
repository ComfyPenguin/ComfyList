import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/data/local/database_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/datasources/drift_trash_local.dart';
import '../../data/repositories/trash_repository_impl.dart';
import '../../domain/entities/trash_entry.dart';
import '../../domain/repositories/trash_repository.dart';
import 'trash_state.dart';

final trashLocalProvider = Provider<DriftTrashLocal>((ref) {
  return DriftTrashLocal(ref.watch(trashDaoProvider));
});

final trashRepositoryProvider = Provider<TrashRepository>((ref) {
  return TrashRepositoryImpl(ref.watch(trashLocalProvider));
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
          onError: (Object _) => state = const TrashError(CacheFailure()),
        );
    ref.onDispose(() => _sub?.cancel());

    return const TrashLoading();
  }

  /// Saca de la papelera lo que se acaba de devolver a Firestore.
  Future<void> remove(List<TrashEntry> entries) async {
    await ref
        .read(trashRepositoryProvider)
        .remove(entries.map((entry) => entry.rowId).toList(growable: false));
  }

  Future<void> empty() async {
    await ref.read(trashRepositoryProvider).empty(_uid);
  }

  String get _uid => (ref.read(authProvider) as Authenticated).user.uid;
}

final trashProvider = NotifierProvider<TrashNotifier, TrashState>(
  TrashNotifier.new,
);
