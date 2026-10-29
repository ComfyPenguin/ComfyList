# Gotchas — ComfyList

Trampas y decisiones no obvias del proyecto, por área. `AGENTS.md` solo enlaza aquí: este es el sitio donde ampliar un gotcha, no el índice del repo.

## Firebase y red

- **Nada de SDK de Firebase**: todo va por REST con Dio (Identity Toolkit + Firestore REST). `firebase_core` está solo por compatibilidad; no importar `cloud_firestore` ni `firebase_auth`.
- **Dos clientes Dio**: `instance` (con auth interceptor) y `authClient` (sin interceptor, para signUp/signIn).
- **Los listados se leen por páginas** (`getAllDocuments`, `firestore_pages.dart`): Firestore corta las colecciones y puede devolver menos de lo pedido, así que una sola petición puede dejar documentos fuera; hay que seguir el `nextPageToken`.
- **La apiKey solo abre tres APIs**: en Google Cloud está restringida a Identity Toolkit, Token Service y Cloud Firestore. Cualquier API nueva falla con `403 API_KEY_SERVICE_BLOCKED` aunque el código esté bien: hay que añadirla a la lista. Va sin restricción de aplicación a propósito (las llamadas salen con Dio, sin las cabeceras `X-Android-Package`/`X-Android-Cert`, y la usan los builds de escritorio).

## Config y build

- **Config de Firebase fuera del repo**: `android/app/google-services.json` y `lib/firebase_options.dart` los genera `flutterfire configure` (config en `firebase.json`) y están ignorados por git. En un clon nuevo hay que generarlos o pedirlos: sin `google-services.json` el build de Android falla (lo exige el plugin `com.google.gms.google-services`).
- **Recuperar `google-services.json` sin `flutterfire`**: con el CLI de Firebase logueado, `firebase apps:sdkconfig ANDROID <appId> --project comfy-list` (el `appId` sale de `firebase apps:list`) imprime el archivo entero; redirigirlo crea uno válido.
- **Reglas de Firestore**: viven en `firestore.rules` y se despliegan con `firebase deploy --only firestore:rules`. Son el único control de acceso real (la app habla con Firestore REST y la apiKey es pública): exigen `request.auth.uid == uid` sobre todo `users/{uid}/**` y `request.auth.token.email_verified == true`.
- **`environment.flutter` es el único pin del SDK**: Dependabot infiere el release de Flutter que cumple `environment.sdk` y `environment.flutter` y resuelve el lockfile con ese Flutter (y su Dart), así que el CI lo lee de ahí mismo (`flutter-version-file: pubspec.yaml`) y no hay dos sitios que desincronizar. Sin ese campo cogía el último stable (3.47.7, Dart 3.13.5) y cada PR suyo rompía `flutter pub get --enforce-lockfile`, porque su `flutter_test` permite `meta 1.19.0`; el de 3.44.4 lo pincha a `1.18.0`. Ese `meta` fija también `build_runner` en `^2.15.1`: a partir de 2.16.1 exige `analyzer ≥13.3`, que pide `meta ^1.18.3`. Un salto de `drift` que arrastre `drift_dev` cambia el código generado: `dart run build_runner build` va en el mismo commit.

## Auth

- **Correo sin verificar**: deja el estado en `AuthUnverifiedEmail` y el router solo permite `/verify-email` (`VerifyEmailScreen`): comprobar, reenviar el correo o cerrar sesión. Sin red se usa el estado de verificación guardado en `SecureSessionStore` (`session.emailVerified`); si no hay ninguno (sesión anterior a esa clave), entra como antes y se guarda en la primera comprobación con red.
- **Cerrar sesión revoca los tokens en el servidor**: `accounts:update` con `validSince` y el idToken — el refreshToken no caduca solo. Es best-effort (sin red la sesión local se borra igual) y `validSince` sale del reloj del dispositivo: un reloj muy adelantado deja esa cuenta fuera hasta esa hora.
- **Contraseñas**: la política vive en `PasswordPolicy` (8 caracteres, con una letra y un número). Firebase solo impone 6 y no es configurable sin Identity Platform, así que la comprobación es local, antes de llamar a la API; el registro la enseña en vivo con `PasswordRulesChecklist`.
- **Google Sign-In**: solo Android, en `main()` con `Platform.isAndroid`.
- **La huella del keystore de firma tiene que estar en Firebase**: Google solo reconoce la app si la SHA-1 del keystore con el que está firmada figura en el cliente Android del proyecto. Registradas están la del debug keystore (los `flutter run` entran) y la del `upload-keystore.jks` (`0D:D5:59:47…`, la que firma las releases de CI y en local); un keystore nuevo (Play App Signing, otro equipo) rompe el login con `DEVELOPER_ERROR` sin tocar nada más. Se mira con `keytool -list -v -keystore <jks>` y se añade en Configuración del proyecto → Tus apps → Añadir huella digital (o `POST /v1beta1/projects/{p}/androidApps/{app}/sha` con la Management API).

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
- **Restaurar es reescribir el documento con su mismo id** (un `patch` o un `update` de `commit` sobre un documento inexistente lo crea). Una lista vuelve con sus tareas en un solo `commit`.
- **Borrados y restauraciones en bloque**: van por `commitWrites` (`firestore_commit.dart`), un `documents:commit` por tanda de 500 escrituras; la atomicidad solo vale dentro de una tanda. Los ids de la papelera los genera el cliente.
- **Quitar de la papelera lo restaurado es best-effort**: `remove` tira todos los ids en un solo `commit`; si falla, apunta todos en `trash_pending_table` (vía `TrashPendingStore`, así el reintento sobrevive a cerrar la app) y el `Watcher` lo reintenta antes de cada lectura, podando los que ya no están: una fila fantasma desaparece sola en cuanto hay red.
- **Al borrar una lista, sus tareas se leen *antes*** (el borrado se las lleva en cascada) para poder guardarlas también. La lista se oculta de inmediato y reaparece si el borrado falla. Si esa lectura falla, no se borra nada (la copia se quedaría sin ellas y no volverían) y la pantalla avisa con `AppToast.listDeleteFailed`.
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
- **El CI exige el lockfile al día**: `flutter pub get --enforce-lockfile` falla si un cambio en `pubspec.yaml` no va acompañado de su `pubspec.lock` actualizado, y también si el lockfile se resolvió con otro Flutter (una versión de un paquete que el SDK fijado no admite).

