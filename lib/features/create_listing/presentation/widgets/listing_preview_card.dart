import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/brands/brand_logo_glyph.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_details_header_titles.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../models/listing_preview_data.dart';
import 'create_listing_compose_layout.dart';

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
  static const Key detailKey = ValueKey(
    'create_listing_listing_preview_detail',
  );
  static const Key typeBadgeKey = ValueKey(
    'create_listing_listing_preview_type_badge',
  );

  static const double _cardRadius = 18;
  @visibleForTesting
  static const double compactCoverHeight = 68;
  @visibleForTesting
  static const double sideCoverExtent = 136;
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
      if (data.bodyType != null) formatListingBodyType(l10n, data.bodyType!),
      if (data.fuelType != null) formatListingFuelType(l10n, data.fuelType!),
      if (data.engineDisplacementLiters != null)
        formatEngineDisplacementForDisplay(l10n, data.engineDisplacementLiters),
      if (data.enginePowerHp != null)
        formatEnginePowerHpDisplay(l10n, data.enginePowerHp),
      if (data.transmissionType != null)
        formatListingTransmissionType(l10n, data.transmissionType!),
    ]);
    final detailLine = listingPreviewJoin([
      if (data.drivetrain != null)
        formatListingDrivetrain(l10n, data.drivetrain!),
      if (data.engineCylinders != null)
        '${l10n.listingEngineCylinders} ${data.engineCylinders}',
      if (data.doors != null) '${l10n.listingDoors} ${data.doors}',
      if (data.seats != null) '${l10n.listingSeats} ${data.seats}',
    ]);
    final variant = data.variant;

    final semantics = [
      l10n.createListingPreviewHeading,
      identityLabel,
      ?variant,
      priceLabel,
      if (metaLine.isNotEmpty) metaLine,
      if (specLine.isNotEmpty) specLine,
      if (detailLine.isNotEmpty) detailLine,
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
          style: createListingSectionTitleStyle(theme)?.copyWith(fontSize: 15),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
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
              detailLine: detailLine,
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
    required this.detailLine,
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
  final String detailLine;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = ListingPreviewCard._cardRadius;
    final panelBg = isDark
        ? Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.07),
            scheme.surface,
          )
        : Colors.white;
    final borderColor = scheme.onSurface.withValues(
      alpha: isDark ? 0.18 : 0.12,
    );

    return DecoratedBox(
      key: ListingPreviewCard.cardKey,
      decoration: BoxDecoration(
        color: isDark ? panelBg : const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? borderColor : const Color(0xFFE6D9CC),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x107A6A58),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final stacked = constraints.maxWidth < 340 || scale > 1.15;
            final cover = _PreviewCover(
              bytes: data.coverBytes,
              compact: !data.hasCover,
              hint: l10n.createListingPreviewAddPhotoHint,
            );
            final info = _PreviewInfoPanel(
              theme: theme,
              l10n: l10n,
              data: data,
              identityLabel: identityLabel,
              variant: variant,
              priceLabel: priceLabel,
              priceIncomplete: priceIncomplete,
              metaLine: metaLine,
              specLine: specLine,
              detailLine: detailLine,
            );
            if (stacked) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: ListingPreviewCard.sideCoverExtent,
                    child: cover,
                  ),
                  info,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 42,
                    child: _CoverSlot(
                      extent: ListingPreviewCard.sideCoverExtent,
                      child: cover,
                    ),
                  ),
                  Expanded(flex: 58, child: _LooseWidth(child: info)),
                ],
              ),
            );
          },
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
    return _PreviewPhoto(bytes: bytes!);
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
          color: scheme.onSurface.withValues(alpha: 0.06),
          child: Center(
            child: Icon(
              CarzonIcons.coverCarPlaceholder,
              size: 28,
              color: scheme.onSurface.withValues(alpha: 0.55),
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
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    return ColoredBox(
      key: ListingPreviewCard.coverPlaceholderKey,
      color: scheme.onSurface.withValues(
        alpha: theme.brightness == Brightness.light ? 0.045 : 0.08,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CarzonIcons.addPhoto, size: 22, color: muted),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                hint,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: createListingSupportStyle(theme)?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  fontSize: 11,
                ),
              ),
            ],
          ],
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
    required this.detailLine,
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
  final String detailLine;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final priceStyle =
        (priceIncomplete
                ? theme.textTheme.bodyMedium
                : theme.textTheme.titleMedium)
            ?.copyWith(
              fontSize: priceIncomplete ? 13 : 17,
              fontWeight: priceIncomplete ? FontWeight.w500 : FontWeight.w700,
              color: priceIncomplete
                  ? scheme.onSurface.withValues(alpha: isDark ? 0.70 : 0.62)
                  : scheme.onSurface,
              letterSpacing: priceIncomplete ? -0.1 : -0.35,
              height: 1.25,
            );
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
      letterSpacing: -0.25,
      color: scheme.onSurface.withValues(alpha: isDark ? 0.96 : 0.94),
      height: 1.15,
    );
    final variantStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.64 : 0.50),
      height: 1.25,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final specStyle = metaStyle?.copyWith(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.72 : 0.58),
      height: isDark ? 1.35 : 1.25,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.12,
    );
    final detailStyle = metaStyle?.copyWith(height: isDark ? 1.35 : 1.25);
    final factLines = isDark ? 3 : 2;

    final brandPath = getBrandIconPath(data.make);
    final showBrand = !isBrandIconDefaultAssetPath(brandPath);
    final priceFirst = !priceIncomplete;
    final badges = <Widget>[
      if (data.hasCover)
        _PreviewChip(
          label: formatMarketRegion(l10n, data.marketRegion),
          icon: CarzonIcons.map,
          foreground: scheme.onSurface.withValues(alpha: 0.72),
          background: scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.06),
        ),
      if (data.listingType != ListingType.sale)
        _PreviewChip(
          key: ListingPreviewCard.typeBadgeKey,
          label: formatType(l10n, data.listingType),
          icon: CarzonIcons.swap,
          foreground: scheme.onSecondaryContainer,
          background: scheme.secondaryContainer.withValues(
            alpha: isDark ? 0.45 : 0.55,
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
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
            const SizedBox(height: 2),
          ],
          _IdentityRow(
            identityLabel: identityLabel,
            titleStyle: titleStyle,
            brandPath: showBrand ? brandPath : null,
          ),
          if (variant != null) ...[
            const SizedBox(height: 2),
            Text(
              variant!,
              key: ListingPreviewCard.variantKey,
              style: variantStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (metaLine.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              metaLine,
              key: ListingPreviewCard.metaKey,
              style: metaStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (specLine.isNotEmpty) ...[
            SizedBox(height: isDark ? 4 : 2),
            Text(
              specLine,
              key: ListingPreviewCard.specsKey,
              style: specStyle,
              maxLines: factLines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (detailLine.isNotEmpty) ...[
            SizedBox(height: isDark ? 4 : 2),
            Text(
              detailLine,
              key: ListingPreviewCard.detailKey,
              style: detailStyle,
              maxLines: factLines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (!priceFirst) ...[
            const SizedBox(height: 4),
            Text(
              priceLabel,
              key: ListingPreviewCard.priceKey,
              style: priceStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 0; i < badges.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Flexible(child: badges[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Reports [extent] as its intrinsic height so a short info column keeps the
/// marketplace card compact, while a taller column can grow past [extent]
/// instead of overflowing.
class _CoverSlot extends SingleChildRenderObjectWidget {
  const _CoverSlot({required this.extent, required Widget child})
    : super(child: child);

  final double extent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCoverSlot(extent);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCoverSlot renderObject) {
    renderObject.extent = extent;
  }
}

class _RenderCoverSlot extends RenderProxyBox {
  _RenderCoverSlot(this._extent);

  double _extent;

  double get extent => _extent;

  set extent(double value) {
    if (_extent == value) return;
    _extent = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) => _extent;

  @override
  double computeMaxIntrinsicHeight(double width) => _extent;
}

/// Drops the child's minimum intrinsic width so a long one-line label
/// ellipsizes inside the preview row instead of stretching it.
class _LooseWidth extends SingleChildRenderObjectWidget {
  const _LooseWidth({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLooseWidth();
}

class _RenderLooseWidth extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    super.key,
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
          ),
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
