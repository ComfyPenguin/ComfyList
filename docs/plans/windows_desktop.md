# ComfyList en Windows (escritorio) — plan

> Pendiente. Escrito el 26/09/2026 como contexto para implementarlo en una sesión aparte:
> pégame este fichero y se puede empezar sin rehacer el análisis.
>
> Ver también: `google_sign_in_desktop.md` y `linux_desktop.md`.

## Objetivo

Que Windows sea una plataforma de primera: que instale sin sustos, que la sesión aguante, que los
recordatorios funcionen (o se degraden con elegancia) y que el bloqueo local llegue también aquí.

## Punto de partida (lo que ya vale)

- `windows/` está completo: la ventana abre a 1280x720 con el título `comfy_list`
  (`windows/runner/main.cpp:28-30`).
- Drift usa la misma `driftDatabase(name: 'comfy_list')`
  (`lib/shared/data/local/app_database.dart:16`) → carpeta de datos de la app bajo `%APPDATA%`.
- Red: todo HTTPS saliente con Dio; nada que abrir en el firewall.
- Los builds de escritorio usan la apiKey de Android (la de `firebase_endpoints.dart`): no hace
  falta ninguna clave nueva.
- Google Sign-In no funciona hoy en Windows; tiene plan propio.

## Qué falta

### 1. Compilar

Visual Studio 2022 con la carga de trabajo **"Desarrollo para escritorio con C++"** y, además,
las **librerías C++ ATL** (las exige `flutter_secure_storage` en Windows, según su README).
Primer paso: `flutter build windows --release` y ver qué falta.

### 2. Sesión persistente

`flutter_secure_storage` en Windows usa el almacén nativo del sistema (por usuario de Windows),
sin llavero externo: es el caso fácil de los tres. A verificar solo que sobrevive a actualizar la
app y que `signOut()` la limpia (ya lo hace: `auth_repository_impl.dart:287`).

### 3. Recordatorios de citas

El plugin soporta toasts en Windows (implementación C++/WinRT), pero tiene dos límites que tocan
justo el plan de recordatorios:

- **No hay notificaciones repetidas**: `periodicallyShow` lanza `UnsupportedError`.
- **Sin identidad de paquete (MSIX), `cancel` no hace nada y `getActiveNotifications` devuelve una
  lista vacía.** Eso choca con `AppointmentRemindersScheduler`, que reescribe el plan con
  `cancelAll`: sin MSIX los avisos se acumularían en vez de reprogramarse.

Antes de tocar nada hay que verificar si `schedule` funciona fuera de MSIX. Si no, la decisión es
la misma que en Linux: avisos solo con la app abierta, o MSIX obligatorio si se quiere el
comportamiento completo.

### 4. Bloqueo local (huella/PIN)

`local_auth` **sí** soporta Windows (Windows Hello: PIN, huella o cara), así que es la plataforma
natural para extender el bloqueo local que quedó pendiente en la rama de seguridad. Requiere que
el usuario tenga Hello configurado y degradar con elegancia si no lo tiene (no bloquear la app).

### 5. Empaquetado y firma

- **MSIX** con el paquete `msix` (es lo que recomienda la doc de Flutter) o un instalador EXE
  (Inno Setup) + zip portable. `fastforge` también genera EXE y MSIX.
- **Firma de código (Authenticode)**: sin firmar, SmartScreen avisa al usuario. Publicar en la
  Microsoft Store es la vía en la que Microsoft re-firma el paquete.
- Ojo: el MSIX no es solo cosmético aquí — es lo que da la identidad de paquete que necesitan los
  toasts para poder cancelarse (punto 3).

### 6. Detalles de escritorio (nice-to-have)

Título "ComfyList" en vez de `comfy_list` (`windows/runner/main.cpp:30`), recordar tamaño y
posición de la ventana, y el icono del `.exe`/instalador.

## A verificar

1. Que `flutter build windows --release` compila con los plugins actuales.
2. Ruta real de la base de datos (`%APPDATA%`) y que sobrevive a actualizar la app.
3. `schedule` y `cancelAll` de notificaciones **sin** MSIX: qué pasa exactamente con cada uno.
4. Lo mismo con el paquete MSIX instalado: si el plan de recordatorios se comporta como en Android.
5. `local_auth` en una máquina sin Windows Hello: que la app siga siendo usable.
6. Dónde deja los tokens `flutter_secure_storage` en Windows y que se borran al cerrar sesión.
7. Tamaño del instalador y que la app arranca en un Windows limpio (sin Visual Studio instalado).

## Criterios de aceptación

- Instalador (MSIX o EXE) que instala y desinstala limpiamente, y que la app arranca en un Windows
  sin dependencias raras.
- Login por correo, sesión persistida, listas y citas funcionando.
- Recordatorios con el comportamiento decidido (y coherente con lo que prometa la UI), más el
  bloqueo local por Windows Hello si se implementa.
- `flutter analyze` limpio y la suite actual en verde.

## No-objetivos

- Web y macOS: fuera de alcance.
- Nada de SDK de Firebase ni de cifrar la base de datos local.
- No meterse en la Microsoft Store en la primera pasada: primero el instalador local.
