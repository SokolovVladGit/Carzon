import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synchronously resolves [AppLocalizations] for `ru`.
AppLocalizations ruStrings() => lookupAppLocalizations(const Locale('ru'));

/// Synchronously resolves [AppLocalizations] for `ro`.
AppLocalizations roStrings() => lookupAppLocalizations(const Locale('ro'));

/// Builds a [MaterialApp] wrapper with localization delegates installed.
MaterialApp localizedApp({
  required Widget home,
  Locale locale = const Locale('ru'),
  NavigatorObserver? navigatorObserver,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: [?navigatorObserver],
    home: home,
  );
}

/// Convenience for tests that need to pump a widget with localization.
Future<void> pumpLocalizedWidget(
  WidgetTester tester,
  Widget widget, {
  Locale locale = const Locale('ru'),
}) async {
  await tester.pumpWidget(localizedApp(home: widget, locale: locale));
  await tester.pump();
}
