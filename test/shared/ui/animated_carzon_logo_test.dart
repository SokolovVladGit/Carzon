import 'package:carzon/shared/ui/animated_carzon_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('AnimatedCarzonLogo pumps in light theme', (tester) async {
    await tester.pumpWidget(
      host(
        const AnimatedCarzonLogo(
          key: Key('animatedCarzonLogo'),
          autoplay: false,
        ),
        theme: ThemeData.light(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('animatedCarzonLogo')), findsOneWidget);
    expect(find.bySemanticsLabel('Carzon'), findsOneWidget);
  });

  testWidgets('AnimatedCarzonLogo pumps in dark theme', (tester) async {
    await tester.pumpWidget(
      host(
        const AnimatedCarzonLogo(
          key: Key('animatedCarzonLogo'),
          autoplay: false,
        ),
        theme: ThemeData.dark(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('animatedCarzonLogo')), findsOneWidget);
    expect(find.bySemanticsLabel('Carzon'), findsOneWidget);
  });
}
