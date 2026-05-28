import 'package:flutter/material.dart';

import '../../../core/l10n/app_locale_preference.dart';
import '../../../l10n/app_localizations.dart';

/// Generic message notification copy (foreground local display).
///
/// Foreground local notifications use the active app locale. Remote Edge push
/// title/body are also locale-aware in repo (per recipient push token locale);
/// deploy updated Edge Functions before remote RU/RO copy is live in production.
abstract final class MessageNotificationPublicCopy {
  static String title(AppLocalePreference preference) =>
      _l10n(preference).notificationMessageTitle;

  static String body(AppLocalePreference preference) =>
      _l10n(preference).notificationMessageBody;

  static AppLocalizations _l10n(AppLocalePreference preference) {
    return lookupAppLocalizations(
      Locale(appLocalePreferenceToLanguageCode(preference)),
    );
  }
}
