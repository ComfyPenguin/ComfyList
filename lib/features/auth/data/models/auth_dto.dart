/// Respuesta de Identity Toolkit para signUp y signInWithPassword.
class IdentityAuthResponse {
  IdentityAuthResponse({
    required this.idToken,
    required this.refreshToken,
    required this.localId,
    required this.email,
    this.displayName,
  });

  final String idToken;
  final String refreshToken;
  final String localId; // uid
  final String email;
  final String? displayName;

  factory IdentityAuthResponse.fromJson(Map<String, dynamic> json) {
    return IdentityAuthResponse(
      idToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String,
      localId: json['localId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
    );
  }
}

/// Respuesta de `accounts:lookup`. La API devuelve `users` como lista —
/// solo nos interesa el primero.
class IdentityLookupUser {
  IdentityLookupUser({
    required this.localId,
    required this.email,
    this.displayName,
  });

  final String localId;
  final String email;
  final String? displayName;

  factory IdentityLookupUser.fromJson(Map<String, dynamic> json) {
    return IdentityLookupUser(
      localId: json['localId'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
    );
  }
}
