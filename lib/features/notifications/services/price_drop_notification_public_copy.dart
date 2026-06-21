import 'package:flutter/material.dart';

import '../../../core/l10n/app_locale_preference.dart';
import '../../../l10n/app_localizations.dart';

/// Public notification copy for price-drop alerts (foreground local display).
abstract final class PriceDropNotificationPublicCopy {
  static String title(AppLocalePreference preference) =>
      _l10n(preference).notificationPriceDropTitle;

  static String body(AppLocalePreference preference) =>
      _l10n(preference).notificationPriceDropBody;

  static AppLocalizations _l10n(AppLocalePreference preference) {
    return lookupAppLocalizations(
      Locale(appLocalePreferenceToLanguageCode(preference)),
    );
  }
}
