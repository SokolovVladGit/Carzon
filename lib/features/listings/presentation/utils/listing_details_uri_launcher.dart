import 'package:url_launcher/url_launcher.dart';

/// Launcher seam for listing-details external URIs (e.g. the "Report
/// listing" mailto).
///
/// Mirrors the `EditListingImagePicker` typedef on the edit-listing page so
/// widget tests can intercept `launchUrl` without owning a global
/// abstraction.
typedef ListingDetailsUriLauncher = Future<bool> Function(Uri uri);

/// Default [ListingDetailsUriLauncher]: opens [uri] in an external app.
Future<bool> launchExternalUri(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
