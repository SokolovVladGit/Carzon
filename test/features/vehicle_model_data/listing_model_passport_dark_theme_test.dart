import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/vehicle_model_data/domain/entities/buyer_listing_model_data_source_result.dart';
import 'package:carzon/features/vehicle_model_data/domain/repositories/model_data_repository.dart';
import 'package:carzon/features/vehicle_model_data/domain/usecases/get_listing_model_data_for_buyer.dart';
import 'package:carzon/features/vehicle_model_data/presentation/widgets/listing_details_model_passport_section.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

class _FakeModelDataRepository implements ModelDataRepository {
  _FakeModelDataRepository(this._rows);

  final List<BuyerListingModelDataSourceResult> _rows;

  @override
  Future<Result<List<BuyerListingModelDataSourceResult>>>
  getListingModelDataForBuyer(String listingId) async {
    return Success(_rows);
  }
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerFactory<GetListingModelDataForBuyer>(
      () => GetListingModelDataForBuyer(
        _FakeModelDataRepository([
          BuyerListingModelDataSourceResult(
            sourceId: 'epa_fueleconomy',
            status: 'succeeded',
            sourceLabel: 'EPA · FuelEconomy.gov',
            normalizedSummary: const {'combined_l_per_100km': 7.35},
          ),
        ]),
      ),
    );
  });

  testWidgets('renders in dark mode with visible card and text', (tester) async {
    final ru = ruStrings();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ListingDetailsModelPassportSection(listingId: 'l1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_model_passport_section')), findsOneWidget);
    expect(find.text(ru.listingModelPassportSectionTitle), findsOneWidget);
    expect(find.text('EPA · FuelEconomy.gov'), findsOneWidget);

    final titleStyle = tester.widget<Text>(find.text(ru.listingModelPassportSectionTitle)).style;
    expect(titleStyle?.color, isNotNull);
  });

  testWidgets('renders pending card in dark mode', (tester) async {
    await sl.reset();
    sl.registerFactory<GetListingModelDataForBuyer>(
      () => GetListingModelDataForBuyer(
        _FakeModelDataRepository([
          BuyerListingModelDataSourceResult(
            sourceId: 'epa_fueleconomy',
            status: 'pending',
            sourceLabel: 'EPA · FuelEconomy.gov',
          ),
        ]),
      ),
    );

    final ru = ruStrings();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ListingDetailsModelPassportSection(listingId: 'l1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_model_passport_pending')), findsOneWidget);
    expect(find.text(ru.listingModelPassportPendingTitle), findsOneWidget);
  });
}
