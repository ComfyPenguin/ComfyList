import 'package:flutter/foundation.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../domain/entities/trash_entry.dart';

@immutable
sealed class TrashState {
  const TrashState();
}

class TrashInitial extends TrashState {
  const TrashInitial();
}

class TrashLoading extends TrashState {
  const TrashLoading();
}

class TrashData extends TrashState {
  const TrashData(this.entries);
  final List<TrashEntry> entries;
}

class TrashError extends TrashState {
  const TrashError(this.failure);
  final Failure failure;
}