## Releases

- **Versionado por fecha y commits**: cada push a `main` dispara `.github/workflows/release.yml`. `tool/release.dart` saca la versión de la fecha del commit que publica (en su propio huso) y de su número de commits — `2026.10.11+221` —, y el tag añade ese mismo número (`v2026.10.11.221`) para que dos releases del mismo día no choquen. Los conventional commits ya no dan la versión: solo deciden *si* hay algo que publicar, así que sin `feat`, `fix`, `perf` ni un breaking desde el último tag no se publica nada.
- **`versionCode` = número de commits de `main`** (`git rev-list --count HEAD`): es el mismo número que cierra la versión, así que crece solo entre releases; si se reescribe la historia de `main` hay que mantenerlo a mano o Play rechazará la subida.
- **Firma y Firebase llegan por secrets**: `ANDROID_KEYSTORE_B64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` y `GOOGLE_SERVICES_JSON_B64`. En local firma igual `android/key.properties` con `android/app/upload-keystore.jks` (ambos ignorados por git); sin ellos el release local cae a la debug key y en CI el build falla. Guarda copia del `.jks` y de las contraseñas: sin eso no hay actualizaciones publicables.
- **Cuatro jobs y cachés**: `plan` → `checks` (analyze y tests) en paralelo con `build` (compila y sube `dist/` como artefacto) → `release` (tag, publica y verifica), que solo arranca si los dos salen bien. La caché de tareas de Gradle (`org.gradle.caching=true` en `android/gradle.properties`, guardada por `setup-gradle`) evita recompilar los plugins si no cambian (si R8 también se reutiliza depende de si el cambio de versión le llega, sin medir aún); el NDK se guarda con `actions/cache` y su versión va a mano en el workflow: si Flutter sube la suya hay que actualizarla o se vuelve a bajar en cada release.
- **El APK solo lleva arm64** (`--target-platform android-arm64`): cada arquitectura de más era otra compilación AOT y otra copia de la app dentro del APK (75 MB con las tres). No se instala en móviles de 32 bits ni en emuladores x86. El AAB para Play solo se compila lanzando el workflow a mano (`workflow_dispatch`) con la casilla `aab`.
- **Dry-run local**: `dart tool/release.dart plan` imprime la próxima versión sin tocar nada.
- **Lo publicado se comprueba contra lo compilado**: el último paso del workflow, `dart tool/verify_release.dart "$TAG" dist/*`, compara el sha256 de cada archivo con el `digest` que la API devuelve de su asset y falla si no cuadran o si la release no publica ninguno. Va después de subir (antes el `digest` no existe), así que un fallo deja la release ya publicada y hay que borrarla (`gh release delete "$TAG"`) y volver a publicarla. Los archivos se emparejan por nombre de asset, que es el que la app busca al bajar.

## Actualizaciones

