import 'package:carzon/app/startup_error_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StartupErrorApp follows system theme and exposes dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StartupErrorApp(
        title: 'Startup failed',
        message: 'Could not initialize.',
      ),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.system);
    expect(materialApp.darkTheme?.brightness, Brightness.dark);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, isNotNull);
  });
}
