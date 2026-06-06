import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/compare/presentation/utils/compare_tray_layout.dart'
    show
        compareTrayBottomInset,
        compareTrayHiddenForRoute,
        compareTrayVisibleForRoute,
        compareTrayUsesBottomNavClearance;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareTrayVisibleForRoute', () {
    test('shows only on listings discovery home', () {
      expect(compareTrayVisibleForRoute(AppRoutes.listings), isTrue);
      expect(compareTrayVisibleForRoute('/?openFilters=1'), isTrue);
    });

    test('hidden on compare page', () {
      expect(compareTrayVisibleForRoute(AppRoutes.compare), isFalse);
      expect(compareTrayHiddenForRoute(AppRoutes.compare), isTrue);
    });

    test('hidden on listing details', () {
      expect(compareTrayVisibleForRoute('/listings/abc-123'), isFalse);
    });

    test('hidden on create listing', () {
      expect(compareTrayVisibleForRoute(AppRoutes.createListing), isFalse);
    });

    test('hidden on edit listing', () {
      expect(compareTrayVisibleForRoute('/listings/abc/edit'), isFalse);
    });

    test('hidden on menu and profile', () {
      expect(compareTrayVisibleForRoute(AppRoutes.menu), isFalse);
      expect(compareTrayVisibleForRoute(AppRoutes.profile), isFalse);
    });

    test('hidden on favorites and my listings', () {
      expect(compareTrayVisibleForRoute(AppRoutes.favorites), isFalse);
      expect(compareTrayVisibleForRoute(AppRoutes.myListings), isFalse);
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

  testWidgets('compareTrayBottomInset uses nav clearance on home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: _InsetProbe(location: AppRoutes.listings)),
    );

    expect(find.text('76.0'), findsOneWidget);
  });

  testWidgets('compareTrayBottomInset uses safe padding elsewhere', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: _InsetProbe(location: '/profile')),
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
