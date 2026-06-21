import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';

/// Non-tappable support header at the top of a support conversation thread.
class ThreadSupportContextCard extends StatelessWidget {
  const ThreadSupportContextCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final accent = AppTheme.editorialAccentColor(cs);

    final decoration = light
        ? BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          )
        : AppTheme.editorialDarkSectionCard(cs, borderRadius: 16)!.copyWith(
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: decoration,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: accent.withValues(alpha: light ? 0.85 : 0.9),
                  child: const SizedBox(width: 3),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: light ? 0.18 : 0.26),
                                accent.withValues(alpha: light ? 0.08 : 0.12),
                              ],
                            ),
                          ),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.support_agent_rounded,
                              size: 22,
                              color: accent.withValues(alpha: light ? 0.95 : 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.supportConversationTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.22,
                                  letterSpacing: -0.2,
                                  color: cs.onSurface.withValues(
                                    alpha: light ? 1 : 0.96,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.contactSupportSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: light ? 0.82 : 0.78,
                                  ),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
