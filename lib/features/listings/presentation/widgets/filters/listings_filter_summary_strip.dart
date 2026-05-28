import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations_x.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/ui/carzon_icons.dart';
import 'listing_filter_summary_presenter.dart';

/// Premium contextual strip above filter sections (defaults + live draft line).
class ListingsFilterSummaryStrip extends StatelessWidget {
  const ListingsFilterSummaryStrip({super.key, required this.view});

  final ListingsFilterSummaryView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    final useDefault = view.useDefaultLayout;
    final headline = useDefault
        ? l10n.filtersSummaryDefaultTitle
        : (view.activeLine ?? '');

    final headlineStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
      height: 1.3,
      color: scheme.onSurface.withValues(alpha: light ? 0.93 : 0.98),
    );

    final decoration =
        AppTheme.editorialDarkHeroCard(scheme, borderRadius: 18) ??
        BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                scheme.onSurface.withValues(alpha: 0.03),
                Color.alphaBlend(
                  scheme.surfaceContainerHigh.withValues(alpha: 0.14),
                  Color.alphaBlend(
                    scheme.surfaceContainerHighest.withValues(alpha: 0.12),
                    scheme.surface,
                  ),
                ),
              ),
              Color.alphaBlend(
                scheme.surfaceContainerHighest.withValues(alpha: 0.08),
                scheme.surface,
              ),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.17),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        );

    final iconWidget = light
        ? Icon(
            CarzonIcons.filter,
            size: 18,
            color: scheme.onSurface.withValues(alpha: 0.36),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.20),
                    scheme.surfaceContainerHigh,
                  ),
                  scheme.surfaceContainerLow,
                ],
              ),
              border: Border.all(
                color: AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: 0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                CarzonIcons.filter,
                size: 18,
                color: AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: 0.95),
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.center, child: iconWidget),
              const SizedBox(height: 9),
              Text(
                headline,
                textAlign: TextAlign.center,
                maxLines: useDefault ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: headlineStyle,
              ),
              if (useDefault) ...[
                const SizedBox(height: 11),
                Text(
                  l10n.filtersSummaryDefaultHints,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: light ? 0.5 : 0.72,
                    ),
                    height: 1.5,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
