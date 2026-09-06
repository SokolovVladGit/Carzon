import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/whatsapp_contact_icon.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import 'create_listing_compose_layout.dart';
import 'create_listing_segmented_control.dart';

class PremiumListingCurrencyBar extends StatelessWidget {
  const PremiumListingCurrencyBar({
    super.key,
    required this.theme,
    required this.selected,
    required this.enabled,
    required this.eurLabel,
    required this.usdLabel,
    required this.onChanged,
  });

  final ThemeData theme;
  final ListingCurrency selected;
  final bool enabled;
  final String eurLabel;
  final String usdLabel;
  final ValueChanged<ListingCurrency> onChanged;

  @override
  Widget build(BuildContext context) {
    return CreateListingSegmentedControl<ListingCurrency>(
      value: selected,
      enabled: enabled,
      onChanged: onChanged,
      options: [
        CreateListingSegmentOption(value: ListingCurrency.eur, label: eurLabel),
        CreateListingSegmentOption(value: ListingCurrency.usd, label: usdLabel),
      ],
    );
  }
}

class PremiumWhatsAppToggleRow extends StatelessWidget {
  const PremiumWhatsAppToggleRow({
    super.key,
    required this.theme,
    required this.l10n,
    required this.value,
    required this.submitting,
    required this.onChanged,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool value;
  final bool submitting;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final enabled = !submitting;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
        onTap: enabled ? () => onChanged(!value) : null,
        child: Ink(
          decoration: createListingInsetDecoration(
            theme,
            enabled: enabled,
            hasValue: value,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(
                      color: createListingContactIconColor(theme),
                      size: kCreateListingContactIconSize,
                    ),
                    child: const WhatsappContactIcon(
                      size: kCreateListingContactIconSize,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.createListingWhatsAppTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            color: cs.onSurface.withValues(alpha: 0.90),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.createListingWhatsAppSubtitle,
                          maxLines: 2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.25,
                            color: createListingPlaceholderColor(theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: value,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: enabled ? onChanged : null,
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

class PremiumPublishActionButton extends StatelessWidget {
  const PremiumPublishActionButton({
    super.key,
    required this.theme,
    required this.l10n,
    required this.submitting,
    required this.onPressed,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final canTap = !submitting;
    final light = theme.brightness == Brightness.light;
    final baseFill = light ? cs.onSurface : cs.primary;
    final fill = submitting
        ? Color.alphaBlend(cs.surface.withValues(alpha: 0.22), baseFill)
        : baseFill;
    final onFill = light ? cs.surface : cs.onPrimary;

    return DecoratedBox(
      decoration: createListingRaisedDecoration(
        theme,
        fill: fill,
        prominent: !submitting,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
        child: InkWell(
          onTap: canTap ? onPressed : null,
          borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
          splashColor: onFill.withValues(alpha: 0.08),
          highlightColor: onFill.withValues(alpha: 0.04),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kCreateListingFieldMinHeight,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: Center(
                child: submitting
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: onFill.withValues(alpha: 0.82),
                        ),
                      )
                    : Text(
                        l10n.publishListing,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.16,
                          color: onFill,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
