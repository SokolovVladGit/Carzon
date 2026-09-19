import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/create_saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/list_saved_searches.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_saved_search_alerts_enabled.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/listings/presentation/widgets/search_nav_indicators.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/browse_catalog_filter_alerts_sl.dart';

NotificationPreferences _prefs({
  required bool global,
  required bool filterAlerts,
}) {
  return NotificationPreferences(
    userId: 'u',
    globalEnabled: global,
    messagesEnabled: true,
    filterAlertsEnabled: filterAlerts,
    priceDropsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

SavedSearch _bmwRow({required bool alertsEnabled}) {
  return SavedSearch(
    id: 's1',
    name: 'BMW',
    criteria: const ListingDiscoveryCriteria(make: 'BMW'),
    alertsEnabled: alertsEnabled,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  late MockSavedSearchesRepository saved;
  late MockNotificationsRepository prefs;
  late MockPushNotificationRegistrationService push;
  late BrowseCatalogFilterAlertsCubit alerts;

  setUp(() {
    saved = MockSavedSearchesRepository();
    prefs = MockNotificationsRepository();
    push = MockPushNotificationRegistrationService();
    alerts = BrowseCatalogFilterAlertsCubit(
      listSavedSearches: ListSavedSearches(saved),
      createSavedSearch: CreateSavedSearch(saved),
      notificationsRepository: prefs,
      deliveryOrchestrator: FilterAlertDeliveryOrchestrator(
        notificationsRepository: prefs,
        pushRegistration: push,
        setAlertsEnabled: SetSavedSearchAlertsEnabled(saved),
      ),
    );
  });

  tearDown(() async {
    await alerts.close();
  });

  test('vanilla applied state is inactive without bell', () {
    alerts.emit(
      const BrowseCatalogFilterAlertsState(
        phase: BrowseCatalogFilterAlertsLoadPhase.ready,
      ),
    );
    final data = resolveSearchNavIndicatorData(
      applied: const ListingsState(),
      alerts: alerts,
    );
    expect(data.active, isFalse);
    expect(data.bell, isFalse);
  });

  test('make filter is active without requiring a saved alert', () {
    alerts.emit(
      const BrowseCatalogFilterAlertsState(
        phase: BrowseCatalogFilterAlertsLoadPhase.ready,
      ),
    );
    final data = resolveSearchNavIndicatorData(
      applied: const ListingsState(make: 'BMW'),
      alerts: alerts,
    );
    expect(data.active, isTrue);
    expect(data.bell, isFalse);
  });

  test('bell hidden while cubit is loading even if saved row would match', () {
    alerts.emit(
      BrowseCatalogFilterAlertsState(
        phase: BrowseCatalogFilterAlertsLoadPhase.loading,
        savedSearches: [_bmwRow(alertsEnabled: true)],
        prefs: _prefs(global: true, filterAlerts: true),
      ),
    );
    final data = resolveSearchNavIndicatorData(
      applied: const ListingsState(make: 'BMW'),
      alerts: alerts,
    );
    expect(data.active, isTrue);
    expect(data.bell, isFalse);
  });

  test('bell hidden when matching saved search has alerts disabled', () {
    alerts.emit(
      BrowseCatalogFilterAlertsState(
        phase: BrowseCatalogFilterAlertsLoadPhase.ready,
        savedSearches: [_bmwRow(alertsEnabled: false)],
        prefs: _prefs(global: true, filterAlerts: true),
      ),
    );
    expect(
      resolveSearchNavIndicatorData(
        applied: const ListingsState(make: 'BMW'),
        alerts: alerts,
      ).bell,
      isFalse,
    );
  });

  test('account rematch hides previous account bell after cubit reset', () {
    alerts.emit(
      BrowseCatalogFilterAlertsState(
        phase: BrowseCatalogFilterAlertsLoadPhase.ready,
        savedSearches: [_bmwRow(alertsEnabled: true)],
        prefs: _prefs(global: true, filterAlerts: true),
      ),
    );
    expect(
      resolveSearchNavIndicatorData(
        applied: const ListingsState(make: 'BMW'),
        alerts: alerts,
      ).active,
      isTrue,
    );

    alerts.emit(
      const BrowseCatalogFilterAlertsState(
        phase: BrowseCatalogFilterAlertsLoadPhase.ready,
      ),
    );
    expect(
      resolveSearchNavIndicatorData(
        applied: const ListingsState(make: 'BMW'),
        alerts: alerts,
      ).bell,
      isFalse,
    );
  });
}
