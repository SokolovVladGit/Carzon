import 'package:get_it/get_it.dart';

import '../../core/services/supabase_service.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/chat/di/chat_injection.dart';
import '../../features/create_listing/di/create_listing_injection.dart';
import '../../features/favorites/di/favorites_injection.dart';
import '../../features/listings/di/listings_injection.dart';
import '../../features/my_listings/di/my_listings_injection.dart';
import '../../features/profile/di/profile_injection.dart';

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

  // Feature registrations (order matters only if a feature depends on another).
  registerAuthFeature(sl);
  registerListingsFeature(sl);
  registerProfileFeature(sl);
  registerFavoritesFeature(sl);
  registerChatFeature(sl);
  registerCreateListingFeature(sl);
  registerMyListingsFeature(sl);
}
