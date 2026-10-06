import 'package:flutter/material.dart';

import 'create_listing_compose_layout.dart';

/// Warm ivory card for a seller-facing group. Optional icon, title, helper.
class CreateListingQuietSurface extends StatelessWidget {
  const CreateListingQuietSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
    this.title,
    this.helper,
    this.icon,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? title;
  final String? helper;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final titleText = title?.trim();
    final helperText = helper?.trim();
    final hasHeader =
        icon != null ||
        (titleText != null && titleText.isNotEmpty) ||
        (helperText != null && helperText.isNotEmpty);
    final ink = light
        ? const Color(0xFF3F3832)
        : theme.colorScheme.onSurface;
    final muted = ink.withValues(alpha: light ? 0.58 : 0.68);

    return DecoratedBox(
      decoration: createListingSectionSurfaceDecoration(theme),
      child: Padding(
        padding: padding,
        child: hasHeader
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            icon,
                            size: 18,
                            color: light
                                ? const Color(0xFF7A6A58)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (titleText != null && titleText.isNotEmpty)
                              Text(
                                titleText,
                                style: createListingQuietTitleStyle(theme)
                                    ?.copyWith(color: ink),
                              ),
                            if (helperText != null &&
                                helperText.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                helperText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                  height: 1.3,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              )
            : child,
      ),
    );
  }
}

TextStyle? createListingQuietTitleStyle(ThemeData theme) {
  return theme.textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: -0.2,
    height: 1.15,
  );
}
