import 'package:share_plus/share_plus.dart';

/// Launcher seam for the listing-details native share action.
///
/// Mirrors [ListingDetailsUriLauncher] so widget tests can intercept share
/// without a global abstraction.
typedef ListingShareLauncher = Future<void> Function(String text);

/// Thrown when the platform share sheet is unavailable.
class ListingShareUnavailableException implements Exception {
  const ListingShareUnavailableException();
}

/// Default [ListingShareLauncher]: opens the native share sheet.
///
/// User dismissal is not treated as failure. Only unavailable platforms and
/// thrown errors should surface an error snackbar to the user.
Future<void> launchListingShare(String text) async {
  final result = await Share.share(text);
  if (result.status == ShareResultStatus.unavailable) {
    throw const ListingShareUnavailableException();
  }
}
