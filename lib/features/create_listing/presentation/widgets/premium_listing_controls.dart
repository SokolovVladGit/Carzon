import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing_currency.dart';

/// Capsule-style EUR / USD control replacing Material [SegmentedButton].
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
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final light = br == Brightness.light;
    final trackFill = Color.alphaBlend(
      cs.primary.withValues(alpha: light ? 0.052 : 0.095),
      cs.surface,
    );
    final trackBorder = cs.outlineVariant.withValues(
      alpha: light ? 0.30 : 0.34,
    );

    Widget segment(ListingCurrency currency, String label) {
      final on = selected == currency;
      final thumbFill = on
          ? Color.alphaBlend(
              cs.primary.withValues(alpha: light ? 0.145 : 0.24),
              cs.surface,
            )
          : Colors.transparent;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          splashColor: cs.onSurface.withValues(alpha: 0.038),
          highlightColor: cs.onSurface.withValues(alpha: 0.018),
          onTap: enabled && !on ? () => onChanged(currency) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: on
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          cs.primary.withValues(alpha: light ? 0.055 : 0.10),
                          thumbFill,
                        ),
                        thumbFill,
                      ],
                    )
                  : null,
              color: on ? null : thumbFill,
              border: on
                  ? Border.all(
                      color: cs.primary.withValues(alpha: light ? 0.34 : 0.44),
                      width: 1,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.08,
                color: cs.onSurface.withValues(alpha: on ? 1 : 0.70),
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: trackBorder),
          color: trackFill,
          boxShadow: light
              ? [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.038),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: segment(ListingCurrency.eur, eurLabel)),
              VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
                color: cs.outlineVariant.withValues(alpha: 0.34),
              ),
              Expanded(child: segment(ListingCurrency.usd, usdLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

/// WhatsApp availability toggle styled as a calm editorial row.
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
    final light = theme.brightness == Brightness.light;
    final enabled = !submitting;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: cs.onSurface.withValues(alpha: 0.038),
        highlightColor: cs.onSurface.withValues(alpha: 0.018),
        onTap: enabled ? () => onChanged(!value) : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value
                  ? cs.primary.withValues(alpha: light ? 0.28 : 0.40)
                  : cs.outlineVariant.withValues(alpha: light ? 0.24 : 0.32),
            ),
            color: Color.alphaBlend(
              (value ? cs.primary : cs.outlineVariant).withValues(
                alpha: value ? (light ? 0.060 : 0.10) : (light ? 0.020 : 0.040),
              ),
              cs.surface,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.whatsappToggle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: cs.onSurface.withValues(alpha: 0.90),
                    ),
                  ),
                ),
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
    );
  }
}

/// Full-width publish control — inverted editorial emphasis without loud chrome.
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
    final br = theme.brightness;
    final canTap = !submitting;
    final light = br == Brightness.light;

    final baseFill = Color.alphaBlend(
      cs.primary.withValues(alpha: light ? 0.62 : 0.50),
      light ? cs.onSurface : cs.surfaceContainerHigh,
    );
    final fill = submitting
        ? Color.alphaBlend(
            cs.surface.withValues(alpha: br == Brightness.light ? 0.22 : 0.14),
            baseFill,
          )
        : baseFill;
    final onFill = br == Brightness.light
        ? cs.surface
        : cs.surface.withValues(alpha: 0.97);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: fill,
        elevation: br == Brightness.light ? (submitting ? 1 : 3) : 0,
        shadowColor: Colors.black.withValues(
          alpha: br == Brightness.light ? (submitting ? 0.06 : 0.12) : 0,
        ),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canTap ? onPressed : null,
          splashColor: onFill.withValues(alpha: 0.09),
          highlightColor: onFill.withValues(alpha: 0.05),
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
                      letterSpacing: -0.18,
                      color: onFill,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
