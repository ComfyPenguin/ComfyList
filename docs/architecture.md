# Architecture — ComfyList

Convenciones de estructura, datos y navegación. `AGENTS.md` enlaza aquí; el detalle de trampas vive en `docs/gotchas.md`.

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

## Estructura de datos

Firestore es la fuente de verdad y vive bajo `users/{uid}/…`; Drift guarda en local lo que no viaja a la cuenta (preferencias, caché y reintentos). `FirestoreValueCodec` (`shared/data/remote/`) traduce entre el formato REST (`{ fields: … }` tipado) y mapas Dart planos: entiende `string`, `bool`, `int`, `double`, `DateTime` (timestamp) y `null`, y el id sale del último segmento del `name` del documento.

### Firestore

| Ruta | Campos |
| --- | --- |
| `users/{uid}/todo_lists/{id}` | `name`, `iconKey`, `createdAt`, `updatedAt` |
| `users/{uid}/todo_lists/{listId}/todos/{id}` | `title`, `description?`, `isDone`, `createdAt`, `updatedAt` |
| `users/{uid}/appointments/{id}` | `title`, `description?`, `location?`, `dateTime`, `isDone`, `createdAt`, `updatedAt` |
| `users/{uid}/trash/{id}` | `groupId`, `kind` (`list`/`todo`/`appointment`), `itemId`, `parentId?`, `label`, `payload` (entidad serializada a JSON en un campo de texto) y `deletedAt` |

Las reglas de `firestore.rules` exigen `request.auth.uid == uid` y correo verificado sobre todo `users/{uid}/**`.

### Drift

| Tabla | Contenido |
| --- | --- |
| `settings_table` (singleton `id=1`) | Preferencias locales: tema, notificaciones, ordenación, gestos, formato horario, márgenes de aviso, retención de la papelera y el estado del comprobador de actualizaciones (última comprobación y versión descartada) |
| `account_cache_table` | Perfil para pintar algo sin red (`uid`, `email`, `displayName?`, `cachedAt`); la fuente real es Identity Toolkit |
| `trash_pending_table` | Restauraciones que no pudieron quitarse de Firestore; se reintentan antes de cada lectura de la papelera |

## State Management

- `Notifier<T>` + `sealed class` State con variantes: `Initial`, `Loading`, `Data`, `Error`.
- Los providers se activan desde el router en `_AppStateListenable` (`lib/routing/app_router.dart`).
- `todosProvider` usa `NotifierProvider.family` (parametrizado por `listId`).

## Routing (GoRouter)

- `ShellRoute` con `AppShell` (BottomBar + AppBar + FAB persistente).
- **Edición fuera del shell**: rutas como `/lists/new`, `/lists/:id/edit` se declaran fuera del `ShellRoute`.
- `_instantPage()`: todas las transiciones son instantáneas (`CustomTransitionPage` duración 0).
- Redirect logic en `routerProvider`: splash → auth check → precarga datos → home.
