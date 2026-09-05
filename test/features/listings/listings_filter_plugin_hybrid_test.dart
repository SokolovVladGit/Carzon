import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  testWidgets('plug-in hybrid is available in the fuel picker', (tester) async {
    final formKey = GlobalKey<ListingsFilterFormState>();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListingsFilterForm(
              key: formKey,
              seed: ListingsFilterFormSeed.fromListingsState(
                const ListingsState(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fuelTrigger = find.byKey(
      const ValueKey<String>('listings_filter_fuel_type_pick_trigger'),
    );
    await tester.scrollUntilVisible(
      fuelTrigger,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fuelTrigger);
    await tester.pumpAndSettle();
    final phev = find.text(l10n.listingFuelTypePlugInHybrid);
    await tester.scrollUntilVisible(
      phev,
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(phev);
    await tester.pumpAndSettle();

    expect(
      formKey.currentState!.draftSeed.fuelType,
      ListingFuelType.plugInHybrid,
    );
    expect(
      find.descendant(
        of: fuelTrigger,
        matching: find.text(l10n.listingFuelTypePlugInHybrid),
      ),
      findsOneWidget,
    );
  });
}
