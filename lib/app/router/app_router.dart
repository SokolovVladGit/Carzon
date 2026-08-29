import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations_x.dart';
import '../../features/compare/presentation/pages/compare_page.dart';
import '../../features/account/presentation/pages/delete_account_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/create_listing/presentation/pages/create_listing_page.dart';
import '../../features/edit_listing/presentation/pages/edit_listing_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/filter_alerts/presentation/pages/filter_alert_settings_page.dart';
import '../../features/fuel_prices/presentation/pages/fuel_prices_page.dart';
import '../../features/legal/presentation/pages/legal_page.dart';
import '../../features/legal/presentation/models/legal_document_content.dart';
import '../../features/listings/presentation/pages/listing_details_page.dart';
import '../../features/listings/domain/entities/listing_discovery_criteria.dart';
import '../../features/listings/presentation/pages/listings_page.dart';
import '../../features/menu/presentation/pages/menu_page.dart';
import '../../features/messaging/presentation/pages/blocked_users_page.dart';
import '../../features/messaging/presentation/pages/conversation_thread_page.dart';
import '../../features/messaging/presentation/pages/messages_inbox_page.dart';
import '../../features/my_listings/presentation/pages/my_listings_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/recent_searches/presentation/pages/recent_searches_page.dart';
import '../../features/recently_viewed/presentation/pages/recently_viewed_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/sellers/presentation/pages/seller_profile_page.dart';

class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const changePassword = '/change-password';
  static const listings = '/';
  static const listingDetails = '/listings/:id';
  static const editListing = '/listings/:id/edit';
  static const createListing = '/create-listing';
  static const myListings = '/my-listings';
  static const favorites = '/favorites';
  static const compare = '/compare';
  static const recentlyViewed = '/recently-viewed';
  static const recentSearches = '/recent-searches';
  static const profile = '/profile';
  static const settings = '/settings';
  static const deleteAccount = '/delete-account';
  static const menu = '/menu';
  static const legal = '/legal';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const fuelPrices = '/fuel-prices';
  static const messages = '/messages';
  static const notificationSettings = '/notification-settings';
  static const filterAlert = '/filter-alert';
  static const blockedUsers = '/blocked-users';
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
          path: AppRoutes.changePassword,
          builder: (_, _) => const ChangePasswordPage(),
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
          path: AppRoutes.compare,
          builder: (_, _) => const ComparePage(),
        ),
        GoRoute(
          path: AppRoutes.recentlyViewed,
          builder: (_, _) => const RecentlyViewedPage(),
        ),
        GoRoute(
          path: AppRoutes.recentSearches,
          builder: (_, _) => const RecentSearchesPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.deleteAccount,
          builder: (_, _) => const DeleteAccountPage(),
        ),
        GoRoute(
          path: AppRoutes.notificationSettings,
          builder: (_, _) => const NotificationSettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.filterAlert,
          builder: (_, _) => const FilterAlertSettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.blockedUsers,
          builder: (_, _) => const BlockedUsersPage(),
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
        GoRoute(
          path: AppRoutes.privacy,
          builder: (_, _) => const LegalPage(kind: LegalDocumentKind.privacy),
        ),
        GoRoute(
          path: AppRoutes.terms,
          builder: (_, _) => const LegalPage(kind: LegalDocumentKind.terms),
        ),
        GoRoute(
          path: AppRoutes.legal,
          builder: (_, _) => const LegalPage(kind: LegalDocumentKind.notices),
        ),
        GoRoute(
          path: AppRoutes.fuelPrices,
          builder: (_, _) => const FuelPricesPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(context.l10n.routeNotFound(state.uri.toString())),
        ),
      ),
    );
  }
}
