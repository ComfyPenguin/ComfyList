import 'package:flutter/foundation.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../domain/entities/todo.dart';

@immutable
sealed class TodosState {
  const TodosState();
}

class TodosInitial extends TodosState {
  const TodosInitial();
}

class TodosLoading extends TodosState {
  const TodosLoading();
}

class TodosData extends TodosState {
  const TodosData(this.items);
  final List<Todo> items;
}

class TodosError extends TodosState {
  const TodosError(this.failure);
  final Failure failure;
}
