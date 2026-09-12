import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/brands/brand_logo_glyph.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_details_header_titles.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../../listings/presentation/widgets/listing_card.dart';
import '../models/listing_preview_data.dart';

/// Create-listing live preview. Looks like a regular marketplace card
/// but is not a [Listing] and has no marketplace actions.
class ListingPreviewCard extends StatelessWidget {
  const ListingPreviewCard({super.key, required this.data, required this.l10n});

  static const Key headingKey = ValueKey('create_listing_listing_preview');
  static const Key cardKey = ValueKey('create_listing_listing_preview_card');
  static const Key coverKey = ValueKey('create_listing_listing_preview_cover');
  static const Key coverPlaceholderKey = ValueKey(
    'create_listing_listing_preview_cover_placeholder',
  );
  static const Key priceKey = ValueKey('create_listing_listing_preview_price');
  static const Key identityKey = ValueKey(
    'create_listing_listing_preview_identity',
  );
  static const Key variantKey = ValueKey(
    'create_listing_listing_preview_variant',
  );
  static const Key metaKey = ValueKey('create_listing_listing_preview_meta');
  static const Key specsKey = ValueKey('create_listing_listing_preview_specs');
  static const Key typeBadgeKey = ValueKey(
    'create_listing_listing_preview_type_badge',
  );

  static const double _cardRadius = 20;
  @visibleForTesting
  static const double compactCoverHeight = 68;
  static const double _brandGlyphSize = 18;

  final ListingPreviewData data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity = listingDetailsVehicleIdentityLine(data.make, data.model);
    final identityLabel = identity.isEmpty
        ? l10n.createListingPreviewVehiclePlaceholder
        : identity;
    final priceIncomplete = data.priceAmount == null;
    final priceLabel = priceIncomplete
        ? l10n.createListingPreviewEnterPrice
        : formatListingPrice(data.priceAmount!, data.currency);
    final city = data.city;
    final showRegionInMeta =
        !data.hasCover &&
        city == null &&
        (data.year != null || data.mileageKm != null || identity.isNotEmpty);
    final metaLine = listingPreviewJoin([
      if (data.mileageKm != null) formatKm(l10n, data.mileageKm!),
      if (data.year != null) '${data.year}',
      if (city != null)
        city
      else if (showRegionInMeta)
        formatMarketRegion(l10n, data.marketRegion),
    ]);
    final specLine = listingPreviewJoin([
      if (data.fuelType != null) formatListingFuelType(l10n, data.fuelType!),
      if (data.transmissionType != null)
        formatListingTransmissionType(l10n, data.transmissionType!),
      if (data.drivetrain != null)
        formatListingDrivetrain(l10n, data.drivetrain!),
      if (data.engineDisplacementLiters != null)
        formatEngineDisplacementForDisplay(l10n, data.engineDisplacementLiters),
      if (data.bodyType != null) formatListingBodyType(l10n, data.bodyType!),
    ]);
    final variant = data.variant;

    final semantics = [
      l10n.createListingPreviewHeading,
      identityLabel,
      ?variant,
      priceLabel,
      if (metaLine.isNotEmpty) metaLine,
      if (specLine.isNotEmpty) specLine,
      data.hasCover
          ? l10n.createListingPreviewCoverLabel
          : l10n.createListingPreviewAddPhotoHint,
    ].join('. ');

