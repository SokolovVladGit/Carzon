# Localization

Carzon uses Flutter's built-in `gen-l10n` (see `l10n.yaml`). The
generated class is `AppLocalizations` and is imported in presentation
code as:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final l10n = AppLocalizations.of(context);
```

Pages can also use the `context.l10n` extension defined in
`lib/core/l10n/app_localizations_x.dart`.

## Supported locales

- **Russian (`ru`)** — the product language for the Transnistria MVP
  launch. This is also the **default and fallback** locale: the
  `MaterialApp.router` passes `locale: const Locale('ru')` explicitly,
  so Carzon renders in Russian regardless of the device locale.

## Planned future locales (NOT yet supported)

Do not add placeholder translations for these. They are listed here so
the team knows the shape of the upcoming work.

- **Romanian (`ro`)** — planned second language for Moldova proper.
  Will be added as `lib/l10n/app_ro.arb`.
- **English (`en`)** — planned for demos, support, and international
  review. Will be added as `lib/l10n/app_en.arb`.

When either language is added:

1. Copy `app_ru.arb` to the new file, strip the Russian text, and
   translate every key.
2. Do not add `@@locale` + an empty body: gen-l10n expects every key
   present in the template ARB.
3. Add the new `Locale(...)` to the `supportedLocales` wiring in
   `lib/app/app.dart`.
4. Decide (with product) whether the default/fallback is still Russian
   or should switch to the device locale — do not flip this silently.

## Conventions

- Presentation layer only: no localization lookups in `domain/` or
  `data/` layers.
- Formatters for enum-backed display labels
  (`formatType`, `formatMarketRegion`, `formatStatus`) accept a
  `AppLocalizations` instance and return localized labels.
- Contact validators (`validatePhone`, `validateTelegramUsername`) also
  accept an `AppLocalizations` instance.
- `buildReportListingMailto` takes an `AppLocalizations` so the email
  subject and body it produces are shown to the user in the same
  language as the rest of the app.
