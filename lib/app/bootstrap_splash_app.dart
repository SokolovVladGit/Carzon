import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../shared/ui/animated_carzon_logo.dart';
import '../shared/ui/carzon_logo.dart';

/// Minimal Flutter shell shown while async bootstrap runs.
///
/// Replaced by [CarzonApp] once initialization completes. No router, DI, or
/// localization — only theme-aware branded loading presentation.
class BootstrapSplashApp extends StatelessWidget {
  const BootstrapSplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const BootstrapSplashView(),
    );
  }
}

/// Centered startup logo with reduced-motion fallback.
class BootstrapSplashView extends StatelessWidget {
  const BootstrapSplashView({super.key});

  static const double logoHeight = 52;
  static const double logoMaxWidth = 320;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);

    final logo = animationsEnabled
        ? const AnimatedCarzonLogo(
            key: Key('bootstrapSplashAnimatedLogo'),
            height: logoHeight,
            width: logoMaxWidth,
            repeat: false,
          )
        : const CarzonLogo(
            key: Key('bootstrapSplashStaticLogo'),
            height: logoHeight,
            width: logoMaxWidth,
          );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(child: logo),
      ),
    );
  }
}
