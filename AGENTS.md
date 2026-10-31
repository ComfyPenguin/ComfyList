# ComfyList

App de TODOs y citas con recordatorios, sincronizada vía Firebase. Android es la plataforma principal; web y escritorio están en camino.

## Comandos

```sh
flutter pub get --enforce-lockfile   # el CI exige pubspec.lock al día
flutter analyze                      # tras cada cambio
flutter test <archivo> --plain-name "<texto>"   # un solo test
dart run build_runner build          # codegen de Drift: tras tocar tablas o DAOs
dart tool/release.dart plan          # próxima versión, sin tocar nada
```

El SDK de Flutter se fija solo en `environment.flutter` de `pubspec.yaml`: Dependabot y el CI lo leen de ahí.

`android/app/google-services.json` no está en el repo y sin él el build de Android falla. Se genera con `flutterfire configure` o, sin él, con `firebase apps:sdkconfig ANDROID <appId> --project comfy-list > android/app/google-services.json` (el `appId` sale de `firebase apps:list`). En Windows el CLI termina con código 127 aunque el archivo salga completo: valida el JSON, no el código de salida.

## Arquitectura

Feature-first, tres capas por feature (`data`, `domain`, `presentation`); lo transversal vive en `lib/shared/`.

- **Datos**: Firestore por usuario (`users/{uid}/…`) es la fuente de verdad. Drift guarda solo preferencias, caché de cuenta y reintentos de la papelera.
- **Red**: todo por REST con Dio (Identity Toolkit y Firestore). `firebase_core` está solo por compatibilidad, así que `cloud_firestore` y `firebase_auth` no entran. `DioClient` expone `instance` (con `AuthInterceptor`) y `authClient` (sin interceptor: signUp, signIn y refresh). Los tokens viven solo en `SecureSessionStore`.
- **Errores**: los repositorios devuelven `Result<T>` (`Ok` | `Err`) hacia presentation.
- **Estado**: Riverpod con `Notifier<T>` y un `sealed class` de estado por feature. `app.dart` activa con `ref.watch` los providers de segundo plano (recordatorios, purga de papelera, actualizaciones).
- **Routing**: `routing/app_router.dart`. `_AppStateListenable` reevalúa las redirecciones cuando cambia el estado de auth. Las pantallas principales van en un `ShellRoute`; las de edición, fuera; las de auth, dentro de `SecureScreen`.
- **Inyección**: solo Riverpod. `appDatabaseProvider` y `notificationsServiceProvider` lanzan `UnimplementedError` hasta que `main()` los sobrescribe.

## Convenciones

- Texto visible: español de España, de «tú». Código: inglés. Comentarios: español.
- Colores, tipografía, espaciado y radios salen de `shared/core/theme/`.
- Las entidades distinguen «no tocar» de «poner a null» con flags en `copyWith` (`clearDescription`, `clearLocation`).
- Commits convencionales en inglés, con el mensaje limpio, sin pie de atribución.
- Las ramas se fusionan en `develop` con `git merge --no-ff` y se borran después, en local y en remoto, una vez `git log develop..<rama>` sale vacío.

## Trampas no obvias

### Firebase

- **La apiKey solo abre Identity Toolkit, Token Service y Cloud Firestore.** Una API nueva falla con `403 API_KEY_SERVICE_BLOCKED` aunque el código esté bien: se añade en Google Cloud. Va sin restricción de aplicación a propósito (Dio no manda las cabeceras `X-Android-*` y el escritorio también la usa).
- **Las reglas (`firestore.rules`) son el único control de acceso**, porque la apiKey es pública. Se despliegan con `firebase deploy --only firestore:rules`.
- **Los listados se leen por páginas** (`firestore_pages.dart`): Firestore puede devolver menos de lo pedido, así que se sigue el `nextPageToken`.
- **Las escrituras en bloque van por `commitWrites`**, de 500 en 500; la atomicidad solo vale dentro de una tanda.
- **`FirestoreValueCodec` solo entiende valores planos**: un objeto anidado se guarda como JSON en un campo de texto.

### Auth

- Correo sin verificar → `AuthUnverifiedEmail`, y el router solo deja pasar a `/verify-email`. Sin red rige el estado guardado en `SecureSessionStore`.
- Cerrar sesión revoca los tokens en el servidor con `validSince` (el refreshToken no caduca solo). Es best-effort y `validSince` sale del reloj del dispositivo.
- `PasswordPolicy` se comprueba en local porque Firebase solo impone 6 caracteres.
- Google Sign-In: solo Android. La SHA-1 del keystore de firma tiene que estar registrada en el cliente Android de Firebase; un keystore nuevo rompe el login con `DEVELOPER_ERROR`. Las del debug keystore y de `upload-keystore.jks` ya lo están; se comprueba comparando `firebase apps:android:sha:list <appId> --project comfy-list` con `keytool -list -v -keystore <jks>`.

### Privacidad

