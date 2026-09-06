import 'package:flutter/material.dart';

import 'create_listing_compose_layout.dart';

/// Create-only closed picker. Empty state shows [label] as a placeholder.
class CreateListingPickerField extends StatelessWidget {
  const CreateListingPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.empty,
    required this.enabled,
    required this.onTap,
    this.errorText,
    this.fieldKey,
  });

  final String label;
  final String value;
  final bool empty;
  final bool enabled;
  final VoidCallback? onTap;
  final String? errorText;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shown = empty ? label : value;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final visualState = resolveCreateListingFieldVisualState(
      enabled: enabled,
      hasValue: !empty,
      error: hasError,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: fieldKey,
              borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
              onTap: enabled ? onTap : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                decoration: createListingSoftSurfaceDecoration(
                  theme,
                  visualState: visualState,
                  hasValue: !empty,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kCreateListingFieldMinHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      kCreateListingFieldHPad,
                      14,
                      14,
                      14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            shown,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.25,
                              fontWeight: FontWeight.w400,
                              color: empty
                                  ? createListingPlaceholderColor(theme)
                                  : createListingValueColor(
                                      theme,
                                      enabled: enabled,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 22,
                          color: createListingPickerChevronColor(
                            theme,
                            enabled: enabled,
                            empty: empty,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
