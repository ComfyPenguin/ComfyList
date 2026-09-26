// ignore_for_file: prefer_const_constructors

import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/auth/domain/entities/auth_user.dart';
import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter/material.dart';

/// Builders tipados para los tests de features. Cada builder acepta named
/// optionals que casan con el constructor de la entidad; los defaults son
/// valores realistas en español y `DateTime.now().toUtc()` para fechas.
///
/// Los builders son funciones puras (sin I/O, sin `Random`, sin estado
/// compartido) — son seguros en tests paralelos.
AuthUser buildAuthUser({
  String uid = 'u1',
  String email = 'a@b.c',
  String? displayName,
  bool? emailVerified = true,
}) {
  return AuthUser(
    uid: uid,
    email: email,
    displayName: displayName,
    emailVerified: emailVerified,
  );
}

Todo buildTodo({
  String id = 't1',
  String title = 'Comprar pan',
  String? description,
  bool isDone = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now().toUtc();
  return Todo(
    id: id,
    title: title,
    description: description,
    isDone: isDone,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

TodoList buildTodoList({
  String id = 'L1',
  String name = 'Compras',
  String iconKey = 'cart',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now().toUtc();
  return TodoList(
    id: id,
    name: name,
    iconKey: iconKey,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

Appointment buildAppointment({
  String id = 'a1',
  String title = 'Dentista',
  String? description,
  String? location,
  DateTime? dateTime,
  bool isDone = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now().toUtc();
  return Appointment(
    id: id,
    title: title,
    description: description,
    location: location,
    dateTime: dateTime ?? now.add(const Duration(hours: 1)),
    isDone: isDone,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

AppSettings buildAppSettings({
  ThemeMode? themeMode,
  bool? notificationsEnabled,
  bool? appointmentsCompletionEnabled,
  bool? completedToBottom,
  bool? appointmentsCompletedToBottom,
  bool? appointmentsTodayOnTop,
  bool? invertSwipeActions,
  bool? use24HourFormat,
  List<int>? appointmentReminderMinutes,
  bool? longPressHintSeen,
}) {
  return AppSettings(
    themeMode: themeMode ?? AppSettings.defaults.themeMode,
    notificationsEnabled:
        notificationsEnabled ?? AppSettings.defaults.notificationsEnabled,
    appointmentsCompletionEnabled:
        appointmentsCompletionEnabled ??
        AppSettings.defaults.appointmentsCompletionEnabled,
    completedToBottom:
        completedToBottom ?? AppSettings.defaults.completedToBottom,
    appointmentsCompletedToBottom:
        appointmentsCompletedToBottom ??
        AppSettings.defaults.appointmentsCompletedToBottom,
    appointmentsTodayOnTop:
        appointmentsTodayOnTop ?? AppSettings.defaults.appointmentsTodayOnTop,
    invertSwipeActions:
        invertSwipeActions ?? AppSettings.defaults.invertSwipeActions,
    use24HourFormat: use24HourFormat ?? AppSettings.defaults.use24HourFormat,
    appointmentReminderMinutes:
        appointmentReminderMinutes ??
        AppSettings.defaults.appointmentReminderMinutes,
    longPressHintSeen:
        longPressHintSeen ?? AppSettings.defaults.longPressHintSeen,
  );
}

/// Fila de settings en formato Drift. Útil para tests de DAO y de
/// `SettingsRepositoryImpl` que mapean `SettingsRow` → `AppSettings`.
SettingsRow buildSettingsRow({
  int id = 1,
  String themeMode = 'system',
  bool notificationsEnabled = true,
  bool appointmentsCompletionEnabled = false,
  bool completedToBottom = true,
  bool appointmentsCompletedToBottom = true,
  bool appointmentsTodayOnTop = true,
  bool invertSwipeActions = false,
  bool use24HourFormat = true,
  String appointmentReminderMinutes = '30',
  bool longPressHintSeen = false,
  DateTime? updatedAt,
}) {
  return SettingsRow(
    id: id,
    themeMode: themeMode,
    notificationsEnabled: notificationsEnabled,
    appointmentsCompletionEnabled: appointmentsCompletionEnabled,
    completedToBottom: completedToBottom,
    appointmentsCompletedToBottom: appointmentsCompletedToBottom,
    appointmentsTodayOnTop: appointmentsTodayOnTop,
    invertSwipeActions: invertSwipeActions,
    use24HourFormat: use24HourFormat,
    appointmentReminderMinutes: appointmentReminderMinutes,
    longPressHintSeen: longPressHintSeen,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
  );
}

AccountCacheRow buildAccountCacheRow({
  String uid = 'u1',
  String email = 'a@b.c',
  String? displayName,
  DateTime? cachedAt,
}) {
  return AccountCacheRow(
    uid: uid,
    email: email,
    displayName: displayName,
    cachedAt: cachedAt ?? DateTime.now().toUtc(),
  );
}

/// Construye un documento REST de Firestore con la forma que esperan los
/// DTOs de feature (`TodoListDto.fromDocument`, `TodoDto.fromDocument`, etc.).
Map<String, dynamic> buildFirestoreDocument({
  required String name,
  required Map<String, dynamic> fields,
}) {
  return <String, dynamic>{
    'name': name,
    'fields': FirestoreValueCodec.encodeFields(fields)['fields'],
  };
}

/// Tipos de error canónicos para tests que necesitan una `Failure` concreta
/// sin tener que importar todas las subclases del sealed `Failure`.
enum FailureKind {
  network,
  timeout,
  server,
  auth,
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  googleSignInCancelled,
  googleSignInFailure,
  notFound,
  validation,
  cache,
  unknown,
}

Failure buildFailure(FailureKind kind) {
  return switch (kind) {
    FailureKind.network => const NetworkFailure(),
    FailureKind.timeout => const TimeoutFailure(),
    FailureKind.server => const ServerFailure(),
    FailureKind.auth => const AuthFailure(),
    FailureKind.invalidCredentials => const InvalidCredentialsFailure(),
    FailureKind.emailAlreadyInUse => const EmailAlreadyInUseFailure(),
    FailureKind.weakPassword => const WeakPasswordFailure(),
    FailureKind.googleSignInCancelled => const GoogleSignInCancelledFailure(),
    FailureKind.googleSignInFailure => const GoogleSignInFailure(),
    FailureKind.notFound => const NotFoundFailure(),
    FailureKind.validation => const ValidationFailure('Datos no válidos.'),
    FailureKind.cache => const CacheFailure(),
    FailureKind.unknown => const UnknownFailure(),
  };
}
