import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../trash/domain/entities/trash_entry.dart';
import '../../../trash/presentation/providers/trash_provider.dart';
import '../../data/datasources/firestore_appointments_remote.dart';
import '../../data/repositories/appointments_repository_impl.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointments_repository.dart';
import 'appointments_state.dart';

final firestoreAppointmentsRemoteProvider =
    Provider<FirestoreAppointmentsRemote>((ref) {
  return FirestoreAppointmentsRemote(ref.watch(dioClientProvider).instance);
});

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  final repo = AppointmentsRepositoryImpl(
    ref.watch(firestoreAppointmentsRemoteProvider),
    pollInterval: ref.watch(pollIntervalProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Notifier de citas. Es un Notifier simple (sin family).
///
/// Cuando el [authProvider] cambia (login/logout), `build` se re-ejecuta
/// y la suscripción al watcher se renueva.
class AppointmentsNotifier extends Notifier<AppointmentsState> {
  StreamSubscription<dynamic>? _sub;

  @override
  AppointmentsState build() {
    final auth = ref.watch(authProvider);
    if (auth is! Authenticated) return const AppointmentsInitial();

    final uid = auth.user.uid;
    final repo = ref.read(appointmentsRepositoryProvider);

    _sub?.cancel();
    _sub = repo.watchAppointments(uid).listen(
      (items) => state = AppointmentsData(items),
      onError: (Object e, StackTrace st) {
        if (state is! AppointmentsData) {
          state = AppointmentsError(e is Failure ? e : const UnknownFailure());
        }
        // Si ya tenemos datos en pantalla, descartamos el error transitorio
        // (siguiente poll lo arreglará). Evita parpadeo de error tras resume.
      },
    );
    ref.onDispose(() => _sub?.cancel());

    return const AppointmentsLoading();
  }

  String get _uid => (ref.read(authProvider) as Authenticated).user.uid;

  Future<void> create({
    required String title,
    String? description,
    String? location,
    required DateTime dateTime,
  }) async {
    final res = await ref.read(appointmentsRepositoryProvider).createAppointment(
          uid: _uid,
          title: title,
          description: description,
          location: location,
          dateTime: dateTime,
        );
    res.fold(onOk: (_) {}, onErr: (f) => state = AppointmentsError(f));
  }

  Future<void> toggleDone(String id, bool isDone) async {
    await ref.read(appointmentsRepositoryProvider).updateAppointment(
          uid: _uid,
          id: id,
          isDone: isDone,
        );
  }

  Future<void> updateFields({
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    DateTime? dateTime,
  }) async {
    await ref.read(appointmentsRepositoryProvider).updateAppointment(
          uid: _uid,
          id: id,
          title: title,
          description: description,
          clearDescription: clearDescription,
          location: location,
          clearLocation: clearLocation,
          dateTime: dateTime,
        );
  }

  Future<void> delete(String id) async {
    final appointment = _findById(id);
    if (appointment != null) {
      await ref.read(trashRepositoryProvider).save(
            uid: _uid,
            items: [
              TrashItem(
                kind: TrashKind.appointment,
                itemId: appointment.id,
                label: appointment.title,
                payload: appointment.toJson(),
              ),
            ],
          );
    }

    await ref.read(appointmentsRepositoryProvider).deleteAppointment(
          uid: _uid,
          id: id,
        );
  }

  /// Devuelve la última cita borrada. Devuelve si se pudo.
  Future<bool> undoLastDelete() async {
    final trash = ref.read(trashRepositoryProvider);
    final entries = await trash.latestGroup(
      uid: _uid,
      kind: TrashKind.appointment,
    );
    if (entries.isEmpty) return false;

    final repo = ref.read(appointmentsRepositoryProvider);
    for (final entry in entries) {
      final res = await repo.restoreAppointment(
        uid: _uid,
        appointment: Appointment.fromJson(entry.payload),
      );
      if (res.isErr) return false;
    }

    await trash.remove(entries.map((entry) => entry.rowId).toList());
    return true;
  }

  Appointment? _findById(String id) {
    final current = state;
    if (current is! AppointmentsData) return null;
    for (final appointment in current.items) {
      if (appointment.id == id) return appointment;
    }
    return null;
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, AppointmentsState>(
  AppointmentsNotifier.new,
);
