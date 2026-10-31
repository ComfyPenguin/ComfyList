import 'package:comfy_list/features/auth/presentation/providers/auth_provider.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todo_lists/domain/repositories/todo_lists_repository.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/features/trash/domain/repositories/trash_repository.dart';
import 'package:comfy_list/features/trash/presentation/providers/trash_provider.dart';
import 'package:comfy_list/features/trash/presentation/screens/trash_screen.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockListsRepo extends Mock implements TodoListsRepository {}

class _MockTodosRepo extends Mock implements TodosRepository {}

/// Papelera de mentira: sirve lo que se le dé y apunta lo que se quita.
class _FixedTrashRepository implements TrashRepository {
  _FixedTrashRepository(this.entries);

  List<TrashEntry> entries;
  final List<String> removed = [];

  @override
  Stream<List<TrashEntry>> watch(String uid) => Stream.value(entries);

  @override
  Future<Result<void>> remove({
    required String uid,
    required List<String> ids,
  }) async {
    removed.addAll(ids);
    entries = entries.where((entry) => !ids.contains(entry.id)).toList();
    return const Ok(null);
  }

  @override
  Future<Result<List<TrashEntry>>> list(String uid) async => Ok(entries);

  @override
  Future<Result<void>> empty(String uid) async {
    entries = [];
    return const Ok(null);
  }

  @override
  Future<Result<List<TrashEntry>>> save({
    required String uid,
    required List<TrashItem> items,
  }) async => const Ok([]);

  @override
  Future<Result<void>> purgeExpired({
    required String uid,
    required int days,
  }) async => const Ok(null);
}