- **Sin token, así que el repo tiene que ser público**: la app lee `api.github.com/repos/ComfyPenguin/ComfyList/releases/latest` sin autenticación y baja el APK del asset; meter un token de GitHub en el APK repartido sería regalar acceso al repo. Con el repo privado la API responde 404 y no hay nada que ofrecer, y sin releases publicadas tampoco: el feed es lo que publica `.github/workflows/release.yml`, que no necesita ningún cambio.
- **La versión que se compara es el número de commits**: el último segmento del tag (`v2026.10.11.231` → 231), que es el mismo número que Android guarda como `versionCode`, contra el `buildNumber` del paquete instalado. Si el tag no sigue ese formato, se saca del nombre del APK (`comfylist-2026.10.11+231.apk`); el tag antiguo `v1.0.0` no se puede comparar y se ignora. Un build local por delante de la última release queda «al día»: nunca se ofrece bajar.
- **Se instala el `.apk`, jamás el `.aab`** (el AAB es para Play), y con el `browser_download_url` que devuelve la API: el `+` del nombre viaja codificado como `%2B` y construir la URL a mano lo rompe. Solo se acepta si es `https://github.com/ComfyPenguin/ComfyList/releases/download/…` (`GithubReleaseDto`); otra URL descarta la release entera.
- **El APK se compara con el `digest` de la release antes de ofrecerlo**: el asset trae su sha256 en la respuesta de la API y el repositorio calcula el del archivo bajado; si no cuadra se borra y el reintento vuelve a bajarlo (`IntegrityFailure`, con el aviso en la fila de Ajustes). El archivo llega de otro host que la API (`release-assets.githubusercontent.com`, tras la redirección del `browser_download_url`), así que una descarga cortada o manipulada se detecta aquí. El hash se comprueba también justo antes de instalar (`verifyApk`, desde `AppUpdatesNotifier.install()`): si el APK cambió mientras esperaba en disco se borra y se vuelve a pedir la descarga; si ya no está, se avisa sin tacharlo de manipulación. El hash detecta corrupción y manipulación en tránsito (el APK llega de otro host que la API que publica el hash); la autenticidad la garantiza la firma de Android al actualizar (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), por eso no se fija ninguna huella en el código. Una release sin `digest` ni siquiera se ofrece: `GithubReleaseDto.toRelease` la descarta, igual que la de URL ajena, y `AppRelease.sha256` es obligatorio.
- **Android no instala en silencio**: hace falta `REQUEST_INSTALL_PACKAGES`, un `FileProvider` propio (`file_paths.xml`, sobre el `content://`) y el diálogo del sistema, que confirma quien usa la app. El puente es el canal `comfy_list/updates` de `MainActivity`. Si la app instalada lleva otra firma (un `flutter run` con la debug key frente al APK de release), el instalador rechaza el paquete: no hay nada que arreglar desde la app.
- **El APK lo baja el `DownloadManager`, no Dio**: unos segundos después de salir de la app, Android le aplica el bloqueo de red `APP_BACKGROUND` y destruye sus sockets TCP (`InetDiagMessage: Destroyed live tcp sockets for uids=…` en logcat, comprobado en Android 17), así que una descarga dentro del proceso muere siempre. El DownloadManager descarga desde el sistema, enseña su notificación y deja el APK en `getExternalFilesDir(DIRECTORY_DOWNLOADS)` (de ahí el `external-files-path` de `file_paths.xml`). Si la app muere a mitad, `enqueueDownload` reengancha la descarga de esa URL en vez de empezar otra, y borra las de versiones anteriores con su APK. Si no avanza en 2 minutos el diálogo deja de esperar, pero la descarga sigue en el sistema y el reintento se reengancha. En Android 6–10 esa carpeta la pueden tocar otras apps con permiso de almacenamiento entre el hash y la instalación; se acepta porque el instalador exige la misma firma. Es la única red que no pasa por `DioClient`.
- **Dos columnas nuevas en `settings_table`** (v14 de Drift): `last_update_check_at` (la comprobación automática va una vez al día) y `skipped_update_build` (el «Ahora no» por build). Quien venga de la v8 o antes las recibe con la recreación de la tabla de la v9, así que van en su `newColumns` y su `addColumn` se limita a `from >= 9`.
- **El arranque automático va con `ref.listen`, no con `watch`**: el provider del comprobador no se vuelve a leer solo, así que un `watch` a secas dejaría la comprobación sin disparar hasta que alguien lo leyera otra vez.
- **El aviso se marca al leerse** (`UpdatePromptNotifier`): el diálogo sale una sola vez por build y sesión, y en Ajustes la fila sigue anunciando la versión nueva aunque se haya descartado el aviso.
- **Ajustes solo enseña el comprobador donde hay APK que instalar** (`updateCheckSupportedProvider`, Android): en escritorio, web e iOS la sección no se monta.
- **Override de depuración**: `--dart-define=APP_UPDATES_FAKE_INSTALLED_BUILD=230` hace que la app se crea una build anterior y dispara el flujo entero (modal, descarga e instalador) sin publicar nada. Solo para `flutter run` en un móvil: con ese define puesto, el test del build instalado falla a propósito.

## Ramas

- **Fusión en `develop` con `git merge --no-ff`** (para dejar el commit de merge como en el resto del historial) y borrado después, en local (`git branch -d`) y en remoto (`git push origin --delete <rama>`).
- **Antes de borrar, comprobar que está contenida**: `git branch --no-merged develop` y `git log develop..<rama>` tienen que salir vacíos.
