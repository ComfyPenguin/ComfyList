/// Constantes de rutas de la app.
class Routes {
  Routes._();

  static const String home = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String settings = '/settings';

  // Listas de tareas
  static const String todoLists = '/lists';
  static const String todoListNew = '/lists/new';
  static String todoListEdit(String listId) => '/lists/$listId/edit';

  // Tareas dentro de una lista
  static String todoList(String listId) => '/lists/$listId';
  static String todoNew(String listId) => '/lists/$listId/todos/new';
  static String todoEdit(String listId, String todoId) =>
      '/lists/$listId/todos/$todoId';

  // Citas
  static const String appointments = '/appointments';
  static const String appointmentNew = '/appointments/new';
  static String appointmentEdit(String id) => '/appointments/$id/edit';
  static String appointmentDetail(String id) =>
      '/appointments/$id/detail';
}
