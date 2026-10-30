import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../../../todo_lists/presentation/providers/todo_lists_provider.dart';
import '../../../todos/presentation/providers/todos_provider.dart';
import '../../domain/deletions.dart';
import 'trash_provider.dart';

final deletionsProvider = Provider<Deletions>(
  (ref) => Deletions(
    trash: ref.watch(trashRepositoryProvider),
    todos: ref.watch(todosRepositoryProvider),
    lists: ref.watch(todoListsRepositoryProvider),
    appointments: ref.watch(appointmentsRepositoryProvider),
  ),
);
