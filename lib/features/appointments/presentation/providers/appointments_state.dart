import 'package:flutter/foundation.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../domain/entities/appointment.dart';

@immutable
sealed class AppointmentsState {
  const AppointmentsState();
}

class AppointmentsInitial extends AppointmentsState {
  const AppointmentsInitial();
}

class AppointmentsLoading extends AppointmentsState {
  const AppointmentsLoading();
}

class AppointmentsData extends AppointmentsState {
  const AppointmentsData(this.items);
  final List<Appointment> items;
}

class AppointmentsError extends AppointmentsState {
  const AppointmentsError(this.failure);
  final Failure failure;
}
