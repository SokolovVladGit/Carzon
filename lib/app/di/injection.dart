import 'package:get_it/get_it.dart';

import '../../core/services/auth_deep_link_service.dart';
import '../../core/services/supabase_service.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/compare/di/compare_injection.dart';
import '../../features/create_listing/di/create_listing_injection.dart';
import '../../features/edit_listing/di/edit_listing_injection.dart';
import '../../features/favorites/di/favorites_injection.dart';
import '../../features/filter_alerts/di/filter_alerts_injection.dart';
import '../../features/legal/di/legal_injection.dart';
import '../../features/listings/di/listings_injection.dart';
import '../../features/messaging/di/messaging_injection.dart';
import '../../features/my_listings/di/my_listings_injection.dart';
import '../../features/notifications/di/notifications_injection.dart';
import '../../features/profile/di/profile_injection.dart';
import '../../features/sellers/di/sellers_injection.dart';

/// Single global service locator used across the app.
///
/// Features must NOT create their own [GetIt] instances.
final GetIt sl = GetIt.instance;

/// App-level DI bootstrap. Called from `bootstrap.dart` after Supabase init.
///
/// Each feature owns its own registration in `features/<name>/di/<name>_injection.dart`.
/// This file only wires them together.
Future<void> configureDependencies(SupabaseService supabaseService) async {
  // Core / shared singletons
  sl.registerSingleton<SupabaseService>(supabaseService);
  sl.registerLazySingleton<AuthDeepLinkService>(
    () => AuthDeepLinkService.forSupabase(sl<SupabaseService>()),
  );

  // Feature registrations (order matters only if a feature depends on another).
  // Notifications before auth so `SignOut` pre-hooks can resolve push services.
  registerNotificationsFeature(sl);
  registerAuthFeature(sl);
  registerListingsFeature(sl);
  registerSellersFeature(sl);
  registerMessagingFeature(sl);
  registerProfileFeature(sl);
  registerFilterAlertsFeature(sl);
  registerFavoritesFeature(sl);
  registerCompareFeature(sl);
  registerCreateListingFeature(sl);
  registerMyListingsFeature(sl);
  registerEditListingFeature(sl);
  registerLegalFeature(sl);
}
