import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Shared auth screen shell: gradient canvas, transparent app bar, back nav.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.fallbackRoute,
    required this.body,
  });

  final String fallbackRoute;
  final Widget body;

  static const double horizontalPadding = 24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final canvasColors = light
        ? [
            Color.alphaBlend(
              scheme.surfaceContainerLow.withValues(alpha: 0.45),
              scheme.surface,
            ),
            scheme.surface,
          ]
        : AppTheme.editorialDarkFilterCanvasGradient(scheme);
    final canvasTop = canvasColors.first;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: canvasTop,
      appBar: AppBar(
        leading: AppBackButton(fallback: fallbackRoute),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        iconTheme: IconThemeData(
          color: scheme.onSurface.withValues(alpha: light ? 0.88 : 0.92),
        ),
        systemOverlayStyle: light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: canvasColors,
            stops: light ? const [0, 0.55] : const [0, 0.35, 1],
          ),
        ),
        child: body,
      ),
    );
  }
}

/// Centered, vertically balanced scroll body for auth screens.
class AuthPageBody extends StatelessWidget {
  const AuthPageBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: kToolbarHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: AuthPageScaffold.horizontalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Secondary auth action link matching sign-in secondary button styling.
class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.accent = false,
    this.muted = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool accent;
  final bool muted;

  static const EdgeInsets _compactLinkPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final accentColor = light
        ? scheme.primary
        : AppTheme.editorialAccentColor(scheme);

    Color foreground;
    TextStyle? textStyle;

    if (accent) {
      foreground = accentColor.withValues(alpha: light ? 0.9 : 0.96);
      textStyle = theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
      );
    } else if (muted) {
      foreground = scheme.onSurfaceVariant.withValues(
        alpha: light ? 0.62 : 0.68,
      );
      textStyle = theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02,
      );
    } else {
      foreground = scheme.onSurfaceVariant.withValues(
        alpha: light ? 0.82 : 0.88,
      );
      textStyle = theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      );
    }

    return TextButton(
      onPressed: loading ? null : onPressed,
      style: TextButton.styleFrom(
        padding: _compactLinkPadding,
        foregroundColor: foreground,
        textStyle: textStyle,
      ),
      child: Text(label),
    );
  }
}