- Sin backup en Android: hacen falta `allowBackup="false"` **y** `res/xml/data_extraction_rules.xml`; con solo lo primero, Android 12+ sigue pasando los datos al móvil nuevo.
- Lo que identifique a una cuenta (correo, uid, token) se registra con `debugLog`; `debugPrint` sigue escribiendo en release.

### Drift

- Las migraciones son secuenciales: un `if (from < N)` por cambio, con `schemaVersion` a juego.
- Quitar una columna borra también sus `addColumn` y `columnTransformer` antiguos (el getter ya no existe y no compilaría): una sola recreación de tabla en el `if (from < N)` del borrado cubre a todos los que vienen de versiones anteriores.
- Un cambio de tipo de columna pide `migrator.alterTable(TableMigration(...))` con su `columnTransformer`, no un `addColumn`.
- `alterTable` recrea la tabla con el esquema **actual**: las columnas añadidas después de esa versión van en su `newColumns`, y su `addColumn` se limita a las versiones que llegan sin ellas.
- Un salto de `drift` arrastra `drift_dev` y cambia el código generado: `build_runner build` va en el mismo commit.

### Papelera

- Vive en la cuenta (`users/{uid}/trash`), no en el dispositivo. Los elementos de un mismo borrado comparten `groupId`.
- El tope (`TrashRepository.maxGroupsPerUid`) cuenta borrados, no documentos, y recorta al guardar y al leer, del más viejo primero y sin partir un grupo.
- Al borrar una lista, sus tareas se leen **antes** (el borrado se las lleva en cascada). Si esa lectura falla, no se borra nada.
- Quitar de la papelera lo restaurado es best-effort: si falla, queda en `trash_pending_table` y el `Watcher` lo reintenta antes de cada lectura.
- `trashPurgeProvider` purga solo con los ajustes ya leídos: con el plazo de fábrica como comodín borraría de más a quien tenga «nunca».

### Recordatorios

Qué avisar lo decide una función pura (`buildAppointmentReminders`); `AppointmentRemindersScheduler` reescribe el plan entero cuando cambian citas o ajustes. Las notificaciones son best-effort: fallan en silencio donde la plataforma no las soporta (Linux).

Cada cita lleva sus márgenes (`Appointment.reminderMinutes`); solo el interruptor de notificaciones es global. En Firestore van como texto separado por comas, y **campo ausente ≠ texto vacío**: ausente es una cita anterior a los márgenes por cita y se lee como `[30]`; vacío es «sin avisos». Por eso el `patch` escribe el vacío en vez de borrar el campo.

### Actualizaciones (solo Android)

- La app consulta `releases/latest` de GitHub **sin token**, así que el repo tiene que ser público.
- Compara el último segmento del tag (`v2026.10.11.231` → 231, igual que el `versionCode`) con el `buildNumber` instalado. Se instala el `.apk`, nunca el `.aab`, con el `browser_download_url` tal cual: el `+` del nombre viaja como `%2B`.
- El APK se baja con `DownloadManager`, **no con Dio**: al salir de la app, Android corta los sockets del proceso (`APP_BACKGROUND`) y cualquier descarga interna muere. El puente es el canal `comfy_list/updates` de `MainActivity`.
- El sha256 se contrasta con el `digest` del asset al bajar y otra vez justo antes de instalar. Una release sin `digest` o con URL ajena al repo no se ofrece.
- Para probar el flujo sin publicar: `--dart-define=APP_UPDATES_FAKE_INSTALLED_BUILD=230` en `flutter run`. Con ese define, el test del build instalado falla a propósito.

### Tests

`createTestContainer` (`test/helpers/provider_scope.dart`) abre una DB en memoria y recibe repositorios y remotes por tipo; si el tipo no está en su `switch`, el mensaje de error dice dónde añadirlo.

### Releases

- Cada push a `main` dispara `release.yml`. La versión sale de la fecha del commit y de su número de commits (`2026.10.11+221`, tag `v2026.10.11.221`). Los conventional commits solo deciden **si** se publica: sin `feat`, `fix`, `perf` o un breaking desde el último tag, no hay release.
- `versionCode` es `git rev-list --count HEAD` en `main`: si se reescribe esa historia, Play rechaza la subida.
- La firma llega por secrets del repo; en local, por `android/key.properties` y `android/app/upload-keystore.jks` (ignorados por git). Sin ellos, el build local cae a la debug key.
- El APK es solo **arm64**: no se instala en móviles de 32 bits ni en emuladores x86. El AAB se compila solo lanzando el workflow a mano con la casilla `aab`.
- `tool/verify_release.dart` corre **después** de publicar. Si falla, la release ya está publicada: se borra con `gh release delete "$TAG"` y se repite.

## Agent skills

### Issue tracker

Las incidencias viven en GitHub Issues (`ComfyPenguin/ComfyList`, con `gh`). Ver `docs/agents/issue-tracker.md`.

### Triage labels

Vocabulario por defecto: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. Ver `docs/agents/triage-labels.md`.

### Domain docs

Un solo contexto: `GLOSSARY.md` y `docs/adr/` en la raíz. Ver `docs/agents/domain.md`.
