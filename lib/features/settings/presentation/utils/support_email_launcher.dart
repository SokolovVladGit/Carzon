import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

Future<bool> launchExternalUrl(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
