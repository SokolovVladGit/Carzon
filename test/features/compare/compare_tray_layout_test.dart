import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/compare/presentation/utils/compare_tray_layout.dart'
    show
        compareTrayBottomInset,
        compareTrayHiddenForRoute,
        compareTrayUsesBottomNavClearance;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareTrayHiddenForRoute', () {
    test('hides on compare page', () {
      expect(compareTrayHiddenForRoute(AppRoutes.compare), isTrue);
    });

    test('shows on listing details', () {
      expect(compareTrayHiddenForRoute('/listings/abc-123'), isFalse);
    });

    test('shows on listings home', () {
      expect(compareTrayHiddenForRoute(AppRoutes.listings), isFalse);
    });

    test('shows on menu', () {
      expect(compareTrayHiddenForRoute(AppRoutes.menu), isFalse);
    });
  });

  group('compareTrayUsesBottomNavClearance', () {
    test('true for top-level routes with floating nav', () {
      expect(compareTrayUsesBottomNavClearance(AppRoutes.favorites), isTrue);
      expect(compareTrayUsesBottomNavClearance(AppRoutes.menu), isTrue);
    });

    test('false for listing details', () {
      expect(compareTrayUsesBottomNavClearance('/listings/abc'), isFalse);
    });

    test('false for profile', () {
      expect(compareTrayUsesBottomNavClearance('/profile'), isFalse);
    });
  });

  testWidgets('compareTrayBottomInset uses nav clearance on home', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _InsetProbe(location: AppRoutes.listings),
      ),
    );

    expect(find.text('76.0'), findsOneWidget);
  });

  testWidgets('compareTrayBottomInset uses contact bar clearance on details', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _InsetProbe(location: '/listings/abc'),
      ),
    );

    expect(find.text('82.0'), findsOneWidget);
  });

  testWidgets('compareTrayBottomInset uses safe padding elsewhere', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _InsetProbe(location: '/profile'),
      ),
    );

    expect(find.text('16.0'), findsOneWidget);
  });
}

class _InsetProbe extends StatelessWidget {
  const _InsetProbe({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final inset = compareTrayBottomInset(context, location);
    return Scaffold(body: Text(inset.toStringAsFixed(1)));
  }
}
