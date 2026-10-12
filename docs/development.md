# Desarrollo

Guía para montar el entorno y trabajar en ComfyList. Para saber qué hace la app, mira el [README](../README.md).

## Requisitos

- Flutter: la versión exacta de `environment.flutter` en `pubspec.yaml` (hoy 3.44.4, canal stable) — el CI la lee de ahí
- Android SDK configurado (para compilar y lanzar en Android)

## Empezar

```sh
flutter pub get
flutter run
```

`android/app/google-services.json` y `lib/firebase_options.dart` no se versionan: genéralos con `flutterfire configure` (la config está en `firebase.json`) o pídelos. Sin el primero, el build de Android falla.

## Comandos

```sh
flutter analyze              # Análisis estático
flutter test                 # Suite completa
dart run build_runner build  # Codegen de Drift tras tocar tablas o DAOs
dart tool/release.dart plan  # Próxima versión, sin publicar nada
```

## Stack

| Área | Tecnología |
| --- | --- |
| UI | Flutter (Material 3) |
| Estado | Riverpod |
| Navegación | GoRouter |
| Red | Dio (Identity Toolkit y Firestore, REST) |
| Base local | Drift (SQLite) |
| Sesión | flutter_secure_storage |

## Estructura

Feature-first con Clean Architecture (3 capas por feature):

```
lib/
├─ features/   # appointments, auth, settings, todos, todo_lists, trash
└─ shared/     # core, data, platform, ui
test/          # tests por feature + helpers compartidos
tool/          # herramientas de desarrollo (release.dart)
```

## Releases y CI

- Las PRs hacia `develop` pasan `flutter analyze`, `flutter test` y comprobación del lockfile (`.github/workflows/ci.yml`).
- Al empujar a `main`, el workflow calcula la versión, compila APK y AAB firmados y publica la GitHub Release.
- La versión es `año.mes.dia+commits` (por ejemplo `2026.10.11+221`): la fecha del commit que se publica y su número de commits. El tag lleva ese mismo número (`v2026.10.11.221`) para que dos releases del mismo día no choquen, y los conventional commits solo deciden si hay algo que publicar: sin `feat`, `fix`, `perf` ni breaking desde el último tag no se publica nada.
- Dependabot propone actualizaciones de actions y dependencias cada semana.

## Ramas

- Las features se fusionan en `develop` con `git merge --no-ff` y la rama se borra después.
- `main` solo recibe fusiones para publicar releases.

### Publicar una release (develop → main)

Con `develop` verde (analyze y tests), fusiona y empuja `main`; el [workflow de release](../.github/workflows/release.yml) calcula la versión, compila APK y AAB, y publica la GitHub Release:

```sh
git checkout main
git pull
git merge develop --no-ff
git push origin main
```

El workflow añade a `main` un commit `chore(release): vX.Y.Z` con el tag `vX.Y.Z`. Cuando termine, cierra el ciclo sincronizando `develop` con ese commit:

```sh
git fetch origin
git checkout develop
git merge origin/main
git push origin develop
```

Sin `feat`, `fix`, `perf` ni breaking desde el último tag, el workflow termina en verde sin publicar nada.

## Más documentación

- [`architecture.md`](architecture.md) — capas, estado y routing.
- [`gotchas.md`](gotchas.md) — trampas y decisiones no obvias (Firebase, Privacidad, Drift, Releases…).
- [`plans/`](plans) — planes de escritorio (Windows, Linux) y Google Sign-In.
- [`../AGENTS.md`](../AGENTS.md) — convenciones de código.
