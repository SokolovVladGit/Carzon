import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/brands/brand_logo_glyph.dart';
import '../../domain/entities/listing.dart';
import '../utils/listing_details_header_titles.dart';
import '../utils/listing_details_uri_launcher.dart';
import '../utils/listing_formatters.dart';
import 'listing_details_body.dart';

// --------------------------------------------------------------------
// State-specific content below the (hoisted) hero section + content panel
// --------------------------------------------------------------------
//
// These widgets render only the content that sits UNDER the hero image.
// Behavior, visuals, and localization keys are unchanged from the previous
// same-library `part`; all page-private inputs are now passed explicitly.

/// Horizontal gutter used for the below-hero content.
const double _pageHPadding = 20;

/// How far the below-hero content block is pulled up so its rounded
/// top corners sit on the hero image. Purely cosmetic — the layout
/// height of the below-hero block is unchanged.
const double _heroContentOverlap = 20;

class SuccessBelowHero extends StatelessWidget {
  const SuccessBelowHero({
    super.key,
    required this.listing,
    required this.carouselPageZeroBased,
    required this.carouselPhotoCount,
    required this.reportEmail,
    required this.uriLauncher,
  });

  final Listing listing;
  final int carouselPageZeroBased;

  /// Number of carousel photos from `listing_images` (+ cover fallback).
  final int carouselPhotoCount;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;

  @override
  Widget build(BuildContext context) {
    // Cosmetic overlap: pulls the rounded header panel up over the
    // hero's bottom edge. Children keep their natural layout; this is
    // a paint-time offset only.
    final Widget indicator;
    if (carouselPhotoCount <= 1) {
      indicator = const SizedBox.shrink();
    } else {
      indicator = _ListingGalleryIndicator(
        currentIndex: carouselPageZeroBased.clamp(0, carouselPhotoCount - 1),
        imageCount: carouselPhotoCount,
      );
    }

    return Transform.translate(
      offset: const Offset(0, -_heroContentOverlap),
      child: _ListingContentPanel(
        header: _ListingHeader(listing: listing, indicator: indicator),
        body: BelowHeroContent(
          listing: listing,
          reportEmail: reportEmail,
          uriLauncher: uriLauncher,
        ),
      ),
    );
  }
}

/// Rounded-top panel seam below the hero (loading / failure / success body).
class _ListingBelowHeroPanel extends StatelessWidget {
  const _ListingBelowHeroPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final decoration = light
        ? BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          )
        : AppTheme.editorialDarkSectionCard(scheme, borderRadius: 24)!;
    return DecoratedBox(decoration: decoration, child: child);
  }
}

class LoadingBelowHero extends StatelessWidget {
  const LoadingBelowHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (theme.brightness == Brightness.light) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 40),
          Center(child: LoadingView()),
          SizedBox(height: 40),
        ],
      );
    }
    return _ListingBelowHeroPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 52),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.editorialAccentColor(scheme),
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

class FailureBelowHero extends StatelessWidget {
  const FailureBelowHero({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (theme.brightness == Brightness.light) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _pageHPadding),
            child: ErrorView(message: message, onRetry: onRetry),
          ),
          const SizedBox(height: 32),
        ],
      );
    }
    return _ListingBelowHeroPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _pageHPadding,
          36,
          _pageHPadding,
          40,
        ),
        child: Theme(
          data: theme.copyWith(
            iconTheme: IconThemeData(
              color: scheme.error.withValues(alpha: 0.88),
              size: 48,
            ),
            textTheme: theme.textTheme.apply(
              bodyColor: scheme.onSurface.withValues(alpha: 0.92),
              displayColor: scheme.onSurface.withValues(alpha: 0.92),
            ),
          ),
          child: ErrorView(message: message, onRetry: onRetry),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// Listing content panel (header + body, under the hero)
// --------------------------------------------------------------------

/// Rounded-top surface panel that hosts the entire scrollable body
/// under the hero section. The corner radius is the visual seam
/// between the photo and the page body. [header] sits flush against
/// the top edge (no outer horizontal gutter) so the pager indicator
/// can be centred on the full panel width; [body] carries the usual
/// page-gutter padding.
class _ListingContentPanel extends StatelessWidget {
  const _ListingContentPanel({required this.header, required this.body});

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final decoration = light
        ? BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          )
        : AppTheme.editorialDarkSectionCard(scheme, borderRadius: 24)!;
    return Container(
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _pageHPadding,
              8,
              _pageHPadding,
              32,
            ),
            child: body,
          ),
        ],
      ),
    );
  }
}

/// New listing header that lives at the top of the content
/// panel (not over the photo). Shows:
///   1. The pager indicator (hidden when no photos exist),
///   2. The brand mark,
///   3. Primary line: seller listing title (squeezed) when set, else make+model,
///   4. Optional structured subtitle: `make model · year` when the title lacks
///      that identity (redundant identity+year lines are omitted),
///   5. Region + type badges,
///   6. Secondary meta row (year • mileage • city),
///   7. Price in the primary accent colour.
class _ListingHeader extends StatelessWidget {
  const _ListingHeader({required this.listing, required this.indicator});