void main() {
  late _MockListsRepo listsRepo;
  late _MockTodosRepo todosRepo;
  late _FixedTrashRepository trash;

  setUpAll(() async {
    // mocktail necesita un valor de relleno para los matchers de entidades.
    registerFallbackValue(buildTodoList());
    registerFallbackValue(buildTodo());
    registerFallbackValue(<Todo>[]);

    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  setUp(() {
    listsRepo = _MockListsRepo();
    todosRepo = _MockTodosRepo();
    when(() => todosRepo.refresh(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
        )).thenAnswer((_) async {});
  });

  TrashEntry entry({
    required String id,
    required TrashKind kind,
    required String itemId,
    required String label,
    required Map<String, dynamic> payload,
    String group = 'g1',
    String? parentId,
  }) {
    return TrashEntry(
      id: id,
      uid: 'u1',
      groupId: group,
      deletedAt: DateTime.now().toUtc(),
      item: TrashItem(
        kind: kind,
        itemId: itemId,
        parentId: parentId,
        label: label,
        payload: payload,
      ),
    );
  }

  /// Una lista con dos tareas, borradas de una vez.
  void seedListWithTasks() {
    final list = buildTodoList(id: 'L1', name: 'Compras');
    trash = _FixedTrashRepository([
      entry(
        id: 'd1',
        kind: TrashKind.todo,
        itemId: 't1',
        parentId: 'L1',
        label: 'Pan',
        payload: buildTodo(id: 't1', title: 'Pan').toJson(),
      ),
      entry(
        id: 'd2',
        kind: TrashKind.list,
        itemId: 'L1',
        label: 'Compras',
        payload: list.toJson(),
      ),
      entry(
        id: 'd3',
        kind: TrashKind.todo,
        itemId: 't2',
        parentId: 'L1',
        label: 'Leche',
        payload: buildTodo(id: 't2', title: 'Leche').toJson(),
      ),
    ]);
  }

  /// La tarea se borró primero y la lista después: dos borrados, pero la tarea
  /// no puede volver sin la lista.
  void seedTaskThenList() {
    final list = buildTodoList(id: 'L1', name: 'Compras');
    trash = _FixedTrashRepository([
      entry(
        id: 'd3',
        group: 'g2',
        kind: TrashKind.todo,
        itemId: 't2',
        parentId: 'L1',
        label: 'Pan',
        payload: buildTodo(id: 't2', title: 'Pan').toJson(),
      ),
      entry(
        id: 'd2',
        kind: TrashKind.list,
        itemId: 'L1',
        label: 'Compras',
        payload: list.toJson(),
      ),
      entry(
        id: 'd1',
        kind: TrashKind.todo,
        itemId: 't1',
        parentId: 'L1',
        label: 'Leche',
        payload: buildTodo(id: 't1', title: 'Leche').toJson(),
      ),
    ]);
  }

  /// Papelera llena: un borrado por cada hueco del tope.
  void seedFullTrash() {
    trash = _FixedTrashRepository([
      for (var i = 0; i < TrashRepository.maxGroupsPerUid; i++)
        entry(
          id: 'd$i',
          group: 'g$i',
          kind: TrashKind.todo,
          itemId: 't$i',
          label: 'Tarea $i',
          payload: buildTodo(id: 't$i', title: 'Tarea $i').toJson(),
        ),
    ]);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => StaticAuthNotifier(Authenticated(buildAuthUser())),
          ),
          trashRepositoryProvider.overrideWithValue(trash),
          todoListsRepositoryProvider.overrideWithValue(listsRepo),
          todosRepositoryProvider.overrideWithValue(todosRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          // La pantalla vive dentro del Scaffold del shell.
          home: const Scaffold(body: TrashScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('una lista con sus tareas es una sola fila', (tester) async {
    seedListWithTasks();
    await pumpScreen(tester);

    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('1 borrado guardado'), findsOneWidget);
    expect(find.text('Lista · hoy · 2 tareas'), findsOneWidget);

    // Lo de dentro está, pero recogido: ni se ve ni se toca.
    expect(find.text('Pan').hitTestable(), findsNothing);
    expect(find.text('Leche').hitTestable(), findsNothing);
    expect(find.text('Ver las 2 tareas'), findsOneWidget);
  });

  testWidgets('el desplegable enseña las tareas que se llevó', (tester) async {
    seedListWithTasks();
    await pumpScreen(tester);

    await tester.tap(find.text('Ver las 2 tareas'));
    await tester.pumpAndSettle();

    expect(find.text('Pan').hitTestable(), findsOneWidget);
    expect(find.text('Leche').hitTestable(), findsOneWidget);
    expect(find.text('Ocultar'), findsOneWidget);

    // Y se vuelve a recoger por donde se abrió.
    await tester.tap(find.text('Ocultar'));
    await tester.pumpAndSettle();
    expect(find.text('Pan').hitTestable(), findsNothing);
  });

  testWidgets('una tarea borrada antes que su lista sale dentro de ella',
      (tester) async {
    seedTaskThenList();
    await pumpScreen(tester);

    // Una sola fila: la tarea no puede volver sin la lista, así que no tiene
    // un restaurar propio.
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('1 borrado guardado'), findsOneWidget);
    expect(find.text('Lista · hoy · 2 tareas'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);
  });

  testWidgets('restaurar esa lista devuelve también la tarea que colgaba',
      (tester) async {
    seedTaskThenList();
    when(() => listsRepo.restoreList(
          uid: 'u1',
          list: any(named: 'list'),
          todos: any(named: 'todos'),
        ))
        .thenAnswer((_) async => const Ok(null));

    await pumpScreen(tester);
    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    final todos = verify(
      () => listsRepo.restoreList(
        uid: 'u1',
        list: any(named: 'list'),
        todos: captureAny(named: 'todos'),
      ),
    ).captured.single as List<Todo>;
    expect(todos, hasLength(2));
    // La lista, su tarea y la que ya estaba borrada antes.
    expect(trash.removed, ['d2', 'd1', 'd3']);
  });

  testWidgets('restaurar devuelve la lista con sus tareas enteras',
      (tester) async {
    seedListWithTasks();
    when(() => listsRepo.restoreList(
          uid: 'u1',
          list: any(named: 'list'),
          todos: any(named: 'todos'),
        ))
        .thenAnswer((_) async => const Ok(null));

    await pumpScreen(tester);
    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    // Todas las tareas van con la lista, aunque no se haya desplegado nada.
    final todos = verify(
      () => listsRepo.restoreList(
        uid: 'u1',
        list: any(named: 'list'),
        todos: captureAny(named: 'todos'),
      ),
    ).captured.single as List<Todo>;
    expect(todos, hasLength(2));
    expect(trash.removed, ['d2', 'd1', 'd3']);
  });

  testWidgets('con la papelera llena avisa de que descarta lo más viejo',
      (tester) async {
    seedFullTrash();
    await pumpScreen(tester);

    expect(find.text('100 borrados guardados'), findsOneWidget);
    expect(find.textContaining('más recientes'), findsOneWidget);
  });

  testWidgets('con sitio de sobra no hay aviso', (tester) async {
    seedListWithTasks();
    await pumpScreen(tester);

    expect(find.textContaining('más recientes'), findsNothing);
  });

  testWidgets('el aviso cuenta huecos guardados, no filas', (tester) async {
    // 98 borrados sueltos, una lista con su tarea y una tarea que se borró
    // antes que la lista: 100 huecos ocupados, pero la pantalla junta la tarea
    // con la lista y solo enseña 99 filas.
    final list = buildTodoList(id: 'L1', name: 'Compras');
    trash = _FixedTrashRepository([
      entry(
        id: 'hanging',
        group: 'gOrphan',
        kind: TrashKind.todo,
        itemId: 't0',
        parentId: 'L1',
        label: 'Pan',
        payload: buildTodo(id: 't0', title: 'Pan').toJson(),
      ),
      entry(
        id: 'dList',
        group: 'gList',
        kind: TrashKind.list,
        itemId: 'L1',
        label: 'Compras',
        payload: list.toJson(),
      ),
      entry(
        id: 'dTask',
        group: 'gList',
        kind: TrashKind.todo,
        itemId: 't1',
        parentId: 'L1',
        label: 'Leche',
        payload: buildTodo(id: 't1', title: 'Leche').toJson(),
      ),
      for (var i = 0; i < 98; i++)
        entry(
          id: 'd$i',
          group: 'g$i',
          kind: TrashKind.todo,
          itemId: 'x$i',
          label: 'Tarea $i',
          payload: buildTodo(id: 'x$i', title: 'Tarea $i').toJson(),
        ),
    ]);

    await pumpScreen(tester);

    expect(find.text('99 borrados guardados'), findsOneWidget);
    expect(find.textContaining('más recientes'), findsOneWidget);
  });
}
