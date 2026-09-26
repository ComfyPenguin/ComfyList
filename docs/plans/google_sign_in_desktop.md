# Login con Google en Windows y Linux — plan

> Pendiente. Escrito el 26/09/2026 como contexto para implementarlo en una sesión aparte:
> pégame este fichero y se puede empezar sin rehacer el análisis.
>
> Ver también: `linux_desktop.md` y `windows_desktop.md`.

## Objetivo

Que en los builds de escritorio (**Windows** y **Linux**) se pueda entrar con Google, no solo
con correo y contraseña, **sin añadir el SDK de Firebase**: el flujo tiene que terminar en un
`id_token` de Google que se envíe a `accounts:signInWithIdp`, igual que se hace hoy en Android.

## Punto de partida (código actual)

- `lib/main.dart:33` — `GoogleSignIn.initialize(serverClientId: FirebaseEndpoints.googleSignInWebClientId)`
  solo bajo `Platform.isAndroid`.
- `lib/features/auth/presentation/widgets/google_sign_in_section.dart:28` —
  `if (kIsWeb || !Platform.isAndroid) return const SizedBox.shrink();` (botón oculto fuera de Android).
- `lib/features/auth/data/repositories/auth_repository_impl.dart:177` — `signInWithGoogle()`:
  paso 1 `GoogleSignIn.instance.authenticate()`, paso 2 `_remote.signInWithGoogle(googleIdToken:)`,
  y después guarda sesión en `SecureSessionStore` + `accountCache`.
- `lib/features/auth/data/datasources/identity_toolkit_remote.dart:47` — POST a
  `accounts:signInWithIdp` con `postBody: 'id_token=...&providerId=google.com'`,
  `requestUri: 'http://localhost'`, `returnIdpCredential` y `returnSecureToken`.
- `auth_repository_impl.dart:287` — `signOut()` ya envuelve `GoogleSignIn.instance.signOut()`
  en try-catch, así que hoy el logout no falla en escritorio.
- `FirebaseEndpoints.apiKey` está restringida a Identity Toolkit + Token Service + Firestore
  (ver AGENTS.md). El flujo nuevo **no necesita tocar esa lista**: el canje del `code` va a
  `oauth2.googleapis.com`, que no usa apiKey.
- Piezas que ya valen tal cual: `SecureSessionStore` (Windows DPAPI; Linux `libsecret` + keyring),
  la `sealed class` de `Failure`, `AuthState` y el propio botón.

## Por qué no vale `google_sign_in`

El plugin (7.x) solo implementa Android, iOS, macOS y web: en Windows y Linux
`GoogleSignIn.instance` no funciona. Alternativa descartada de momento:
`google_sign_in_all_platforms` (paquete de comunidad, sin vetar; evaluar solo si se prefiere
no escribir el flujo a mano).

## La vía: OAuth 2.0 nativo con redirect loopback (RFC 8252)

1. Crear en Google Cloud un cliente OAuth de tipo **Desktop app** en el proyecto `comfy-list`,
   con redirect `http://127.0.0.1:<puerto>`.
2. PKCE: `code_verifier` (43-128 caracteres, `[A-Za-z0-9-._~]`) y
   `code_challenge = BASE64URL(SHA256(verifier))`, método `S256`. Añadir un `state` aleatorio.
3. Abrir el navegador del sistema con `url_launcher` (**no está en `pubspec.yaml`**; hay que añadirlo):

   ```
   https://accounts.google.com/o/oauth2/v2/auth
     ?client_id=<desktop>
     &redirect_uri=http://127.0.0.1:<puerto>
     &response_type=code
     &scope=openid%20email%20profile
     &code_challenge=<...>&code_challenge_method=S256
     &state=<...>
   ```

4. Escuchar en loopback: `HttpServer.bind(InternetAddress.loopbackIPv4, 0)` (puerto aleatorio),
   recibir `code` y `state`, validar el `state`, responder una página de "ya puedes volver a la
   app" y cerrar el servidor.
5. Canjear el código: POST a `https://oauth2.googleapis.com/token` con `code`, `client_id`,
   `code_verifier`, `redirect_uri` y `grant_type=authorization_code`. De ahí sale el `id_token`.
6. Enviar ese `id_token` a `signInWithIdp` con el **mismo** `redirect_uri` como `requestUri`, y
   seguir el camino que ya existe (sesión + caché de cuenta).

## A verificar antes de escribir código (no dar por hecho)

1. **`requestUri`**: Identity Toolkit exige que coincida con el usado para obtener el token. Hoy
   está fijo a `http://localhost` (`identity_toolkit_remote.dart:57`). Si el puerto es aleatorio,
   ¿acepta `http://127.0.0.1:<puerto>`? Si no, usar un `requestUri` fijo registrado en el cliente
   OAuth y escuchar en ese puerto.
2. **`aud` del `id_token`**: confirmar que `signInWithIdp` acepta un token cuyo `aud` es el client
   ID de escritorio (debería, al ser del mismo proyecto). Probarlo con `curl` antes de escribir
   Dart: respuesta esperada con `localId`/`idToken`, error típico `INVALID_IDP_RESPONSE`.
3. **Puerto aleatorio en la consola**: comprobar si el cliente Desktop admite cualquier puerto
   loopback o si hay que registrar un redirect exacto.
4. **Pantalla de consentimiento**: si sigue en "Testing", solo entran los usuarios de prueba →
   publicarla (los scopes `openid email profile` no requieren verificación de Google).
5. **Linux**: `url_launcher` dentro de Snap/Flatpak sale por el portal del escritorio; y el
   keyring tiene que estar disponible o `SecureSessionStore` fallará al guardar la sesión.
6. **Windows desde la Store (UWP)**: sería otro tipo de cliente OAuth, con redirect `ms-app://`
   (no aplica al `.exe` normal).
7. Revisar si por entonces `google_sign_in` ya soporta escritorio: si es así, el plan se simplifica.

## Diseño propuesto

- `GoogleAuthFlow` (interfaz) en `lib/features/auth/data/datasources/`, con dos implementaciones:
  - `GoogleSignInPluginFlow` → el actual, para Android.
  - `GoogleLoopbackFlow` → escritorio: `url_launcher` + `HttpServer` + PKCE.
- Elegir implementación en un provider (p. ej. `googleAuthFlowProvider`), como el resto del
  proyecto: sin `get_it`, sin `Platform` repartido por las pantallas y sin lógica en la UI.
- `AuthRepositoryImpl.signInWithGoogle()` pasa a pedir el `id_token` al flow; el paso 2
  (`signInWithIdp`) no cambia.
- Errores: reutilizar `GoogleSignInCancelledFailure` y `GoogleSignInFailure`, y añadir un caso
  para "el usuario cerró el navegador / caducó la espera del redirect" como variante de la
  `sealed class` de `Failure`, nunca con excepciones sueltas.

## Criterios de aceptación

- `flutter analyze` limpio.
- Tests: `code_challenge` S256 contra un vector conocido, `state` inválido → error, canje con
  `Dio` mockeado (URL y `code_verifier`) y que el repositorio manda el `requestUri` correcto.
- A mano: login con Google en Windows y en Linux con una cuenta real, logout, y comprobar que el
  `idToken` guardado en `SecureSessionStore` sirve contra Firestore (las reglas exigen
  `email_verified`).
- El botón de Google visible en escritorio y ausente en web (sigue sin haber build web).

## No-objetivos

- Nada de SDK de Firebase (`cloud_firestore` / `firebase_auth` siguen prohibidos).
- No tocar la allowlist de la apiKey ni `firestore.rules`: el flujo reutiliza `signInWithIdp`.
