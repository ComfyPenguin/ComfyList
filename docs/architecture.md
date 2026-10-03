# Architecture — ComfyList

Convenciones de estructura y navegación. `AGENTS.md` enlaza aquí; el detalle de trampas vive en `docs/gotchas.md`.

## Capas por feature

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

## State Management

- `Notifier<T>` + `sealed class` State con variantes: `Initial`, `Loading`, `Data`, `Error`.
- Los providers se activan desde el router en `_AppStateListenable` (`lib/routing/app_router.dart`).
- `todosProvider` usa `NotifierProvider.family` (parametrizado por `listId`).

## Routing (GoRouter)

- `ShellRoute` con `AppShell` (BottomBar + AppBar + FAB persistente).
- **Edición fuera del shell**: rutas como `/lists/new`, `/lists/:id/edit` se declaran fuera del `ShellRoute`.
- `_instantPage()`: todas las transiciones son instantáneas (`CustomTransitionPage` duración 0).
- Redirect logic en `routerProvider`: splash → auth check → precarga datos → home.
