import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/theme/app_theme.dart';
import 'auth_editorial_header.dart';

/// Provider buttons matching CARZON auth surfaces. No Material defaults.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.googleLabel,
    required this.appleLabel,
    required this.separatorLabel,
    required this.showGoogle,
    required this.showApple,
    required this.loading,
    required this.onGooglePressed,
    required this.onApplePressed,
  });

  final String googleLabel;
  final String appleLabel;
  final String separatorLabel;
  final bool showGoogle;
  final bool showApple;
  final bool loading;
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;

  bool get hasAny => showGoogle || showApple;

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AuthFormSection.formMaxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showGoogle)
            _SocialProviderButton(
              buttonKey: const ValueKey<String>('sign_in_google_button'),
              label: googleLabel,
              loading: loading,
              onPressed: onGooglePressed,
              leading: const _GoogleMark(),
              filled: false,
            ),
          if (showGoogle && showApple) const SizedBox(height: 10),
          if (showApple)
            _SocialProviderButton(
              buttonKey: const ValueKey<String>('sign_in_apple_button'),
              label: appleLabel,
              loading: loading,
              onPressed: onApplePressed,
              leading: const _AppleMark(),
              filled: true,
            ),
          const SizedBox(height: 22),
          _SocialSeparator(label: separatorLabel),
        ],
      ),
    );
  }
}

class _SocialSeparator extends StatelessWidget {
  const _SocialSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.62);
    return KeyedSubtree(
      key: const ValueKey<String>('sign_in_social_separator'),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}

class _SocialProviderButton extends StatelessWidget {
  const _SocialProviderButton({
    required this.buttonKey,
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.leading,
    required this.filled,
  });

  final Key buttonKey;
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final Widget leading;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AuthFormStyles.fieldRadius),
    );

    final child = loading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 10),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    if (filled) {
      final background = light ? const Color(0xFF111111) : scheme.onSurface;
      final foreground = light ? Colors.white : scheme.surface;
      return FilledButton(
        key: buttonKey,
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: shape,
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.55),
          disabledForegroundColor: foreground.withValues(alpha: 0.7),
        ),
        child: child,
      );
    }

    final accent = light
        ? scheme.primary
        : AppTheme.editorialAccentColor(scheme);
    return OutlinedButton(
      key: buttonKey,
      onPressed: loading ? null : onPressed,
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: shape,
            foregroundColor: scheme.onSurface,
            side: BorderSide(
              color: scheme.outlineVariant.withValues(
                alpha: light ? 0.42 : 0.5,
              ),
            ),
            backgroundColor: light
                ? scheme.surface
                : Color.alphaBlend(
                    scheme.onSurface.withValues(alpha: 0.04),
                    scheme.surfaceContainerHigh,
                  ),
          ).copyWith(
            overlayColor: WidgetStatePropertyAll(
              accent.withValues(alpha: 0.06),
            ),
          ),
      child: child,
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 16,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: 16,
      height: 18,
      child: CustomPaint(
        painter: AppleLogoPainter(
          color: light ? Colors.white : Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
