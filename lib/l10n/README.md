# Localization

Carzon uses Flutter's built-in `gen-l10n` (see `l10n.yaml`). The
generated class is `AppLocalizations`:

```dart
import 'package:carzon/l10n/app_localizations.dart';

final l10n = AppLocalizations.of(context);
```

Pages can also use the `context.l10n` extension defined in
`lib/core/l10n/app_localizations_x.dart`.

## Supported locales

- **Russian (`ru`)** — default on fresh install; fallback locale.
- **Romanian (`ro`)** — user-selectable in Profile → Settings.

App language is **user-controlled** (see `AppLocaleCubit`), not the
device locale. `MaterialApp.router` receives `locale` from the cubit.

## Adding or updating strings

1. Add the key to `app_ru.arb` (template).
2. Add the same key with Romanian text to `app_ro.arb`.
3. Run `flutter gen-l10n` (or `flutter pub get` when `generate: true`).
4. Use `context.l10n` in presentation code only.

Romanian `app_ro.arb` was initially generated with
`tool/generate_app_ro_arb.py` (RU→RO, with manual VIN/notification
overrides). Re-run only for bulk catch-up; review ICU placeholders,
VIN, and legal copy manually.

## Conventions

- Presentation layer only: no localization lookups in `domain/` or
  `data/` layers.
- Enum-backed label helpers accept `AppLocalizations`.
- Date/number formatting should use `l10n.localeName` or
  `AppLocaleCubit.state.intlLanguageTag`, not a hardcoded `'ru'`.
