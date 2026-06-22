import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../models/legal_section_content.dart';
import '../utils/legal_sections_builder.dart';

/// Static Terms & Privacy surface for the Carzon MVP.
///
/// Editorial in-app policy layout: localized sections, no remote fetch.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _legalPageBackground(context),
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.listings),
        title: Text(l10n.legalTitle),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _legalCanvasGradient(context),
            stops: const [0, 0.42, 1],
          ),
        ),
        child: const _LegalBody(),
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody();

  static const double _sectionGap = 28;

  @override
  Widget build(BuildContext context) {
    final sections = buildLegalSections(context.l10n);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + bottomInset),
      children: [
        const _LegalDisclaimerCallout(),
        for (var i = 0; i < sections.length; i++) ...[
          SizedBox(height: i == 0 ? 24 : _sectionGap),
          _LegalSectionBlock(section: sections[i]),
        ],
      ],
    );
  }
}

class _LegalDisclaimerCallout extends StatelessWidget {
  const _LegalDisclaimerCallout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return DecoratedBox(
      key: const ValueKey<String>('legal_disclaimer_callout'),
      decoration: AppTheme.filterAlertManagementSurface(scheme, borderRadius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.legalDisclaimerLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: isDark ? 0.88 : 0.82),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.legalDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.86 : 0.88,
                ),
                height: 1.48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSectionBlock extends StatelessWidget {
  const _LegalSectionBlock({required this.section});

  final LegalSectionContent section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.90 : 0.88),
      height: 1.55,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.82 : 0.86),
      height: 1.48,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.08,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < section.paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(section.paragraphs[i], style: bodyStyle),
        ],
        if (section.bullets.isNotEmpty) ...[
          if (section.paragraphs.isNotEmpty) const SizedBox(height: 12),
          _LegalBulletList(items: section.bullets, style: bodyStyle),
        ],
        for (var i = 0; i < section.trailingParagraphs.length; i++) ...[
          const SizedBox(height: 12),
          Text(section.trailingParagraphs[i], style: metaStyle),
        ],
      ],
    );
  }
}

class _LegalBulletList extends StatelessWidget {
  const _LegalBulletList({required this.items, this.style});

  final List<String> items;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bulletColor = scheme.onSurfaceVariant.withValues(
      alpha: isDark ? 0.72 : 0.68,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9, right: 10),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: bulletColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: Text(item, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

Color _legalPageBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.050),
      scheme.surface,
    );
  }
  return Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.018),
    scheme.surface,
  );
}

List<Color> _legalCanvasGradient(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    return AppTheme.editorialDarkFilterCanvasGradient(scheme);
  }

  final top = Color.alphaBlend(
    scheme.surfaceTint.withValues(alpha: 0.008),
    scheme.surface,
  );
  final mid = Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.032),
    scheme.surfaceContainerLowest,
  );
  final bottom = Color.alphaBlend(
    scheme.onSurface.withValues(alpha: 0.024),
    Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.070),
      scheme.surfaceContainerLow,
    ),
  );
  return [top, mid, bottom];
}
