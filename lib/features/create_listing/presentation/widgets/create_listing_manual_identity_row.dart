import 'package:flutter/material.dart';

import 'create_listing_compose_layout.dart';

/// Compact entry into manual make / model / year. Create Listing only.
class CreateListingManualIdentityRow extends StatelessWidget {
  const CreateListingManualIdentityRow({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.expanded = false,
  });

  static const Key actionKey = ValueKey('create_listing_enter_manually');

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final light = theme.brightness == Brightness.light;
    return Semantics(
      key: actionKey,
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: light
                    ? const Color(0xFFE6D9CC)
                    : cs.onSurface.withValues(alpha: 0.20),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      kCreateListingIconEdit,
                      size: kCreateListingEditIconSize,
                      color: createListingEditIconColor(
                        theme,
                        enabled: enabled,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                          color: enabled
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? kCreateListingIconChevronUp
                          : kCreateListingIconChevronDown,
                      size: kCreateListingChevronSize,
                      color: createListingChevronColor(theme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
