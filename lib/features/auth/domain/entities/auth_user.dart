import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.emailVerified,
  });

  final String uid;
  final String email;
  final String? displayName;

  /// Lo que responde `accounts:lookup`. Es `null` cuando no hemos podido
  /// preguntarlo (arranque sin red, hidratado desde la caché local): no se
  /// deja fuera a nadie por no saberlo, y el corte de datos lo hace la regla
  /// de Firestore, que exige el correo verificado.
  final bool? emailVerified;
}
