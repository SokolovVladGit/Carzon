import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Visual rhythm for create-listing section cards (editorial hierarchy).
enum CreateListingSectionTone { hero, identity, placement, metrics, finale }

/// Scroll canvas behind the compose form — soft ivory/graphite, not flat white.
Color createListingCanvasColor(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return Color.alphaBlend(
    cs.outlineVariant.withValues(alpha: light ? 0.022 : 0.05),
    cs.surface,
  );
}

/// Shared field chrome for the create-listing compose flow.
InputDecoration createListingFieldDecoration(
  ThemeData theme, {
  String? labelText,
  String? hintText,
  String? helperText,
}) {
  final cs = theme.colorScheme;
  final br = theme.brightness;
  final radius = BorderRadius.circular(14);
  final fillBase = br == Brightness.light
      ? cs.surface
      : cs.surfaceContainerLowest;
  final subtleFill = Color.alphaBlend(
    cs.outlineVariant.withValues(alpha: br == Brightness.light ? 0.04 : 0.08),
    fillBase,
  );
  final focusBorderColor = cs.onSurface.withValues(
    alpha: br == Brightness.light ? 0.28 : 0.36,
  );
  final quietVariant = cs.onSurfaceVariant.withValues(
    alpha: br == Brightness.light ? 0.72 : 0.78,
  );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: 4,
    floatingLabelBehavior: labelText != null
        ? FloatingLabelBehavior.auto
        : FloatingLabelBehavior.never,
    labelStyle: TextStyle(
      color: quietVariant,
      fontWeight: FontWeight.w500,
      fontSize: 13.5,
      letterSpacing: 0.02,
    ),
    hintStyle: TextStyle(
      color: quietVariant.withValues(alpha: 0.92),
      fontWeight: FontWeight.w400,
    ),
    helperStyle: TextStyle(
      color: quietVariant.withValues(alpha: 0.78),
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.42,
    ),
    border: OutlineInputBorder(borderRadius: radius),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: cs.outlineVariant.withValues(
          alpha: br == Brightness.light ? 0.30 : 0.34,
        ),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: focusBorderColor, width: 1.08),
    ),
    errorBorder: OutlineInputBorder(borderRadius: radius),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: cs.error, width: 1.12),
    ),
    filled: true,
    fillColor: subtleFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

/// Premium product moment at the top of the compose flow.
class CreateListingComposeHero extends StatelessWidget {
  const CreateListingComposeHero({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final quiet = cs.onSurfaceVariant.withValues(alpha: light ? 0.62 : 0.68);

    final topFill = Color.alphaBlend(
      cs.outlineVariant.withValues(alpha: light ? 0.04 : 0.08),
      cs.surfaceContainerLowest,
    );
    final bottomFill = Color.alphaBlend(
      cs.outlineVariant.withValues(alpha: light ? 0.02 : 0.05),
      cs.surface,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: light ? 0.34 : 0.38),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topFill, bottomFill],
        ),
        boxShadow: light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.createListingComposeEyebrow.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                fontSize: 10.5,
                color: quiet,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.createListingComposeHeadline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.52,
                height: 1.08,
                fontSize: 26,
                color: cs.onSurface.withValues(alpha: 0.97),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.createListingComposeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: quiet,
                height: 1.44,
                fontWeight: FontWeight.w400,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: light ? 0.28 : 0.32),
            ),
          ],
        ),
      ),
    );
  }
}

/// @deprecated Use [CreateListingComposeHero]. Kept for imports/tests compatibility.
typedef CreateListingComposeIntro = CreateListingComposeHero;

/// Secondary copy under a field group — guidance, not utility noise.
class CreateListingHelperText extends StatelessWidget {
  const CreateListingHelperText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(left: 1, bottom: 2),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: light ? 0.50 : 0.56),
          height: 1.4,
          fontWeight: FontWeight.w400,
          fontSize: 11.5,
          letterSpacing: 0.01,
        ),
      ),
    );
  }
}

