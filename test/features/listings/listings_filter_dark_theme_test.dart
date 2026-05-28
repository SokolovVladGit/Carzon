import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form_seed.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_host.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  testWidgets('ListingsFilterHost renders key labels in dark theme', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.filtersTitle), findsOneWidget);
    expect(find.text(l10n.filtersSectionMakeModel), findsOneWidget);
    expect(find.text(l10n.filtersSectionBudget), findsOneWidget);
    expect(find.text(l10n.filterClear), findsOneWidget);
    expect(find.text(l10n.filterShowCars), findsOneWidget);
    expect(find.text(l10n.filtersSummaryDefaultTitle), findsOneWidget);
  });
}
