# Carzon

Mobile-first Flutter app for the Moldovan car marketplace (buy / sell / exchange).
Backend: Supabase. A separate React web client will reuse the same backend later.

## Architecture

Feature-first, layered (Clean-Architecture-lite):

```
lib/
├── main.dart
├── app/                       # composition root
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── di/injection.dart      # aggregates per-feature DI
│   └── router/app_router.dart
├── core/                      # cross-cutting infrastructure
│   ├── config/  constants/  errors/  extensions/
│   ├── services/  theme/  utils/  widgets/
├── features/<feature>/
│   ├── di/                    # feature-local DI registration
│   ├── data/{datasources,models,repositories}
│   ├── domain/{entities,repositories,usecases}
│   └── presentation/{bloc,pages,widgets}
└── shared/                    # cross-feature reusable building blocks
```

### Rules

- **Presentation never touches Supabase.** Only `data/datasources/` does.
- **Domain has no Flutter or Supabase imports.** It is pure Dart.
- **Repositories return `Result<T>`** (`Success` / `FailureResult<Failure>`).
- **State management:** `Cubit` for simple state (e.g. auth session),
  `Bloc` for event-driven flows (e.g. paginated listings).
- **DI:** single global `GetIt` instance (`sl`) in `app/di/injection.dart`.
  Each feature owns `features/<feature>/di/<feature>_injection.dart` and is
  registered from the app-level bootstrap. No giant DI file.

### Web reuse

Domain entities, use cases, and the repository contracts are framework-agnostic
and can be lifted into a shared Dart package later, or directly mirrored by the
React client (the contracts double as the API surface to design against).

## Setup

```bash
cp .env.example .env
# fill in SUPABASE_URL and SUPABASE_ANON_KEY
flutter pub get
flutter run
```

## Testing

```bash
flutter test
```

## Adding a new feature

1. Create `lib/features/<name>/{di,data,domain,presentation}/...`.
2. Implement the layers (datasource → repository impl → usecases → bloc/cubit → page).
3. Add `lib/features/<name>/di/<name>_injection.dart` that registers everything.
4. Wire it in `lib/app/di/injection.dart` (one line).
5. Add a route in `lib/app/router/app_router.dart` if it has UI.

No app-level refactor required.