    return Column(
      key: headingKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createListingPreviewHeading,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Semantics(
          container: true,
          label: semantics,
          child: ExcludeSemantics(
            child: _PreviewVisualCard(
              theme: theme,
              l10n: l10n,
              data: data,
              identityLabel: identityLabel,
              variant: variant,
              priceLabel: priceLabel,
              priceIncomplete: priceIncomplete,
              metaLine: metaLine,
              specLine: specLine,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewVisualCard extends StatelessWidget {
  const _PreviewVisualCard({
    required this.theme,
    required this.l10n,
    required this.data,
    required this.identityLabel,
    required this.variant,
    required this.priceLabel,
    required this.priceIncomplete,
    required this.metaLine,
    required this.specLine,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final ListingPreviewData data;
  final String identityLabel;
  final String? variant;
  final String priceLabel;
  final bool priceIncomplete;
  final String metaLine;
  final String specLine;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = ListingPreviewCard._cardRadius;
    final panelBg = isDark
        ? Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.04),
            scheme.surfaceContainerHigh,
          )
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDark
        ? scheme.outline.withValues(alpha: 0.32)
        : Colors.white.withValues(alpha: 0.55);

    return DecoratedBox(
      key: ListingPreviewCard.cardKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? scheme.shadow.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PreviewCover(
                  bytes: data.coverBytes,
                  compact: !data.hasCover,
                  hint: l10n.createListingPreviewAddPhotoHint,
                ),
                _PreviewInfoPanel(
                  theme: theme,
                  l10n: l10n,
                  data: data,
                  identityLabel: identityLabel,
                  variant: variant,
                  priceLabel: priceLabel,
                  priceIncomplete: priceIncomplete,
                  metaLine: metaLine,
                  specLine: specLine,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCover extends StatelessWidget {
  const _PreviewCover({required this.compact, required this.hint, this.bytes});

  final Uint8List? bytes;
  final bool compact;
  final String hint;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _PreviewCompactEmptyCover(hint: hint);
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _PreviewPhoto(bytes: bytes!),
    );
  }
}

class _PreviewPhoto extends StatelessWidget {
  const _PreviewPhoto({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      key: ListingPreviewCard.coverKey,
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) {
        final scheme = Theme.of(context).colorScheme;
        return ColoredBox(
          key: ListingPreviewCard.coverPlaceholderKey,
          color: scheme.surfaceContainerHigh,
          child: Center(
            child: Icon(
              Icons.directions_car_filled_outlined,
              size: 28,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
            ),
          ),
        );
      },
    );
  }
}

class _PreviewCompactEmptyCover extends StatelessWidget {
  const _PreviewCompactEmptyCover({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.72);
    return ColoredBox(
      key: ListingPreviewCard.coverPlaceholderKey,
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
      child: SizedBox(
        height: ListingPreviewCard.compactCoverHeight,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.add_a_photo_outlined, size: 22, color: muted),
              if (hint.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
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

class _PreviewInfoPanel extends StatelessWidget {
  const _PreviewInfoPanel({
    required this.theme,
    required this.l10n,
    required this.data,
    required this.identityLabel,
    required this.variant,
    required this.priceLabel,
    required this.priceIncomplete,
    required this.metaLine,
    required this.specLine,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final ListingPreviewData data;
  final String identityLabel;
  final String? variant;
  final String priceLabel;
  final bool priceIncomplete;
  final String metaLine;
  final String specLine;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final priceStyle = theme.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: priceIncomplete
          ? scheme.onSurface.withValues(alpha: isDark ? 0.46 : 0.40)
          : scheme.onSurface,
      letterSpacing: priceIncomplete ? -0.15 : -0.4,
      height: 1.1,
    );
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface.withValues(alpha: isDark ? 0.94 : 0.90),
      height: 1.2,
    );
    final variantStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.25,
    );

    final brandPath = getBrandIconPath(data.make);
    final showBrand = !isBrandIconDefaultAssetPath(brandPath);
    final priceFirst = !priceIncomplete;
    final badges = <Widget>[
      if (data.hasCover)
        ListingBadge(
          label: formatMarketRegion(l10n, data.marketRegion),
          icon: CarzonIcons.map,
          tone: ListingBadgeTone.neutral,
        ),
      if (data.listingType != ListingType.sale)
        ListingBadge(
          key: ListingPreviewCard.typeBadgeKey,
          label: formatType(l10n, data.listingType),
          icon: CarzonIcons.swap,
          tone: ListingBadgeTone.accent,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (priceFirst) ...[
            Text(
              priceLabel,
              key: ListingPreviewCard.priceKey,
              style: priceStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
          _IdentityRow(
            identityLabel: identityLabel,
            titleStyle: titleStyle,
            brandPath: showBrand ? brandPath : null,
          ),
          if (variant != null) ...[
            const SizedBox(height: 3),
            Text(
              variant!,
              key: ListingPreviewCard.variantKey,
              style: variantStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (metaLine.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              metaLine,
              key: ListingPreviewCard.metaKey,
              style: metaStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (specLine.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              specLine,
              key: ListingPreviewCard.specsKey,
              style: metaStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (!priceFirst) ...[
            const SizedBox(height: 8),
            Text(
              priceLabel,
              key: ListingPreviewCard.priceKey,
              style: priceStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: badges),
          ],
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.identityLabel,
    required this.titleStyle,
    required this.brandPath,
  });

  final String identityLabel;
  final TextStyle? titleStyle;
  final String? brandPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (brandPath != null) ...[
          ExcludeSemantics(
            child: BrandLogoGlyph(
              assetPath: brandPath!,
              size: ListingPreviewCard._brandGlyphSize,
              innerSizeFraction: 1,
              darkWell: false,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            identityLabel,
            key: ListingPreviewCard.identityKey,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
