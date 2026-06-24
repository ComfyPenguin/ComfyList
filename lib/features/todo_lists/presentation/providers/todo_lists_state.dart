import 'package:flutter/foundation.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../domain/entities/todo_list.dart';

@immutable
sealed class TodoListsState {
  const TodoListsState();
}

class TodoListsInitial extends TodoListsState {
  const TodoListsInitial();
}

class TodoListsLoading extends TodoListsState {
  const TodoListsLoading();
}

class TodoListsData extends TodoListsState {
  const TodoListsData(this.items);
  final List<TodoList> items;
}

class TodoListsError extends TodoListsState {
  const TodoListsError(this.failure);
  final Failure failure;
}
