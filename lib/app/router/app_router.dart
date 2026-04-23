import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/create_listing/presentation/pages/create_listing_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/listings/presentation/pages/listing_details_page.dart';
import '../../features/listings/presentation/pages/listings_page.dart';
import '../../features/my_listings/presentation/pages/my_listings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in';
  static const listings = '/';
  static const listingDetails = '/listings/:id';
  static const createListing = '/create-listing';
  static const myListings = '/my-listings';
  static const favorites = '/favorites';
  static const chat = '/chat';
  static const profile = '/profile';

  static String listingDetailsPath(String id) => '/listings/$id';
}

class AppRouter {
  AppRouter._();

  static GoRouter build() {
    return GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => const SignInPage(),
        ),
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const ListingsPage(),
        ),
        GoRoute(
          path: AppRoutes.listingDetails,
          builder: (_, state) =>
              ListingDetailsPage(id: state.pathParameters['id']!),
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
          path: AppRoutes.chat,
          builder: (_, _) => const ChatPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
        ),
      ],
      errorBuilder: (_, state) => Scaffold(
        body: Center(child: Text('Route not found: ${state.uri}')),
      ),
    );
  }
}
