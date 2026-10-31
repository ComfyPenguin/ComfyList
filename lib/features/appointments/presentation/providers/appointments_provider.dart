import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/lifecycle/polling_registry.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../trash/domain/entities/trash_group.dart';
import '../../../trash/presentation/providers/deletions_provider.dart';
import '../../data/datasources/firestore_appointments_remote.dart';
import '../../data/repositories/appointments_repository_impl.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/repositories/appointments_repository.dart';
import 'appointments_state.dart';

final firestoreAppointmentsRemoteProvider =
    Provider<FirestoreAppointmentsRemote>((ref) {
  return FirestoreAppointmentsRemote(
    ref.watch(dioClientProvider).instance,
    now: ref.watch(clockProvider),
  );
});

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  final repo = AppointmentsRepositoryImpl(
    ref.watch(firestoreAppointmentsRemoteProvider),
    pollInterval: ref.watch(pollIntervalProvider),
    registry: ref.watch(pollingRegistryProvider),
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

  /// Crea una cita. Devuelve si se pudo; si no, la lista cargada se queda como
  /// está y quien llama decide cómo avisar.
  Future<bool> create({
    required String title,
    String? description,
    String? location,
    RepeatRule? repeatRule,
    required List<int> reminderMinutes,
    required DateTime dateTime,
  }) async {
    final res = await ref.read(appointmentsRepositoryProvider).createAppointment(
          uid: ref.signedInUid,
          title: title,
          description: description,
          location: location,
          repeatRule: repeatRule,
          reminderMinutes: reminderMinutes,
          dateTime: dateTime,
        );
    return res.isOk;
  }

  /// Marca o desmarca una cita. Devuelve si se pudo guardar.
  ///
  /// Completar una cita recurrente no la deja hecha: salta a su siguiente fecha
  /// y sigue pendiente.
  Future<bool> toggleDone(String id, bool isDone) async {
    final appointment = _findById(id);
    final rule = appointment?.repeatRule;
    final advance = isDone && appointment != null && rule != null;
    final res = await ref.read(appointmentsRepositoryProvider).updateAppointment(
          uid: ref.signedInUid,
          id: id,
          isDone: advance ? null : isDone,
          dateTime: advance
              ? rule.nextAfter(
                  appointment.dateTime,
                  now: ref.read(clockProvider)(),
                )
              : null,
        );
    return res.isOk;
  }

  /// Guarda los cambios de una cita. Devuelve si se pudo guardar.
  Future<bool> updateFields({
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    RepeatRule? repeatRule,
    bool clearRepeatRule = false,
    List<int>? reminderMinutes,
    DateTime? dateTime,
  }) async {
    final res = await ref.read(appointmentsRepositoryProvider).updateAppointment(
          uid: ref.signedInUid,
          id: id,
          title: title,
          description: description,
          clearDescription: clearDescription,
          location: location,
          clearLocation: clearLocation,
          repeatRule: repeatRule,
          clearRepeatRule: clearRepeatRule,
          reminderMinutes: reminderMinutes,
          dateTime: dateTime,
        );
    return res.isOk;
  }

  /// Borra la cita con copia en la papelera. Devuelve el borrado, que es lo que
  /// hay que pasar a [undo], o `null` si no se pudo: sin copia no se borra.
  Future<TrashGroup?> delete(String id) async {
    final appointment = _findById(id);
    if (appointment == null) return null;

    final res = await ref.read(deletionsProvider).deleteAppointment(
          uid: ref.signedInUid,
          appointment: appointment,
        );
    return res.fold(onOk: (group) => group, onErr: (_) => null);
  }

  /// Devuelve [group], el borrado que acaba de hacer [delete]. Devuelve si se
  /// pudo.
  Future<bool> undo(TrashGroup group) =>
      ref.read(deletionsProvider).restore(group);

  Appointment? _findById(String id) => switch (state) {
        AppointmentsData(:final items) => items.where((e) => e.id == id).firstOrNull,
        _ => null,
      };
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, AppointmentsState>(
  AppointmentsNotifier.new,
);
