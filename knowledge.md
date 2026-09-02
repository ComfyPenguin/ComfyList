# comfy_list — Project Knowledge

## What this is

Multi-platform TODO + appointments app ("ComfyList") with Firebase sync. Flutter (Material 3), mobile + desktop (Android, iOS, Windows, macOS, Linux, web).

## Where key code lives

- `lib/features/<feature>/` — feature-first + Clean Architecture, 3 layers per feature:
  - `data/datasources/` — remote/local datasources (Dio REST calls)
  - `data/models/` — DTOs with serialization
  - `data/repositories/` — repo implementations
  - `domain/entities/` — immutable domain models with `copyWith`
  - `domain/repositories/` — abstract interfaces
  - `presentation/providers/` — Riverpod Notifiers + sealed-class State
  - `presentation/screens/` + `presentation/widgets/`
- Features: `todos`, `todo_lists`, `appointments`, `auth`, `settings`
- `lib/routing/` — GoRouter setup (`ShellRoute` + `_AppStateListenable`)
- `lib/shared/` — shared UI (theme, `app_shell.dart`, `SecureSessionStore`)
- `test/` — mirrors `lib/features` structure; DB tests use in-memory Drift

## Commands

```sh
flutter run                  # Launch app
flutter analyze              # Static analysis (run after every change)
flutter test                 # Tests
dart run build_runner build  # Drift codegen (after modifying tables/DAOs)
dart run build_runner watch  # Codegen watch mode
```

## Stack & conventions

- **State**: Riverpod 3 (`Notifier<T>` + `sealed class` State: `Initial`/`Loading`/`Data`/`Error`). `todosProvider` is a `NotifierProvider.family` keyed by `listId`. No other state managers, no `get_it`.
- **Routing**: GoRouter with `ShellRoute` (`AppShell`: BottomBar + AppBar + FAB). Edit routes (`/lists/new`, `/lists/:id/edit`) live outside the shell. All transitions instant (`CustomTransitionPage`, duration 0).
- **HTTP**: Dio only. **No Firebase SDK** — everything via Firebase REST API (Identity Toolkit + Firestore REST). `firebase_core` is only for compatibility; never import `cloud_firestore`/`firebase_auth`. Two Dio clients: `instance` (auth interceptor) and `authClient` (no interceptor, for signUp/signIn).
- **Local DB**: Drift (SQLite), schema v4 with sequential `onUpgrade` migrations. Tables: `settings_table` (singleton id=1), `account_cache_table`. `appDatabaseProvider` throws `UnimplementedError` and is overridden in `main()`.
- **Auth**: Identity Toolkit REST + Google Sign-In (Android only, `Platform.isAndroid`). Tokens only in `flutter_secure_storage` via `SecureSessionStore`.
- **Repos**: return `Result<T>` (`Ok` | `Err`) — never throw exceptions.
- **UI**: project theming (`app_colors`, `app_typography`, `app_spacing`, `app_radius`); fonts PlusJakartaSans/Fredoka.
- **Language**: user-facing copy in Spanish (Spain, "tú"); code/identifiers in English; comments in Spanish.

## Gotchas

- All API calls must go through `DioClient`; no token storage outside `SecureSessionStore`.
- Entities use boolean `clearDescription`/`clearLocation` flags (not nullable fields) in `copyWith` to distinguish "don't touch" from "set null".
- `NotificationsService.init()` wrapped in try-catch (best-effort; fails silently on Linux).
- Tests inject in-memory DB via `ProviderScope` + `overrideWithValue`.
- Conventional commits; don't create `.md` files unless asked (this file and AGENTS.md are the exceptions).