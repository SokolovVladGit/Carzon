import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Visual rhythm for create-listing section cards (editorial hierarchy).
enum CreateListingSectionTone {
  /// Dominant: photo composer block.
  hero,

  /// Vehicle identity (make, model, year, city).
  identity,

  /// Deal + market placement.
  placement,

  /// Price and mileage facts.
  metrics,

  /// Contacts and publish.
  finale,
}

/// In-body editorial intro for the create-listing compose flow.
class CreateListingComposeIntro extends StatelessWidget {
  const CreateListingComposeIntro({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 0, 1, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createListingComposeHeadline,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.55,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            l10n.createListingComposeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.88),
              height: 1.38,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium grouped block with editorial tone variants — not identical cards.
class CreateListingPremiumSection extends StatelessWidget {
  const CreateListingPremiumSection({
    super.key,
    required this.title,
    this.subtitle,
    this.kicker,
    required this.child,
    this.tone = CreateListingSectionTone.identity,
  });

  final String? kicker;
  final String title;
  final String? subtitle;
  final Widget child;
  final CreateListingSectionTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final radius = switch (tone) {
      CreateListingSectionTone.hero => 30.0,
      CreateListingSectionTone.finale => 24.0,
      CreateListingSectionTone.identity => 22.0,
      CreateListingSectionTone.placement => 18.0,
      CreateListingSectionTone.metrics => 18.0,
    };

    final padding = switch (tone) {
      CreateListingSectionTone.hero => const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        24,
      ),
      CreateListingSectionTone.finale => const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        28,
      ),
      CreateListingSectionTone.identity => const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        22,
      ),
      CreateListingSectionTone.placement => const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        20,
      ),
      CreateListingSectionTone.metrics => const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        20,
      ),
    };

    final borderColor = switch (tone) {
      CreateListingSectionTone.hero => cs.outlineVariant.withValues(
        alpha: theme.brightness == Brightness.light ? 0.38 : 0.42,
      ),
      CreateListingSectionTone.finale => cs.outlineVariant.withValues(
        alpha: theme.brightness == Brightness.light ? 0.36 : 0.40,
      ),
      CreateListingSectionTone.identity => cs.outlineVariant.withValues(
        alpha: 0.32,
      ),
      CreateListingSectionTone.placement => cs.outlineVariant.withValues(
        alpha: 0.28,
      ),
      CreateListingSectionTone.metrics => cs.outlineVariant.withValues(
        alpha: 0.26,
      ),
    };

    final fill = switch (tone) {
      CreateListingSectionTone.hero => Color.alphaBlend(
        cs.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.light ? 0.038 : 0.082,
        ),
        cs.surface,
      ),
      CreateListingSectionTone.identity => Color.alphaBlend(
        cs.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.light ? 0.035 : 0.08,
        ),
        cs.surfaceContainerLowest,
      ),
      CreateListingSectionTone.placement => Color.alphaBlend(
        cs.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.light ? 0.02 : 0.06,
        ),
        cs.surfaceContainerLowest,
      ),
      CreateListingSectionTone.metrics => Color.alphaBlend(
        cs.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.light ? 0.025 : 0.06,
        ),
        cs.surfaceContainerLowest,
      ),
      CreateListingSectionTone.finale => Color.alphaBlend(
        cs.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.light ? 0.034 : 0.078,
        ),
        cs.surface,
      ),
    };

    final titleStyle = switch (tone) {
      CreateListingSectionTone.hero => theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      CreateListingSectionTone.identity => theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) * 0.96,
      ),
      CreateListingSectionTone.placement =>
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.18,
        ),
      CreateListingSectionTone.metrics => theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: cs.onSurface.withValues(alpha: 0.92),
      ),
      CreateListingSectionTone.finale => theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.22,
      ),
    };

    final afterHeaderGap = switch (tone) {
      CreateListingSectionTone.hero => 22.0,
      CreateListingSectionTone.placement => 12.0,
      CreateListingSectionTone.metrics => 14.0,
      CreateListingSectionTone.finale => 16.0,
      _ => 16.0,
    };

    final light = theme.brightness == Brightness.light;

    return Card(
      elevation: light ? (tone == CreateListingSectionTone.hero ? 2 : 1) : 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: fill,
      shadowColor: Colors.black.withValues(alpha: light ? 0.055 : 0),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kicker != null) ...[
              Text(
                kicker!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.82),
                ),
              ),
              SizedBox(height: tone == CreateListingSectionTone.finale ? 7 : 5),
            ],
            Text(title, style: titleStyle),
            if (subtitle != null) ...[
              SizedBox(height: tone == CreateListingSectionTone.hero ? 7 : 5),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                  height: 1.4,
                  fontWeight: tone == CreateListingSectionTone.hero
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ],
            SizedBox(height: afterHeaderGap),
            child,
          ],
        ),
      ),
    );
  }
}

/// Stable label above a field (Material floating labels omitted where this is used).
class CreateListingFieldLabel extends StatelessWidget {
  const CreateListingFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 1),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.88),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.12,
        ),
      ),
    );
  }
}
