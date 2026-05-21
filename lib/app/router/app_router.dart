import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/l10n/app_localizations_x.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/create_listing/presentation/pages/create_listing_page.dart';
import '../../features/edit_listing/presentation/pages/edit_listing_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/filter_alerts/presentation/pages/filter_alert_settings_page.dart';
import '../../features/legal/presentation/pages/legal_page.dart';
import '../../features/listings/presentation/pages/listing_details_page.dart';
import '../../features/listings/domain/entities/listing_discovery_criteria.dart';
import '../../features/listings/presentation/pages/listings_page.dart';
import '../../features/menu/presentation/pages/menu_page.dart';
import '../../features/messaging/presentation/pages/conversation_thread_page.dart';
import '../../features/messaging/presentation/pages/messages_inbox_page.dart';
import '../../features/my_listings/presentation/pages/my_listings_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/sellers/presentation/pages/seller_profile_page.dart';

class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const listings = '/';
  static const listingDetails = '/listings/:id';
  static const editListing = '/listings/:id/edit';
  static const createListing = '/create-listing';
  static const myListings = '/my-listings';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const menu = '/menu';
  static const legal = '/legal';
  static const messages = '/messages';
  static const notificationSettings = '/notification-settings';
  static const filterAlert = '/filter-alert';
  static const sellerProfile = '/sellers/:sellerId';

  static String listingDetailsPath(String id) => '/listings/$id';
  static String editListingPath(String id) => '/listings/$id/edit';

  static String messagesThreadPath(String conversationId) =>
      '/messages/$conversationId';

  static String sellerProfilePath(String sellerId) => '/sellers/$sellerId';
}

/// Typed payload passed via `GoRouter` `extra` when navigating to
/// [AppRoutes.listingDetails] from an in-app surface (feed, favorites,
/// my listings).
///
/// Enables the destination page to render the tapped listing's actual
/// cover image during `ListingDetailsCubit` loading, so the feed→details
/// Hero flight animates the real photo instead of the placeholder.
///
/// Always optional: deep-linked navigations (opened by URL or push
/// notification) arrive without `extra`, and the details page must keep
/// working — it falls back to the placeholder until the cubit resolves.
class ListingDetailsExtra {
  const ListingDetailsExtra({
    this.coverImageUrl,
    this.coverHeroFlightTopRadius,
  });

  /// Cover image URL already known by the caller. Null if the source
  /// listing has no cover photo, or if the route was opened via a deep
  /// link where the cover URL was not available.
  final String? coverImageUrl;

  /// Matches [ListingCard] cover top corner radius for Hero shuttle math.
  /// Null ⇒ default (regular card / deep links).
  final double? coverHeroFlightTopRadius;
}

/// Pass with [AppRoutes.listings] `extra` when opening feed with predefined
/// discovery (e.g. filter-alert preview).
///
/// [openFilterSheetOnEntry] auto-opens the catalog filter sheet after the
/// feed renders. Used by the alert management screen so "Edit in catalog"
/// drops the user directly into the catalog filter UX with the saved
/// criteria seeded.
class ListingsFeedLaunch {
  const ListingsFeedLaunch({
    required this.snapshot,
    this.openFilterSheetOnEntry = false,
  });

  final ListingDiscoveryCriteria snapshot;
  final bool openFilterSheetOnEntry;
}

class AppRouter {
  AppRouter._();

  static GoRouter build() {
    return GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInPage()),
        GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpPage()),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (_, _) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, state) {
            final extra = state.extra;
            final launch = extra is ListingsFeedLaunch ? extra : null;
            return ListingsPage(feedLaunch: launch);
          },
        ),
        GoRoute(
          path: AppRoutes.sellerProfile,
          builder: (_, state) =>
              SellerProfilePage(sellerId: state.pathParameters['sellerId']!),
        ),
        GoRoute(
          path: AppRoutes.listingDetails,
          builder: (_, state) {
            // Tolerate any `extra` payload — deep links arrive with
            // none, and tests may push unrelated objects. We only
            // consume the typed payload and ignore the rest.
            final extra = state.extra;
            final initialCoverImageUrl = extra is ListingDetailsExtra
                ? extra.coverImageUrl
                : null;
            final coverHeroFlightTopRadius = extra is ListingDetailsExtra
                ? extra.coverHeroFlightTopRadius
                : null;
            return ListingDetailsPage(
              id: state.pathParameters['id']!,
              reportEmail: Env.reportEmail,
              initialCoverImageUrl: initialCoverImageUrl,
              coverHeroFlightTopRadius: coverHeroFlightTopRadius,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.editListing,
          builder: (_, state) =>
              EditListingPage(listingId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.createListing,
          builder: (_, _) => const CreateListingPage(),
        ),
        GoRoute(
          path: AppRoutes.myListings,
          builder: (_, _) => const MyListingsPage(),
        ),
        GoRoute(
          path: AppRoutes.favorites,
          builder: (_, _) => const FavoritesPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.notificationSettings,
          builder: (_, _) => const NotificationSettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.filterAlert,
          builder: (_, _) => const FilterAlertSettingsPage(),
        ),
        GoRoute(path: AppRoutes.menu, builder: (_, _) => const MenuPage()),
        GoRoute(
          path: AppRoutes.messages,
          builder: (_, _) => const MessagesInboxPage(),
        ),
        GoRoute(
          path: '/messages/:conversationId',
          builder: (_, state) => ConversationThreadPage(
            conversationId: state.pathParameters['conversationId']!,
          ),
        ),
        GoRoute(path: AppRoutes.legal, builder: (_, _) => const LegalPage()),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(context.l10n.routeNotFound(state.uri.toString())),
        ),
      ),
    );
  }
}
