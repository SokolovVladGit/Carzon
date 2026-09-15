import 'package:carzon/features/listings/presentation/widgets/listings_search_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  late TextEditingController controller;
  late List<String> submitted;
  var clearCount = 0;

  Finder leadingIcon() =>
      find.byKey(ListingsSearchFilterBar.leadingSearchIconKey);
  Finder submitAction() => find.byKey(ListingsSearchFilterBar.submitActionKey);

  Widget bar() {
    return ListingsSearchFilterBar(
      searchCtrl: controller,
      onOpenFilters: () {},
      onSearchSubmitted: submitted.add,
      onClearSearch: () {
        clearCount++;
        controller.clear();
      },
      active: false,
      bellBadge: false,
    );
  }

  Future<void> pumpBar(
    WidgetTester tester, {
    Locale locale = const Locale('ru'),
    ThemeData? theme,
    double width = 390,
  }) async {
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: Scaffold(
          body: Theme(
            data: theme ?? ThemeData(useMaterial3: true),
            child: Center(
              child: SizedBox(width: width, child: bar()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> typeQuery(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  setUp(() {
    controller = TextEditingController();
    submitted = <String>[];
    clearCount = 0;
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets(
    'empty field shows leading search icon and hides trailing action',
    (tester) async {
      await pumpBar(tester);

      expect(leadingIcon(), findsOneWidget);
      expect(submitAction(), findsNothing);
    },
  );

  testWidgets(
    'non-empty field hides leading icon and shows trailing search action',
    (tester) async {
      await pumpBar(tester);
      await typeQuery(tester, 'BMW');

      expect(leadingIcon(), findsNothing);
      expect(submitAction(), findsOneWidget);
    },
  );

  testWidgets(
    'typed-state search action is a flush end-cap of the search pill',
    (tester) async {
      await pumpBar(tester);
      await typeQuery(tester, 'BMW');

      final pill = tester.getRect(
        find.byKey(ListingsSearchFilterBar.searchFieldKey),
      );
      final action = tester.getRect(submitAction());

      expect(action.right, closeTo(pill.right, 0.5));
      expect(action.top, closeTo(pill.top, 0.5));
      expect(action.bottom, closeTo(pill.bottom, 0.5));
      expect(action.height, closeTo(pill.height, 0.5));
    },
  );

  testWidgets(
    'tapping trailing action submits the current query and unfocuses',
    (tester) async {
      await pumpBar(tester);
      await typeQuery(tester, 'Audi A4');

      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );

      await tester.tap(submitAction());
      await tester.pump();

      expect(submitted, ['Audi A4']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isFalse,
      );
    },
  );

  testWidgets('keyboard Search action still submits through the same handler', (
    tester,
  ) async {
    await pumpBar(tester);
    await typeQuery(tester, 'Passat');
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(submitted, ['Passat']);
  });

  testWidgets('clearing text restores the empty-state leading icon', (
    tester,
  ) async {
    final l10n = ruStrings();
    await pumpBar(tester);
    await typeQuery(tester, 'Golf');

    expect(submitAction(), findsOneWidget);
    expect(leadingIcon(), findsNothing);

    await tester.tap(find.byTooltip(l10n.listingsSearchClearTooltip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(clearCount, 1);
    expect(controller.text, isEmpty);
    expect(leadingIcon(), findsOneWidget);
    expect(submitAction(), findsNothing);
  });

  testWidgets('RO placeholder and submit tooltip stay localized', (
    tester,
  ) async {
    final l10n = roStrings();
    await pumpBar(tester, locale: const Locale('ro'));

    expect(find.text(l10n.listingsSearchHint), findsOneWidget);

    await typeQuery(tester, 'Dacia');

    expect(find.byTooltip(l10n.listingsSearchSubmitTooltip), findsOneWidget);
  });

  testWidgets('long query still fits on compact iPhone width', (tester) async {
    await pumpBar(tester, width: 320);
    await typeQuery(tester, 'Mercedes-Benz GLE 450 4MATIC AMG');

    expect(tester.takeException(), isNull);
    expect(submitAction(), findsOneWidget);
    expect(find.byTooltip(ruStrings().listingsFiltersTooltip), findsOneWidget);
  });

  testWidgets('dark mode keeps the in-field search action tappable', (
    tester,
  ) async {
    await pumpBar(
      tester,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    );
    await typeQuery(tester, 'Skoda');

    await tester.tap(submitAction());
    await tester.pump();

    expect(submitted, ['Skoda']);
  });
}
