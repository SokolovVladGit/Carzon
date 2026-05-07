import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synchronously resolves an [AppLocalizations] instance for `ru` so
/// tests can assert against the exact localized strings the app
/// renders. Uses the gen_l10n-emitted [lookupAppLocalizations]
/// top-level function, which is a synchronous factory for Carzon's
/// single supported locale.
AppLocalizations ruStrings() => lookupAppLocalizations(const Locale('ru'));

/// Builds a [MaterialApp] wrapper with the Russian locale forced and
/// all required localization delegates installed. Use for widget tests
/// of pages/widgets that call `context.l10n` so the delegate chain
/// matches the production `CarzonApp` configuration.
MaterialApp localizedApp({
  required Widget home,
  NavigatorObserver? navigatorObserver,
}) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: [?navigatorObserver],
    home: home,
  );
}

/// Convenience for tests that need to pump a widget with the full
/// localization setup installed. Wraps [widget] in [localizedApp],
/// pumps it, and lets the initial frame settle so `AppLocalizations.of`
/// is available when the test asserts against text.
Future<void> pumpLocalizedWidget(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(localizedApp(home: widget));
  await tester.pump();
}
