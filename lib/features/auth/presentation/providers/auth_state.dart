import 'package:flutter/foundation.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../domain/entities/auth_user.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AuthUser user;
}

/// Sesión válida, pero el correo todavía no está verificado: la app no deja
/// pasar hasta que el usuario abra el enlace del correo.
class AuthUnverifiedEmail extends AuthState {
  const AuthUnverifiedEmail(this.user);
  final AuthUser user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.failure);
  final Failure failure;
}
