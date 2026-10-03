// Endpoints REST de Firebase usados por DioClient.
// Los valores de apiKey y projectId se extrajeron de firebase_options.dart
// (NO son secretos: la API key de Firebase es pública por diseño; las
// reglas de Firestore son lo que protege los datos).
class FirebaseEndpoints {
  FirebaseEndpoints._();

  static const String projectId = 'comfy-list';

  // Permite override en build vía --dart-define=FIREBASE_API_KEY=...
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyD-y9qLbk5IUqS6cyGFAp2O94KAtxvulfI',
  );

  // Web Client ID OAuth (client_type 3 en google-services.json).
  // Necesario como `serverClientId` en GoogleSignIn.initialize() para que
  // Google devuelva un ID token verificable por Firebase Identity Toolkit.
  // TODO: Override en build vía --dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=...
  static const String googleSignInWebClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_WEB_CLIENT_ID',
    defaultValue:
        '49265233072-ubk0m1nsashs18f8fdi4krai0o9be5bn.apps.googleusercontent.com',
  );

  // Identity Toolkit (auth)
  static const String identityBase =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  // Refresco de tokens
  static const String tokenBase = 'https://securetoken.googleapis.com/v1/token';

  // Firestore REST
  static const String firestoreBase =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
}
