import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../utils/thread_attachment_source.dart';

/// Opens the chat attachment source picker (gallery or camera).
Future<ThreadAttachmentSource?> showThreadAttachmentSourceSheet(
  BuildContext context,
) {
  return showModalBottomSheet<ThreadAttachmentSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => const ThreadAttachmentSourceSheet(),
  );
}

class ThreadAttachmentSourceSheet extends StatelessWidget {
  const ThreadAttachmentSourceSheet({super.key});

  static const double _horizontalPadding = 16;
  static const double _rowSpacing = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _horizontalPadding,
          4,
          _horizontalPadding,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.messagingAttachmentSourceTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: cs.onSurface.withValues(alpha: isDark ? 0.96 : 0.92),
              ),
            ),
            const SizedBox(height: 14),
            _SourceActionRow(
              icon: CarzonIcons.photoLibrary,
              label: l10n.messagingAttachmentGallery,
              onTap: () =>
                  Navigator.pop(context, ThreadAttachmentSource.gallery),
            ),
            const SizedBox(height: _rowSpacing),
            _SourceActionRow(
              icon: CarzonIcons.addPhoto,
              label: l10n.messagingAttachmentCamera,
              onTap: () => Navigator.pop(context, ThreadAttachmentSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceActionRow extends StatelessWidget {
  const _SourceActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final decoration = isDark
        ? AppTheme.editorialDarkSectionCard(cs, borderRadius: 16)
        : BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.34),
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashFactory: InkRipple.splashFactory,
        child: Ink(
          decoration: decoration,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _SourceIconCapsule(
                    icon: icon,
                    scheme: cs,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.02,
                        color: cs.onSurface.withValues(alpha: isDark ? 0.94 : 0.9),
                      ),
                    ),
                  ),
                  Icon(
                    CarzonIcons.chevronRight,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.72 : 0.62,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceIconCapsule extends StatelessWidget {
  const _SourceIconCapsule({
    required this.icon,
    required this.scheme,
    required this.isDark,
  });

  final IconData icon;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.editorialAccentColor(scheme);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.16),
                scheme.surfaceContainerHighest,
              )
            : scheme.primaryContainer.withValues(alpha: 0.55),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 22,
          color: isDark
              ? accent.withValues(alpha: 0.96)
              : scheme.primary.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
