import 'dart:async';

import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_apply_result.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_vehicle_model_catalog_repository.dart';
import '../../helpers/filter_form_brand_picker_helpers.dart';
import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  Future<
    (GlobalKey<ListingsFilterFormState>, FakeVehicleModelCatalogRepository)
  >
  pumpForm(
    WidgetTester tester, {
    ListingsState seed = const ListingsState(),
  }) async {
    final catalog = FakeVehicleModelCatalogRepository();
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
              seed: ListingsFilterFormSeed.fromListingsState(seed),
              vehicleModelCatalog: catalog,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (formKey, catalog);
  }

  Future<void> openModel(WidgetTester tester) async {
    final field = find.byKey(const ValueKey('listings_filter_model_field'));
    await tester.scrollUntilVisible(
      field,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(field);
    await tester.pumpAndSettle();
  }

  testWidgets('no make keeps model selector disabled and cleared', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.text(l10n.listingModelChooseMakeFirst), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('listings_filter_model_field')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('listing_model_search_field')),
      findsNothing,
    );
  });

  testWidgets('make change clears previously selected model', (tester) async {
    final (formKey, _) = await pumpForm(tester);
    await pickListingFilterBrand(tester, 'Honda');
    await openModel(tester);
    await tester.tap(find.text('Civic'));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.draftSeed.model, 'Civic');

    await pickListingFilterBrand(tester, 'Toyota');
    expect(formKey.currentState!.draftSeed.model, isNull);
    expect(find.text('Civic'), findsNothing);
  });

  testWidgets('stale hydrate cannot populate a newer make', (tester) async {
    final catalog = FakeVehicleModelCatalogRepository();
    catalog.gate = Completer<void>();
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
                const ListingsState(make: 'Honda', model: 'Civic'),
              ),
              vehicleModelCatalog: catalog,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await pickListingFilterBrand(tester, 'Toyota');
    catalog.gate!.complete();
    await tester.pumpAndSettle();
    expect(formKey.currentState!.draftSeed.make, 'Toyota');
    expect(formKey.currentState!.draftSeed.model, isNull);
    expect(find.text('Civic'), findsNothing);
  });

  testWidgets('canonical filter model is applied as ordinary string', (
    tester,
  ) async {
    final (formKey, _) = await pumpForm(tester);
    await pickListingFilterBrand(tester, 'Honda');
    await openModel(tester);
    await tester.tap(find.text('CR-V'));
    await tester.pumpAndSettle();

    final result = formKey.currentState!.submit();
    expect(result, isA<ListingsFilterApplyResult>());
    expect(result!.make, 'Honda');
    expect(result.model, 'CR-V');
  });

  testWidgets('fallback keeps historical/manual model searchable', (
    tester,
  ) async {
    final (formKey, _) = await pumpForm(
      tester,
      seed: const ListingsState(make: 'Audi', model: 'А5'),
    );
    expect(find.text(l10n.listingModelNotListed), findsOneWidget);
    expect(find.text('А5'), findsOneWidget);
    expect(find.text('A5'), findsNothing);

    final result = formKey.currentState!.submit();
    expect(result!.make, 'Audi');
    expect(result.model, 'А5');
  });
}
