# ComfyList

App TODO multiplataforma con sincronización via Firebase.

## Stack

- **UI**: Flutter (Material Design 3)
- **State**: Riverpod (`Notifier<T>` + `sealed class` State por feature)
- **Routing**: GoRouter con `ShellRoute` para navegación persistente
- **HTTP**: Dio (NO `cloud_firestore` / `firebase_auth` — todo via REST API de Firebase)
- **Local DB**: Drift (SQLite) con `build_runner` para codegen
- **Tokens**: `flutter_secure_storage` via `SecureSessionStore`
- **Auth**: Identity Toolkit REST API + Google Sign-In (solo Android)
- **Testing**: mocktail para mocks, Drift `NativeDatabase.memory()` para tests de DB

## Architecture

Feature-first + Clean Architecture (3 capas por feature):

```
lib/features/<feature>/
├── data/
│   ├── datasources/       ← Remote/local datasources (Dio calls)
│   ├── models/            ← DTOs con serialización
│   └── repositories/      ← Implementaciones del repositorio
├── domain/
│   ├── entities/          ← Modelos de dominio (inmutables, copyWith)
│   └── repositories/      ← Interfaces abstractas
└── presentation/
    ├── providers/         ← Riverpod Notifier + State
    ├── screens/           ← Pantallas
    └── widgets/           ← Widgets específicos
```

Cada feature usa un `Repository` abstracto en `domain/`, implementado en `data/repositories/`.
Los Notifiers se suscriben al stream del repo y actualizan estado reactivamente.

## Commands

```sh
flutter run                 # Lanzar app
flutter test                # Tests unitarios
dart run build_runner build  # Codegen Drift (tras modificar tablas/DAOs)
dart run build_runner watch  # Codegen en modo watch
flutter analyze             # Análisis estático
```

## Modelo de datos (Drift)

- Schema v4 con migraciones `onUpgrade` secuenciales
- **Tablas**: `settings_table` (singleton id=1), `account_cache_table`
- `AppDatabase` se instancia en `main()` y se inyecta via `ProviderScope` override
- Tests: `AppDatabase.forTesting(NativeDatabase.memory())`

## State Management

- `Notifier<T>` + `sealed class` State con variantes: `Initial`, `Loading`, `Data`, `Error`
- Providers se activan desde el router en `_AppStateListenable`
- `todosProvider` usa `NotifierProvider.family` (parametrizado por `listId`)
- `appDatabaseProvider` declara `throw UnimplementedError` y se sobrescribe en `main()`

## Routing (GoRouter)

- `ShellRoute` con `AppShell` (BottomBar + AppBar + FAB persistente)
- **Edición fuera del shell**: rutas como `/lists/new`, `/lists/:id/edit` se declaran fuera del `ShellRoute`
- `_instantPage()`: todas las transiciones son instantáneas (`CustomTransitionPage` duración 0)
- Redirect logic en `routerProvider`: splash → auth check → precarga datos → home

## Copy & Language

- Copy visible al usuario: **español de España**, usando "tú"
- Código (clases, vars, archivos): **inglés**, snake_case archivos, PascalCase clases
- Comentarios: español de España, **solo para explicar brevemente una función o código muy complejo** — no ensuciar el código con comentarios obvios o redundantes

## Do

- Tras cada cambio, correr `flutter analyze` (o `dart analyze` en libs puras) y `flutter test` para verificar que no hay errores ni regresiones
- Respetar estructura feature-first con 3 capas
- Usar Result<T> sealed class (Ok | Err) en repositorios — nunca lanzar excepciones
- Usar mocktail para mocks
- Usar tematización del proyecto (app_colors, app_typography, app_spacing, app_radius)
- Si encuentras comentarios redundantes u obvios en el código (explicando lo que el código ya dice), rectifícalos: bórralos o déjalos en una sola línea breve solo si aportan contexto no obvio
- Conventional commits (sin Co-Authored-By)

## Do NOT

- Usar `get_it` ni otros DI
- Llamar APIs fuera de `DioClient`
- Guardar tokens fuera de `SecureSessionStore`
- Añadir otros state managers
- Mezclar lógica de negocio en UI
- Crear archivos .md salvo que se pida explícitamente
- Añadir comentarios redundantes u obvios en el código

## Gotchas

- **No Firebase SDK**: Todo Firebase va via REST API con Dio (Identity Toolkit + Firestore REST). `firebase_core` solo existe para compatibilidad; no importar `cloud_firestore` ni `firebase_auth`.
- **Dos clientes Dio**: `instance` (con auth interceptor) y `authClient` (sin interceptor, para signUp/signIn).
- **copyWith con flags**: Entidades usan `clearDescription`/`clearLocation` booleanas (no nullable fields) para distinguir "no tocar" de "poner a null".
- **Google Sign-In**: Solo Android en `main()` con `Platform.isAndroid`.
- **Notificaciones**: `NotificationsService.init()` dentro de try-catch (best-effort, falla silenciosamente en Linux).
- **DB override en tests**: `ProviderScope` con `overrideWithValue` en test permite inyectar DB en memoria.
