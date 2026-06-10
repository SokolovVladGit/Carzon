import 'package:carzon/app/bootstrap_splash_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BootstrapSplashApp pumps with animated logo and semantics', (
    tester,
  ) async {
    await tester.pumpWidget(const BootstrapSplashApp());
    await tester.pump();

    expect(find.byType(BootstrapSplashView), findsOneWidget);
    expect(find.byKey(const Key('bootstrapSplashAnimatedLogo')), findsOneWidget);
    expect(find.bySemanticsLabel('Carzon'), findsOneWidget);
  });

  testWidgets('BootstrapSplashApp uses static logo when animations disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const BootstrapSplashView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('bootstrapSplashStaticLogo')), findsOneWidget);
    expect(
      find.byKey(const Key('bootstrapSplashAnimatedLogo')),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Carzon'), findsOneWidget);
  });
}