/// Curated step shell for the create-listing form.
class CreateListingPremiumSection extends StatelessWidget {
  const CreateListingPremiumSection({
    super.key,
    required this.stepIndex,
    required this.title,
    this.subtitle,
    this.kicker,
    required this.child,
    this.tone = CreateListingSectionTone.identity,
  });

  /// 1-based step index shown as «01», «02», …
  final int stepIndex;
  final String? kicker;
  final String title;
  final String? subtitle;
  final Widget child;
  final CreateListingSectionTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final quietSubtitle = cs.onSurfaceVariant.withValues(
      alpha: light ? 0.50 : 0.56,
    );

    final radius = switch (tone) {
      CreateListingSectionTone.hero => 24.0,
      CreateListingSectionTone.finale => 22.0,
      _ => 20.0,
    };

    final padding = switch (tone) {
      CreateListingSectionTone.hero => const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        24,
      ),
      CreateListingSectionTone.finale => const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        26,
      ),
      _ => const EdgeInsets.fromLTRB(20, 20, 20, 22),
    };

    final borderColor = cs.outlineVariant.withValues(
      alpha: switch (tone) {
        CreateListingSectionTone.hero => light ? 0.36 : 0.40,
        CreateListingSectionTone.finale => light ? 0.32 : 0.36,
        _ => light ? 0.28 : 0.32,
      },
    );

    final fillTop = Color.alphaBlend(
      cs.outlineVariant.withValues(
        alpha: light
            ? (tone == CreateListingSectionTone.hero ? 0.038 : 0.028)
            : 0.07,
      ),
      tone == CreateListingSectionTone.hero
          ? cs.surfaceContainerLowest
          : cs.surface,
    );
    final fillBottom = Color.alphaBlend(
      cs.outlineVariant.withValues(alpha: light ? 0.012 : 0.03),
      cs.surfaceContainerLowest,
    );

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.28,
      height: 1.16,
      fontSize: tone == CreateListingSectionTone.hero ? 20 : 18,
      color: cs.onSurface.withValues(alpha: 0.96),
    );

    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: quietSubtitle,
      height: 1.4,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      letterSpacing: 0.01,
    );

    final afterHeaderGap = switch (tone) {
      CreateListingSectionTone.hero => 24.0,
      CreateListingSectionTone.finale => 20.0,
      _ => 18.0,
    };

    final stepLabel = stepIndex.clamp(1, 99).toString().padLeft(2, '0');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillTop, fillBottom],
        ),
        boxShadow: light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: tone == CreateListingSectionTone.hero ? 0.045 : 0.03,
                  ),
                  blurRadius: tone == CreateListingSectionTone.hero ? 24 : 16,
                  offset: Offset(
                    0,
                    tone == CreateListingSectionTone.hero ? 8 : 5,
                  ),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kicker != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.32),
                    ),
                    color: Color.alphaBlend(
                      cs.onSurface.withValues(alpha: light ? 0.04 : 0.08),
                      cs.surface,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      kicker!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.35,
                        fontSize: 11,
                        color: quietSubtitle.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CreateListingStepBadge(label: stepLabel, theme: theme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(subtitle!, style: subtitleStyle),
                      ],
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 0,
                        endIndent: 0,
                        color: cs.outlineVariant.withValues(
                          alpha: light ? 0.16 : 0.22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: afterHeaderGap),
            child,
          ],
        ),
      ),
    );
  }
}

class _CreateListingStepBadge extends StatelessWidget {
  const _CreateListingStepBadge({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: light ? 0.34 : 0.38),
        ),
        color: Color.alphaBlend(
          cs.outlineVariant.withValues(alpha: light ? 0.04 : 0.08),
          cs.surface,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.45,
            fontSize: 12,
            color: cs.onSurfaceVariant.withValues(alpha: light ? 0.72 : 0.78),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Stable label above a field.
class CreateListingFieldLabel extends StatelessWidget {
  const CreateListingFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(left: 1, bottom: 1),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: cs.onSurface.withValues(alpha: light ? 0.72 : 0.78),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.03,
          fontSize: 13.5,
          height: 1.2,
        ),
      ),
    );
  }
}
