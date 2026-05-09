import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations_x.dart';
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

    final useDefault = view.useDefaultLayout;
    final headline = useDefault
        ? l10n.filtersSummaryDefaultTitle
        : (view.activeLine ?? '');

    final headlineStyle =
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          height: 1.3,
          color: scheme.onSurface.withValues(alpha: 0.93),
        ) ??
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          height: 1.3,
          color: scheme.onSurface.withValues(alpha: 0.93),
        );

    final base = scheme.surface;
    final sheetLift = Color.alphaBlend(
      scheme.surfaceContainerHigh.withValues(alpha: 0.14),
      Color.alphaBlend(
        scheme.surfaceContainerHighest.withValues(alpha: 0.12),
        base,
      ),
    );
    final sheetDepth = Color.alphaBlend(
      scheme.surfaceContainerHighest.withValues(alpha: 0.08),
      base,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                scheme.onSurface.withValues(alpha: 0.03),
                sheetLift,
              ),
              sheetDepth,
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
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Icon(
                  CarzonIcons.filter,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.36),
                ),
              ),
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
                    color: scheme.onSurface.withValues(alpha: 0.5),
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
