import 'dart:async';

import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_model_pick_sheet.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_vehicle_model_catalog_repository.dart';
import '../../helpers/l10n_test_helpers.dart';

class _Host extends StatefulWidget {
  const _Host({required this.catalog, this.selected});

  final FakeVehicleModelCatalogRepository catalog;
  final String? selected;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  ListingModelPickResult? result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              FilledButton(
                key: const ValueKey('open_model_picker'),
                onPressed: () async {
                  final picked = await showListingModelPickSheet(
                    context: context,
                    l10n: AppLocalizations.of(context),
                    make: 'Honda',
                    selectedCanonicalModel: widget.selected,
                    catalog: widget.catalog,
                  );
                  if (picked != null) setState(() => result = picked);
                },
                child: const Text('open'),
              ),
              if (result != null)
                Text(
                  result!.manual ? 'manual' : result!.canonicalValue!,
                  key: const ValueKey('picker_result'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  await tester.tap(find.byKey(const ValueKey('open_model_picker')));
  await tester.pump();
}

void main() {
  final l10n = ruStrings();
  final ro = roStrings();

  testWidgets('shows loading then canonical models', (tester) async {
    final catalog = FakeVehicleModelCatalogRepository();
    catalog.gate = Completer<void>();
    await _open(tester, _Host(catalog: catalog));
    expect(find.byKey(const ValueKey('listing_model_loading')), findsOneWidget);

    catalog.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Civic'), findsOneWidget);
    expect(find.text('CR-V'), findsOneWidget);
    expect(find.text(l10n.listingModelNotListed), findsOneWidget);
  });

  testWidgets('search filters and empty state keeps fallback', (tester) async {
    final catalog = FakeVehicleModelCatalogRepository();
    await _open(tester, _Host(catalog: catalog));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('listing_model_search_field')),
      'cr',
    );
    await tester.pumpAndSettle();
    expect(find.text('CR-V'), findsOneWidget);
    expect(find.text('Civic'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('listing_model_search_field')),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('listing_model_empty_state')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('listing_model_manual_option')),
      findsOneWidget,
    );
  });

  testWidgets('selects canonical model and marks current selection', (
    tester,
  ) async {
    final catalog = FakeVehicleModelCatalogRepository();
    await _open(tester, _Host(catalog: catalog, selected: 'Civic'));
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const ValueKey('listing_model_Civic')),
    );
    expect(tile.selected, isTrue);

    await tester.tap(find.text('CR-V'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('picker_result')), findsOneWidget);
    expect(find.text('CR-V'), findsOneWidget);
  });

  testWidgets('controlled fallback returns manual result', (tester) async {
    final catalog = FakeVehicleModelCatalogRepository();
    await _open(tester, _Host(catalog: catalog));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_model_manual_option')));
    await tester.pumpAndSettle();
    expect(find.text('manual'), findsOneWidget);
  });

  testWidgets('error state retries successfully', (tester) async {
    final catalog = FakeVehicleModelCatalogRepository(
      failure: const ServerFailure('down'),
    );
    await _open(tester, _Host(catalog: catalog));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('listing_model_error_state')),
      findsOneWidget,
    );

    catalog.failure = null;
    await tester.tap(find.byKey(const ValueKey('listing_model_retry')));
    await tester.pumpAndSettle();
    expect(find.text('Civic'), findsOneWidget);
  });

  test('RU/RO picker copy exists and is not English leftovers', () {
    for (final value in [
      l10n.listingModelPickerTitle,
      l10n.listingModelSearchHint,
      l10n.listingModelNotListed,
      l10n.listingModelManualFieldLabel,
      l10n.listingModelLoadFailed,
      l10n.listingModelRetry,
      l10n.listingModelChooseMakeFirst,
      ro.listingModelPickerTitle,
      ro.listingModelSearchHint,
      ro.listingModelNotListed,
      ro.listingModelManualFieldLabel,
      ro.listingModelLoadFailed,
      ro.listingModelRetry,
      ro.listingModelChooseMakeFirst,
    ]) {
      expect(value.trim(), isNotEmpty);
      expect(value.toLowerCase(), isNot(contains('model not listed')));
    }
    expect(l10n.listingModelNotListed, isNot(ro.listingModelNotListed));
  });
}
