import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Visual rhythm for create-listing section cards (editorial hierarchy).
enum CreateListingSectionTone { hero, identity, placement, metrics, finale }

/// Scroll canvas behind the compose form — soft ivory/graphite, not flat white.
Color createListingCanvasColor(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  if (light) {
    return Color.alphaBlend(cs.primary.withValues(alpha: 0.018), cs.surface);
  }
  return Color.alphaBlend(
    cs.primary.withValues(alpha: 0.055),
    Color.alphaBlend(cs.outlineVariant.withValues(alpha: 0.08), cs.surface),
  );
}

/// Showroom canvas behind the composer. Kept local to avoid broad theme churn.
BoxDecoration createListingCanvasDecoration(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  if (light) {
    final top = Color.alphaBlend(
      cs.surfaceTint.withValues(alpha: 0.008),
      cs.surface,
    );
    final mid = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.030),
      cs.surfaceContainerLowest,
    );
    final bottom = Color.alphaBlend(
      cs.onSurface.withValues(alpha: 0.030),
      Color.alphaBlend(
        cs.primary.withValues(alpha: 0.090),
        cs.surfaceContainerLow,
      ),
    );
    return BoxDecoration(
      color: createListingCanvasColor(theme),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, mid, bottom],
        stops: const [0, 0.45, 1],
      ),
    );
  }

  final top = Color.alphaBlend(
    cs.primary.withValues(alpha: 0.075),
    cs.surfaceContainerLow,
  );
  final mid = Color.alphaBlend(cs.primary.withValues(alpha: 0.030), cs.surface);
  final bottom = Color.alphaBlend(
    cs.onSurface.withValues(alpha: 0.030),
    Color.alphaBlend(
      cs.primary.withValues(alpha: 0.088),
      cs.surfaceContainerLow,
    ),
  );
  return BoxDecoration(
    color: createListingCanvasColor(theme),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, mid, bottom],
      stops: const [0, 0.48, 1],
    ),
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
  final light = br == Brightness.light;
  final radius = BorderRadius.circular(18);
  final fillBase = light ? cs.surface : cs.surfaceContainerLow;
  final subtleFill = Color.alphaBlend(
    light
        ? cs.primary.withValues(alpha: 0.034)
        : cs.primary.withValues(alpha: 0.095),
    fillBase,
  );
  final focusBorderColor = light
      ? cs.primary.withValues(alpha: 0.46)
      : AppTheme.editorialDarkFieldFocusBorder(cs);
  final quietVariant = cs.onSurfaceVariant.withValues(
    alpha: light ? 0.68 : 0.88,
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
      fontWeight: FontWeight.w600,
      fontSize: 13.2,
      letterSpacing: 0.04,
    ),
    hintStyle: TextStyle(
      color: quietVariant.withValues(alpha: 0.92),
      fontWeight: FontWeight.w400,
    ),
    helperStyle: TextStyle(
      color: quietVariant.withValues(alpha: light ? 0.72 : 0.80),
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.42,
    ),
    border: OutlineInputBorder(borderRadius: radius),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: light
            ? cs.primary.withValues(alpha: 0.16)
            : cs.outline.withValues(alpha: 0.34),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: focusBorderColor,
        width: light ? 1.08 : 1.2,
      ),
    ),
    errorBorder: OutlineInputBorder(borderRadius: radius),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: cs.error, width: 1.12),
    ),
    filled: true,
    fillColor: subtleFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
    final quiet = cs.onSurfaceVariant.withValues(alpha: light ? 0.64 : 0.80);
    final eyebrowColor = light
        ? quiet
        : AppTheme.editorialAccentColor(cs).withValues(alpha: 0.88);

    final surface = light ? cs.surfaceContainerLowest : cs.surfaceContainerLow;
    final topFill = Color.alphaBlend(
      cs.primary.withValues(alpha: light ? 0.095 : 0.17),
      surface,
    );
    final midFill = Color.alphaBlend(
      cs.onSurface.withValues(alpha: light ? 0.010 : 0.030),
      surface,
    );
    final bottomFill = Color.alphaBlend(
      cs.primary.withValues(alpha: light ? 0.035 : 0.085),
      cs.surface,
    );

    final decoration =
        AppTheme.editorialDarkHeroCard(cs) ??
        BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: light
                ? cs.primary.withValues(alpha: 0.20)
                : cs.outline.withValues(alpha: 0.34),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [topFill, midFill, bottomFill],
            stops: const [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.085),
              blurRadius: 38,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.070),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        );

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: light
                        ? cs.primary.withValues(alpha: 0.32)
                        : AppTheme.editorialAccentColor(
                            cs,
                          ).withValues(alpha: 0.58),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l10n.createListingComposeEyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      fontSize: 10.5,
                      color: eyebrowColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.createListingComposeHeadline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.52,
                height: 1.08,
                fontSize: 26,
                color: cs.onSurface.withValues(alpha: light ? 0.97 : 0.98),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.createListingComposeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: quiet,
                height: 1.44,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            Divider(
              height: 1,
              thickness: 1,
              color: light
                  ? cs.primary.withValues(alpha: 0.14)
                  : Color.alphaBlend(
                      AppTheme.editorialAccentColor(cs).withValues(alpha: 0.22),
                      cs.outline.withValues(alpha: 0.28),
                    ),
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
          color: cs.onSurfaceVariant.withValues(alpha: light ? 0.56 : 0.74),
          height: 1.4,
          fontWeight: FontWeight.w400,
          fontSize: 11.8,
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
      alpha: light ? 0.50 : 0.74,
    );

    final radius = switch (tone) {
      CreateListingSectionTone.hero => 30.0,
      CreateListingSectionTone.finale => 28.0,
      _ => 26.0,
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
        CreateListingSectionTone.hero => light ? 0.34 : 0.44,
        CreateListingSectionTone.finale => light ? 0.32 : 0.40,
        _ => light ? 0.28 : 0.36,
      },
    );

    final fillTop = Color.alphaBlend(
      cs.primary.withValues(
        alpha: light
            ? (tone == CreateListingSectionTone.hero ? 0.090 : 0.066)
            : 0.13,
      ),
      tone == CreateListingSectionTone.hero
          ? cs.surfaceContainerLowest
          : cs.surface,
    );
    final fillMiddle = Color.alphaBlend(
      cs.onSurface.withValues(alpha: light ? 0.006 : 0.024),
      tone == CreateListingSectionTone.hero
          ? cs.surfaceContainerLowest
          : cs.surface,
    );
    final fillBottom = Color.alphaBlend(
      cs.primary.withValues(alpha: light ? 0.028 : 0.052),
      cs.surfaceContainerLowest,
    );

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.28,
      height: 1.16,
      fontSize: tone == CreateListingSectionTone.hero ? 20 : 18,
      color: cs.onSurface.withValues(alpha: light ? 0.96 : 0.98),
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

    final decoration =
        AppTheme.editorialDarkSectionCard(cs, borderRadius: radius) ??
        BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [fillTop, fillMiddle, fillBottom],
            stops: const [0, 0.50, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(
                alpha: tone == CreateListingSectionTone.hero ? 0.085 : 0.064,
              ),
              blurRadius: tone == CreateListingSectionTone.hero ? 36 : 30,
              offset: Offset(
                0,
                tone == CreateListingSectionTone.hero ? 14 : 11,
              ),
            ),
            BoxShadow(
              color: cs.primary.withValues(
                alpha: tone == CreateListingSectionTone.hero ? 0.060 : 0.038,
              ),
              blurRadius: tone == CreateListingSectionTone.hero ? 28 : 24,
              offset: const Offset(0, 6),
            ),
          ],
        );

    return DecoratedBox(
      decoration: decoration,
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
                      color: light
                          ? cs.outlineVariant.withValues(alpha: 0.32)
                          : AppTheme.editorialAccentColor(
                              cs,
                            ).withValues(alpha: 0.30),
                    ),
                    color: Color.alphaBlend(
                      (light ? cs.onSurface : cs.primary).withValues(
                        alpha: light ? 0.04 : 0.10,
                      ),
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
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color.alphaBlend(
                  cs.primary.withValues(alpha: light ? 0.030 : 0.065),
                  cs.surface.withValues(alpha: light ? 0.50 : 0.22),
                ),
                border: Border.all(
                  color: cs.primary.withValues(alpha: light ? 0.090 : 0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
                child: Row(
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
                          const SizedBox(height: 13),
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  light
                                      ? cs.primary.withValues(alpha: 0.18)
                                      : AppTheme.editorialAccentColor(
                                          cs,
                                        ).withValues(alpha: 0.26),
                                  cs.outlineVariant.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

    final decoration =
        AppTheme.editorialDarkStepBadge(cs) ??
        BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.30)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(cs.primary.withValues(alpha: 0.145), cs.surface),
              Color.alphaBlend(cs.primary.withValues(alpha: 0.048), cs.surface),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.050),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.45,
            fontSize: 12,
            color: light
                ? cs.primary.withValues(alpha: 0.82)
                : AppTheme.editorialAccentColor(cs).withValues(alpha: 0.92),
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
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: cs.primary.withValues(alpha: light ? 0.34 : 0.52),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: light ? 0.82 : 0.95),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.03,
                fontSize: 13.7,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
