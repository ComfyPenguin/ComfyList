# Gotchas — ComfyList

Trampas y decisiones no obvias del proyecto, por área. `AGENTS.md` solo enlaza aquí: este es el sitio donde ampliar un gotcha, no el índice del repo.

## Firebase y red

- **Nada de SDK de Firebase**: todo va por REST con Dio (Identity Toolkit + Firestore REST). `firebase_core` está solo por compatibilidad; no importar `cloud_firestore` ni `firebase_auth`.
- **Dos clientes Dio**: `instance` (con auth interceptor) y `authClient` (sin interceptor, para signUp/signIn).
- **La apiKey solo abre tres APIs**: en Google Cloud está restringida a Identity Toolkit, Token Service y Cloud Firestore. Cualquier API nueva falla con `403 API_KEY_SERVICE_BLOCKED` aunque el código esté bien: hay que añadirla a la lista. Va sin restricción de aplicación a propósito (las llamadas salen con Dio, sin las cabeceras `X-Android-Package`/`X-Android-Cert`, y la usan los builds de escritorio).

## Config y build

- **Config de Firebase fuera del repo**: `android/app/google-services.json` y `lib/firebase_options.dart` los genera `flutterfire configure` (config en `firebase.json`) y están ignorados por git. En un clon nuevo hay que generarlos o pedirlos: sin `google-services.json` el build de Android falla (lo exige el plugin `com.google.gms.google-services`).
- **Reglas de Firestore**: viven en `firestore.rules` y se despliegan con `firebase deploy --only firestore:rules`. Son el único control de acceso real (la app habla con Firestore REST y la apiKey es pública): exigen `request.auth.uid == uid` sobre todo `users/{uid}/**` y `request.auth.token.email_verified == true`.

## Auth

- **Correo sin verificar**: deja el estado en `AuthUnverifiedEmail` y el router solo permite `/verify-email` (`VerifyEmailScreen`): comprobar, reenviar el correo o cerrar sesión.
- **Cerrar sesión revoca los tokens en el servidor**: `accounts:update` con `validSince` y el idToken — el refreshToken no caduca solo. Es best-effort (sin red la sesión local se borra igual) y `validSince` sale del reloj del dispositivo: un reloj muy adelantado deja esa cuenta fuera hasta esa hora.
- **Contraseñas**: la política vive en `PasswordPolicy` (8 caracteres, con una letra y un número). Firebase solo impone 6 y no es configurable sin Identity Platform, así que la comprobación es local, antes de llamar a la API; el registro la enseña en vivo con `PasswordRulesChecklist`.
- **Google Sign-In**: solo Android, en `main()` con `Platform.isAndroid`.

## Privacidad

- **Nada de backup**: `android:allowBackup="false"` **y** `res/xml/data_extraction_rules.xml` — sin lo segundo, Android 12+ sigue traspasando los datos al móvil nuevo.
- **Nada de logs con datos de cuenta**: para correo, uid o datos del token usa `debugLog` (`shared/core/logging/`), no `debugPrint`, que sigue escribiendo en release.

## Drift

- **Migraciones**: schema v13 con `onUpgrade` secuenciales (un `if (from < N)` por columna, y `schemaVersion` a juego). Un cambio de tipo de columna no es un `addColumn`: pide `migrator.alterTable(TableMigration(...))` con el `columnTransformer` que convierta.
- **`alterTable` recrea la tabla con el esquema actual**: las columnas añadidas después de esa versión van en su `newColumns` y su propio `addColumn` se condiciona a las versiones que sí llegan sin ella (`if (from == N)`, o un rango).
- **Tablas**: `settings_table` (singleton id=1), `account_cache_table`, `trash_pending_table`.
- **`appDatabaseProvider`** (`shared/data/local/`) lanza `UnimplementedError` y se sobrescribe en `main()` con la instancia inicializada.

## Papelera

