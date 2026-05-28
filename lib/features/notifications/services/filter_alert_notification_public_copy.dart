import 'package:flutter/material.dart';

import '../../../core/l10n/app_locale_preference.dart';
import '../../../l10n/app_localizations.dart';

/// Public notification copy for filter alerts (foreground local display).
abstract final class FilterAlertNotificationPublicCopy {
  static String title(AppLocalePreference preference) =>
      _l10n(preference).notificationFilterAlertTitle;

  static String body(AppLocalePreference preference) =>
      _l10n(preference).notificationFilterAlertBody;

  static AppLocalizations _l10n(AppLocalePreference preference) {
    return lookupAppLocalizations(
      Locale(appLocalePreferenceToLanguageCode(preference)),
    );
  }
}
