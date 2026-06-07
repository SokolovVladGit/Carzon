import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Editorial auth header: eyebrow chip, title, and supporting line.
class AuthEditorialHeader extends StatelessWidget {
  const AuthEditorialHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final accent = light
        ? scheme.primary
        : AppTheme.editorialAccentColor(scheme);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const ValueKey('auth_editorial_eyebrow'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: light
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
                : Color.alphaBlend(
                    accent.withValues(alpha: 0.1),
                    scheme.surfaceContainerHigh,
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: light
                  ? scheme.outlineVariant.withValues(alpha: 0.28)
                  : scheme.outline.withValues(alpha: 0.26),
            ),
          ),
          child: Text(
            eyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: light
                  ? scheme.onSurface.withValues(alpha: 0.52)
                  : accent.withValues(alpha: 0.78),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          key: const ValueKey('auth_editorial_title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            height: 1.12,
            color: scheme.onSurface.withValues(alpha: 0.96),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          key: const ValueKey('auth_editorial_subtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: scheme.onSurfaceVariant.withValues(
              alpha: light ? 0.82 : 0.88,
            ),
          ),
        ),
      ],
    );
  }
}

/// Auth form field and surface styling shared by sign-in (and future auth screens).
class AuthFormStyles {
  AuthFormStyles._();

  static const double fieldRadius = 12;
  static const double sectionRadius = 18;

  static InputDecoration fieldDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final accent = light
        ? scheme.primary
        : AppTheme.editorialAccentColor(scheme);

    final fillColor = light
        ? Color.alphaBlend(
            scheme.surfaceContainerHighest.withValues(alpha: 0.26),
            scheme.surface,
          )
        : Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.035),
            scheme.surfaceContainerHigh,
          );

    final restingBorder = scheme.outlineVariant.withValues(
      alpha: light ? 0.16 : 0.2,
    );
    final focusedBorder = accent.withValues(alpha: light ? 0.58 : 0.68);

    OutlineInputBorder shapedBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: light ? 0.76 : 0.82),
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: shapedBorder(restingBorder),
      enabledBorder: shapedBorder(restingBorder),
      focusedBorder: shapedBorder(focusedBorder, width: 1.2),
      errorBorder: shapedBorder(scheme.error),
      focusedErrorBorder: shapedBorder(scheme.error, width: 1.2),
    );
  }

  static BoxDecoration formSectionDecoration(ColorScheme scheme) {
    final light = scheme.brightness == Brightness.light;
    if (!light) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(sectionRadius),
        color: Color.alphaBlend(
          scheme.onSurface.withValues(alpha: 0.03),
          scheme.surfaceContainerHigh,
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
        ],
      );
    }

    return BoxDecoration(
      color: Color.alphaBlend(
        scheme.surfaceContainerHighest.withValues(alpha: 0.18),
        scheme.surface,
      ),
      borderRadius: BorderRadius.circular(sectionRadius),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.03),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final accent = light
        ? scheme.primary
        : AppTheme.editorialAccentColor(scheme);

    return FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
      ),
      backgroundColor: accent,
      foregroundColor: scheme.onPrimary,
    );
  }
}

/// Soft grouped surface for auth form fields and primary CTA.
class AuthFormSection extends StatelessWidget {
  const AuthFormSection({super.key, required this.child});

  final Widget child;

  static const double formMaxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: formMaxWidth),
      child: DecoratedBox(
        decoration: AuthFormStyles.formSectionDecoration(scheme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
          child: child,
        ),
      ),
    );
  }
}