- **Se guarda en la cuenta, no en el dispositivo**: cada borrado va antes a `users/{uid}/trash` (un documento por elemento; los de un mismo borrado comparten `groupId`), así que la papelera es igual en todos los dispositivos y sobrevive a desinstalar. El `payload` es JSON en un campo de texto: `FirestoreValueCodec` solo entiende valores planos.
- **Lectura paginada**: `FirestoreTrashRemote.listEntries` pide de 300 en 300 siguiendo el `nextPageToken` hasta agotar la colección; una sola petición se dejaría las últimas y el tope y la pantalla contarían de menos.
- **Tope de 100 borrados por cuenta** (`TrashRepository.maxGroupsPerUid`), recortado tanto al guardar como al leer (así una cuenta que se quedó por encima —un recorte que falló, dos dispositivos que se pisaron— se arregla al entrar). El recorte es best-effort: si no puede tirar algo, se queda para la siguiente pasada. Cuenta borrados, no documentos (una lista con 40 tareas ocupa un solo hueco), por borrados enteros y del más viejo primero (`_trim` nunca parte un grupo). Al llegar al tope se descarta el más viejo y la pantalla lo avisa con `_FullTrashNotice`.
- **Guardados encadenados**: `TrashRepositoryImpl` va con polling (`pollIntervalProvider`, un `Watcher` por uid) y encadena los guardados —el recorte de uno no se solapa con el siguiente: dos a la vez deciden sobre la misma foto y la cuenta se queda por encima del tope—.
- **`_nextDeletedAt` siempre creciente**: el reloj del sistema no llega al microsegundo y dos borrados seguidos acabarían en el mismo grupo.
- **Deshacer**: `undoLastDelete()` devuelve el último grupo de ese tipo. El aviso lo ofrece `AppToast.showUndo` (8 s con acción, 2 s sin ella) y solo ofrece el último, así que para varios borrados está la pantalla Papelera (`/trash`, entrada en Ajustes), que restaura de uno en uno (`TrashRestorer`) o vacía todo.
- **La pantalla agrupa por `groupId`** (`TrashGroup.partition`): una lista borrada con sus tareas es **una** fila con desplegable, y «Restaurar» devuelve el grupo entero se despliegue o no. Una tarea borrada *antes* que su lista se cuelga de la fila de la lista aunque sea otro borrado: sola se escribiría bajo una lista que no está y no volvería, así que no tiene fila propia hasta que la lista vuelva.
- **Restaurar es reescribir el documento con su mismo id** (`patch` sobre un documento inexistente lo crea).
- **Quitar de la papelera lo restaurado es best-effort**: `remove` no aborta si un borrado falla; apunta el que no pudo tirar en `trash_pending_table` (vía `TrashPendingStore`, así el reintento sobrevive a cerrar la app) y el `Watcher` lo reintenta antes de cada lectura, podando los que ya no están: una fila fantasma desaparece sola en cuanto hay red.
- **Al borrar una lista, sus tareas se leen *antes*** (el borrado se las lleva en cascada) para poder guardarlas también. Si esa lectura falla, no se borra nada (la copia se quedaría sin ellas y no volverían) y la pantalla avisa con `AppToast.listDeleteFailed`.
- **Borrado automático**: con `trashRetentionDays` en un plazo (0/7/15/30 días; 0 = «nunca»; de fábrica 30), `trashPurgeProvider` —activado en `app.dart`— llama a `purgeExpired` al abrir la app con sesión y cada vez que cambia el plazo, así que no hace falta entrar en la papelera. Solo purga cuando los ajustes están leídos: con el plazo de fábrica como comodín borraría de más a quien tenga «nunca» puesto.

## Recordatorios

- **Hasta 5 márgenes por cita** (`AppSettings.appointmentReminderMinutes`, en minutos y sin repetidos). En Ajustes se añaden desde un menú (`showReminderLeadMenu`) y se quitan tocando su pastilla.
- **`appointmentRemindersProvider`** (activado en `app.dart`) escucha citas y ajustes y reescribe el plan entero con `AppointmentRemindersScheduler`. La lógica de qué avisar es pura (`buildAppointmentReminders`) y cada margen lleva su id de notificación: `notificationIdFor(id, minutes: n)`.
- **Notificaciones best-effort**: `NotificationsService.init()` va en try-catch (falla en silencio en Linux), y el scheduling (`schedule`/`cancelAll`) también.

## Entidades y estado

- **`copyWith` con flags**: las entidades usan `clearDescription`/`clearLocation` booleanas (no campos nullable) para distinguir «no tocar» de «poner a null».

## Tests

- **DB en memoria**: `AppDatabase.forTesting(NativeDatabase.memory())`, inyectada con `ProviderScope` + `overrideWithValue`.
- **`createTestContainer`** la inyecta sola al sobreescribir `FirestoreTrashRemote`, porque el repo real de la papelera usa la DB para los pendientes.
- **`sqlite3` 3.x trae su binario por native assets** (hook cacheado en `.dart_tool/hooks_runner`): ni en local ni en CI hace falta instalar la librería de SQLite del sistema.
- **El CI exige el lockfile al día**: `flutter pub get --enforce-lockfile` falla si un cambio en `pubspec.yaml` no va acompañado de su `pubspec.lock` actualizado.

## Releases

- **Versionado automático por conventional commits**: cada push a `main` dispara `.github/workflows/release.yml`. `tool/release.dart` calcula el bump desde el último tag `v*` (breaking → major, `feat` → minor, `fix`/`perf` → patch), el workflow lo escribe en `pubspec.yaml`, lo commitea (`chore(release): vX.Y.Z`) y crea la release con APK y AAB. Sin commits de esos tipos no publica nada. Si aún no hay tags, la primera release usa la versión que ya tenga pubspec.
- **`versionCode` = número de commits de `main`** (`git rev-list --count HEAD`): crece solo entre releases; si se reescribe la historia de `main` hay que mantenerlo a mano o Play rechazará la subida.
- **Firma y Firebase llegan por secrets**: `ANDROID_KEYSTORE_B64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` y `GOOGLE_SERVICES_JSON_B64`. En local firma igual `android/key.properties` con `android/app/upload-keystore.jks` (ambos ignorados por git); sin ellos el release cae a la debug key. Guarda copia del `.jks` y de las contraseñas: sin eso no hay actualizaciones publicables.
- **Dry-run local**: `dart tool/release.dart plan` imprime la próxima versión sin tocar nada.

## Ramas

- **Fusión en `develop` con `git merge --no-ff`** (para dejar el commit de merge como en el resto del historial) y borrado después, en local (`git branch -d`) y en remoto (`git push origin --delete <rama>`).
- **Antes de borrar, comprobar que está contenida**: `git branch --no-merged develop` y `git log develop..<rama>` tienen que salir vacíos.
