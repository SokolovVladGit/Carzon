import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Concise access to [AppLocalizations] from a [BuildContext].
///
/// Usage:
/// ```dart
/// final l10n = context.l10n;
/// Text(l10n.signInTitle);
/// ```
///
/// `AppLocalizations.of(context)` is guaranteed non-null at runtime for
/// Carzon because the app always renders with `Locale('ru')` and the
/// `AppLocalizations` delegate is installed in `MaterialApp.router`.
/// If `AppLocalizations` is missing (e.g. a test forgot the
/// localization delegates), this extension throws a clear
/// [FlutterError] instead of returning `null`.
extension AppLocalizationsX on BuildContext {
  /// The generated getter is typed non-null (`nullable-getter: false`
  /// in `l10n.yaml`), so a missing delegate surfaces as a framework
  /// assertion inside `AppLocalizations.of` before we get here. No
  /// extra null-guard is needed at this layer.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