  final Listing listing;
  final Widget indicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final l10n = context.l10n;
    final headerDisplay = ListingDetailsHeaderDisplay.fromListing(listing);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_pageHPadding, 14, _pageHPadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: indicator),
          const SizedBox(height: 20),
          _BrandMark(make: listing.make),
          const SizedBox(height: 16),
          Text(
            headerDisplay.primaryLine,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.1,
              color: scheme.onSurface.withValues(alpha: light ? 1 : 0.98),
            ),
          ),
          if ((headerDisplay.tagline ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              headerDisplay.tagline!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: .88,
                ),
                fontWeight: FontWeight.w500,
                height: 1.25,
                letterSpacing: 0.02,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _MetaBadgesRow(
            badges: [
              _MetaBadge(label: formatMarketRegion(l10n, listing.marketRegion)),
              _MetaBadge(label: formatType(l10n, listing.type)),
            ],
          ),
          const SizedBox(height: 12),
          _FeatureCards(
            items: [
              _FeatureItemData(
                icon: Icons.calendar_month_outlined,
                value: listing.year.toString(),
              ),
              _FeatureItemData(
                icon: Icons.speed_outlined,
                value: formatKm(l10n, listing.mileageKm),
              ),
              if (listing.city.isNotEmpty)
                _FeatureItemData(
                  icon: Icons.place_outlined,
                  value: listing.city,
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            formatListingPriceFromListing(listing),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: light
                  ? scheme.primary
                  : AppTheme.editorialAccentColor(scheme),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 26),
          const _HairlineDivider(),
        ],
      ),
    );
  }
}

/// Summary chip icon: outlined Material icons, quiet relative to value text.
const double _summaryChipIconSize = 16;
const double _summaryChipIconAlpha = 0.64;

/// "At a glance" feature cards placed between the badges and the
/// price. Each data point (year, mileage, city) gets its own
/// compact card: icon + value centered on a very light neutral
/// fill with a hairline border and a whisper of elevation. The
/// cards are equally wide via [Expanded] so they always fit on one
/// row and never overflow; long values ellipsize.
class _FeatureCards extends StatelessWidget {
  const _FeatureCards({required this.items});

  final List<_FeatureItemData> items;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(child: _FeatureCard(data: items[i])),
        ],
      ],
    );
  }
}

class _FeatureItemData {
  const _FeatureItemData({required this.icon, required this.value});
  final IconData icon;
  final String value;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final _FeatureItemData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final decoration = light
        ? BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.045),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : AppTheme.editorialDarkSectionCard(scheme, borderRadius: 13)!;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: decoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            data.icon,
            size: _summaryChipIconSize,
            color:
                (light ? scheme.primary : AppTheme.editorialAccentColor(scheme))
                    .withValues(alpha: light ? _summaryChipIconAlpha : 0.78),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dots under the hero overlay already echo page position; above the panel
/// use a calmer pill/dot row on the light/dark details surface.
class _ListingGalleryIndicator extends StatelessWidget {
  const _ListingGalleryIndicator({
    required this.currentIndex,
    required this.imageCount,
  });

  final int currentIndex;
  final int imageCount;

  static const Duration _animDuration = Duration(milliseconds: 220);
  static const Curve _animCurve = Curves.easeOutCubic;
  static const double _dotSize = 5.5;
  static const double _pillWidth = 18;
  static const double _trackHeight = 5.5;
  static const double _gap = 5;

  @override
  Widget build(BuildContext context) {
    if (imageCount <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final safeIndex = currentIndex.clamp(0, imageCount - 1);

    final inactive = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.5 : 0.38,
    );
    final active = scheme.primary.withValues(alpha: isDark ? 0.92 : 0.88);

    final track = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(imageCount, (i) {
        final on = i == safeIndex;
        return AnimatedContainer(
          duration: _animDuration,
          curve: _animCurve,
          margin: const EdgeInsets.symmetric(horizontal: _gap / 2),
          height: _trackHeight,
          width: on ? _pillWidth : _dotSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: on ? active : inactive,
          ),
        );
      }),
    );

    return Semantics(
      label: '${safeIndex + 1} of $imageCount',
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: track,
          ),
        ),
      ),
    );
  }
}

/// Brand identity mark: just the SVG icon (no background tile, no
/// text). Falls back to a single large letter when the resolver
/// returns the neutral default slug.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.make});

  final String make;

  static const double _iconSize = 30;
  static const String _defaultSuffix = '/default.svg';

  @override
  Widget build(BuildContext context) {
    final assetPath = getBrandIconPath(make);
    final isUnknown = assetPath.endsWith(_defaultSuffix);

    if (isUnknown) {
      return Text(
        _firstLetter(make),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1,
        ),
      );
    }

    return BrandLogoGlyph(assetPath: assetPath, size: _iconSize);
  }

  static String _firstLetter(String make) {
    final trimmed = make.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }
}

/// Neutral metadata badge used in the below-image header for region
/// + type. Subtle grey fill, rounded, `labelMedium` text.
class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: light
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.08),
                scheme.surfaceContainerHigh,
              ),
        borderRadius: BorderRadius.circular(8),
        border: light
            ? null
            : Border.all(color: scheme.outline.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: light ? 0.72 : 0.84),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.15,
        ),
      ),
    );
  }
}

class _MetaBadgesRow extends StatelessWidget {
  const _MetaBadgesRow({required this.badges});

  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: badges);
  }
}

/// Very subtle full-width hairline used between price and the rest
/// of the content panel. Rendered at ~7% opacity so it structures
/// the layout without reading as a table line.
class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = scheme.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.16);
    return Divider(height: 1, thickness: 0.5, color: color);
  }
}
