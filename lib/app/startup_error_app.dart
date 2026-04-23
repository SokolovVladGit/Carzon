import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/error_view.dart';

/// Minimal MaterialApp shown when the app cannot finish bootstrap
/// (missing env, Supabase init failure, etc.).
///
/// Reuses [ErrorView] so it follows the same UI patterns as the rest of
/// the app. No router, no DI — must work with zero infrastructure.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    super.key,
    required this.title,
    required this.message,
    this.details = const <String>[],
  });

  final String title;
  final String message;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ErrorView(
          message: details.isEmpty
              ? message
              : '$message\n\n${details.join('\n')}',
        ),
      ),
    );
  }
}
