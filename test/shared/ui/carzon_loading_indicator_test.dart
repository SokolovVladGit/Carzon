import 'package:carzon/shared/ui/carzon_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('CarzonLoadingIndicator pumps in animation mode', (tester) async {
    await tester.pumpWidget(
      host(
        const CarzonLoadingIndicator(
          key: Key('carzonLoadingIndicator'),
          autoplay: true,
        ),
        theme: ThemeData.light(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('carzonLoadingIndicator')), findsOneWidget);
    expect(
      find.byKey(const Key('carzonLoadingIndicatorAnimated')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('CarzonLoadingIndicator uses static Z when animations disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const CarzonLoadingIndicator(
                key: Key('carzonLoadingIndicator'),
                autoplay: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('carzonLoadingIndicatorStatic')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });
}
