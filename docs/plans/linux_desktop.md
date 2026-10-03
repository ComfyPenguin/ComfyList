# ComfyList en Linux (escritorio) — plan

> Pendiente. Escrito el 26/09/2026 como contexto para implementarlo en una sesión aparte:
> pégame este fichero y se puede empezar sin rehacer el análisis.
>
> Ver también: `google_sign_in_desktop.md` y `windows_desktop.md`.

## Objetivo

Que Linux deje de ser una plataforma "scaffoldeada" y pase a ser una app de escritorio real:
que compile, que la sesión aguante entre arranques, que los recordatorios se comporten como se
promete en la UI y que se pueda distribuir en un fichero.

## Punto de partida (lo que ya vale)

- `linux/` está completo: `linux/CMakeLists.txt:10` define `APPLICATION_ID = andypr.comfy_list`,
  la ventana abre a 1280x720 con `GtkHeaderBar` y título `comfy_list`
  (`linux/runner/my_application.cc:45-55`).
- Drift abre la base de datos con `driftDatabase(name: 'comfy_list')`
  (`lib/shared/data/local/app_database.dart:16`), que resuelve la carpeta de datos de la app
  vía `path_provider` → en Linux debería caer bajo `~/.local/share/`.
- Todo el tráfico es HTTPS saliente con Dio (Identity Toolkit + Firestore REST): no hay puertos,
  ni servicios, ni firewall que configurar.
- Los builds de escritorio usan la misma apiKey que Android (la compilada en
  `firebase_endpoints.dart`), así que no hace falta ninguna clave nueva.
- Google Sign-In no funciona hoy en Linux; tiene plan propio.

## Qué falta

### 1. Compilar y arrancar

Dependencias de compilación que pide Flutter en Linux (`clang`, `cmake`, `ninja-build`,
`pkg-config`, `libgtk-3-dev`) y de runtime en el sistema destino (`libgtk-3-0`, `libblkid1`,
`liblzma5`, según la doc oficial). Primer paso real: `flutter build linux --release` en una
máquina Linux y ver qué se rompe.

### 2. Sesión persistente (el punto frágil)

`SecureSessionStore` usa `flutter_secure_storage`, que en Linux va contra **libsecret + un
keyring corriendo** (gnome-keyring, kwallet o similar). Sin keyring no hay dónde dejar los
tokens y el login no se puede recordar. Hay que decidir el comportamiento antes de codificar:
avisar en Ajustes de que no hay llavero, o degradar a sesión en memoria (login en cada arranque).

En sandbox es peor: el plugin **todavía no usa el portal XDG de secretos**
(`juliansteenbakker/flutter_secure_storage#1203`), así que en Flatpak/Snap hay que dar acceso al
servicio de bus `org.freedesktop.secrets`, o la sesión no se guarda dentro del paquete.

### 3. Recordatorios de citas

`flutter_local_notifications` lo dice en su README: en Linux **no hay notificaciones
programadas** ("Scheduled/pending notifications is currently not supported due to the lack of a
scheduler API"). El plan de recordatorios de la app se reescribe con `schedule`/`cancelAll`
(`AppointmentRemindersScheduler`), así que en Linux no pinta nada. Opciones, de menos a más:

- **Avisos solo con la app abierta**: un `Timer` interno que dispare la notificación inmediata
  cuando llegue el margen de la cita. Es lo único que se puede hacer sin salir de Flutter.
- **No ofrecerlo**: ocultar el ajuste en Linux y documentarlo.
- **Tarea del sistema** (systemd timer / cron): fuera de alcance, requiere instalar cosas.

También ojo con la entrega: hace falta un servidor de notificaciones por D-Bus; en un entorno sin
escritorio no habrá avisos, y `NotificationsService.init()` ya es best-effort.

### 4. Bloqueo local

`local_auth` no tiene implementación en Linux. Si se quiere algo equivalente: pedir la contraseña
al volver a la app (sesión reciente) o no ofrecerlo. En Windows sí existe (ver su plan).

### 5. Empaquetado

- **AppImage** como formato principal, compilando en la distro **más antigua** que se quiera
  soportar (la glibc manda: lo compilado en una distro nueva no arranca en una LTS vieja).
- Usar un runtime reciente de AppImage para no pedir `libfuse2` (hoy `libfuse2t64` en Ubuntu 24.04).
- Incluir un `.desktop` llamado como el app id (`andypr.comfy_list.desktop`) más icono; el
  AppImage no crea entrada de menú ni auto-actualización por sí solo (AppImageLauncher/AppImageUpdate).
- Herramienta: `fastforge` (genera AppImage, DEB, RPM y Pacman) o `appimage-builder`, que tiene
  ejemplo de Flutter.
- Alternativas: **Flatpak** (sandbox + auto-update, con el problema de libsecret del punto 2) y
  **Snap** (el README del plugin recomienda añadir `libsecret-1-dev` y `libsecret-1-0` al snapcraft).

### 6. Detalles de escritorio (nice-to-have, no bloquean)

Título de ventana "ComfyList" en vez de `comfy_list` (`linux/runner/my_application.cc:48,52`),
recordar tamaño y posición de la ventana, y atajos de teclado típicos de escritorio.

## A verificar

1. Que `flutter build linux --release` compila el proyecto sin tocar código y con todos los
   plugins resueltos (Dio, Drift, secure_storage, notificaciones).
2. Ruta real de la base de datos en Linux, y que sobrevive a reinstalar/actualizar el paquete
   (una actualización no debe pisar los datos del usuario).
3. Con keyring: guardar sesión, cerrar, abrir y entrar sin volver a pedir credenciales.
4. Sin keyring: qué error sale exactamente y que la app **no se cae** (debe poder entrarse igual).
5. Dentro de Flatpak/Snap: si la sesión se guarda o hay que exponer `org.freedesktop.secrets`.
6. Qué hace hoy el scheduler de recordatorios al llamar a `schedule` en Linux: error silencioso,
   excepción capturada o aviso. Decidir en función de eso.

## Criterios de aceptación

- Un AppImage que arranca en dos distros distintas (una LTS veterana y una reciente).
- Login por correo, sesión persistida con keyring, listas y citas funcionando, y recordatorios
  con el comportamiento que se haya decidido (y reflejado en la UI).
- `flutter analyze` limpio y la suite actual en verde.

## No-objetivos

- Web y macOS: fuera de alcance.
- Nada de SDK de Firebase ni de cifrar la base de datos local.
- No empaquetar en varios formatos a la vez: primero AppImage, el resto solo si hace falta.
