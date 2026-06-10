import 'package:carzon/shared/ui/carzon_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const logoKey = Key('testCarzonLogo');

  Widget host(Widget child, {required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders in light theme with key and semantics', (tester) async {
    await tester.pumpWidget(
      host(const CarzonLogo(key: logoKey), theme: ThemeData.light()),
    );
    await tester.pump();

    expect(find.byKey(logoKey), findsOneWidget);
    expect(find.bySemanticsLabel('Carzon'), findsOneWidget);
  });

  testWidgets('renders in dark theme with key and semantics', (tester) async {
    await tester.pumpWidget(
      host(const CarzonLogo(key: logoKey), theme: ThemeData.dark()),
    );
    await tester.pump();

    expect(find.byKey(logoKey), findsOneWidget);
    expect(find.bySemanticsLabel('Carzon'), findsOneWidget);
  });
}
