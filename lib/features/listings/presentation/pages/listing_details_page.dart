import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/entities/listing.dart';
import '../bloc/listing_details_cubit.dart';
import '../bloc/listing_details_state.dart';
import '../utils/contact_format.dart';
import '../utils/listing_formatters.dart';
import '../utils/report_listing_mailto.dart';
import '../widgets/listing_cover_image.dart';

/// Minimal launcher seam local to this page — mirrors the
/// `EditListingImagePicker` typedef on the edit-listing page so widget
/// tests can intercept `launchUrl` without owning a global abstraction.
typedef ListingDetailsUriLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternalUri(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Horizontal gutter used for the below-hero content.
const double _pageHPadding = 20;

/// Fixed height of the hero image section. Taller than the old
/// overlay-heavy hero so the photo feels like a proper showcase
/// while still leaving the below-panel header visible above the
/// fold on a standard 5.5" device.
const double _heroHeight = 380;

/// How far the below-hero content block is pulled up so its rounded
/// top corners sit on the hero image. Purely cosmetic — the layout
/// height of the below-hero block is unchanged.
const double _heroContentOverlap = 20;

class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({
    super.key,
    required this.id,
    this.reportEmail,
    this.uriLauncher,
    this.initialCoverImageUrl,
  });

  final String id;

  /// Optional ops/moderation inbox for the "Report listing" action.
  /// When `null` or empty, the report surface is hidden entirely —
  /// the MVP must never synthesize a fake recipient.
  final String? reportEmail;

  /// Test seam for the "Report listing" mailto launcher.
  final ListingDetailsUriLauncher? uriLauncher;

  /// Cover image URL already known by the navigating caller, passed
  /// through `GoRouter` `extra` so the Hero flight on the push
  /// transition animates the real tapped photo instead of the
  /// placeholder. Used only until [ListingDetailsCubit] emits a
  /// loaded [Listing], after which that listing's own
  /// `coverImageUrl` takes over.
  final String? initialCoverImageUrl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ListingDetailsCubit>()..load(id),
      child: _ListingDetailsView(
        id: id,
        reportEmail: reportEmail,
        uriLauncher: uriLauncher,
        initialCoverImageUrl: initialCoverImageUrl,
      ),
    );
  }
}

class _ListingDetailsView extends StatelessWidget {
  const _ListingDetailsView({
    required this.id,
    required this.reportEmail,
    required this.uriLauncher,
    required this.initialCoverImageUrl,
  });

  final String id;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;
  final String? initialCoverImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pure white surface — hero image and bottom bar carry all the
      // colour, the body stays clean.
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero lives ABOVE the state-dependent BlocBuilder so the
            // destination Hero widget and its `Image.network` child
            // are not torn down mid-flight when the Cubit transitions
            // `initial → loading → success` during the push. The URL
            // prefers the route-extra value (which matches the tapped
            // card exactly) and only updates to the Cubit-loaded URL
            // if it actually differs — typically after the flight has
            // already completed.
            BlocSelector<ListingDetailsCubit, ListingDetailsState, String?>(
              // Use the route-extra cover URL only while the Cubit
              // has not resolved a listing yet. Once it has, the
              // loaded listing's own `coverImageUrl` takes over —
              // including when that URL is `null`, so a stale extra
              // URL can never mask a listing that has no cover.
              selector: (state) => state.listing == null
                  ? initialCoverImageUrl
                  : state.listing!.coverImageUrl,
              builder: (context, imageUrl) => _HeroSection(
                listingId: id,
                imageUrl: imageUrl,
              ),
            ),
            BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
              builder: (context, state) {
                switch (state.status) {
                  case ListingDetailsStatus.initial:
                  case ListingDetailsStatus.loading:
                    return const _LoadingBelowHero();
                  case ListingDetailsStatus.failure:
                    return _FailureBelowHero(
                      message: state.errorMessage ??
                          context.l10n.listingDetailsLoadFailed,
                      onRetry: () =>
                          context.read<ListingDetailsCubit>().load(id),
                    );
                  case ListingDetailsStatus.success:
                    return _SuccessBelowHero(
                      listing: state.listing!,
                      reportEmail: reportEmail,
                      uriLauncher: uriLauncher,
                    );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
        buildWhen: (p, c) =>
            p.status != c.status || p.listing != c.listing,
        builder: (context, state) {
          if (state.status != ListingDetailsStatus.success) {
            return const SizedBox.shrink();
          }
          return _ContactBottomBar(listing: state.listing!);
        },
      ),
    );
  }
}

// --------------------------------------------------------------------
// State-specific content below the (hoisted) hero section
// --------------------------------------------------------------------
//
// These widgets render only the content that sits UNDER the hero
// image. The hero itself is mounted once, higher up in the tree
// (see `_ListingDetailsView.build`) so the shared `Hero` widget and
// its `Image.network` child stay identical across state transitions —
// which is what keeps the forward Hero flight from glitching when
// the Cubit flips from `loading` to `success` mid-transition.

class _SuccessBelowHero extends StatelessWidget {
  const _SuccessBelowHero({
    required this.listing,
    required this.reportEmail,
    required this.uriLauncher,
  });

  final Listing listing;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;

  @override
  Widget build(BuildContext context) {
    // Cosmetic overlap: pulls the rounded header panel up over the
    // hero's bottom edge. Children keep their natural layout; this is
    // a paint-time offset only.
    return Transform.translate(
      offset: const Offset(0, -_heroContentOverlap),
      child: _ListingContentPanel(
        header: _ListingHeader(
          listing: listing,
          indicator: const _ListingPagerIndicator(current: 1, total: 1),
        ),
        body: _BelowHeroContent(
          listing: listing,
          reportEmail: reportEmail,
          uriLauncher: uriLauncher,
        ),
      ),
    );
  }
}

class _LoadingBelowHero extends StatelessWidget {
  const _LoadingBelowHero();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 40),
        Center(child: LoadingView()),
        SizedBox(height: 40),
      ],
    );
  }
}

class _FailureBelowHero extends StatelessWidget {
  const _FailureBelowHero({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
}

// --------------------------------------------------------------------
// Hero section
// --------------------------------------------------------------------

/// Edge-to-edge hero header. Keeps the photo as the visual focus —
/// no title / badges / price overlay any more. Painting order:
///   1. The cover image (shared `Hero` tag with the feed card),
///   2. A very light top scrim so the back / favorite icons stay
///      legible on bright photos,
///   3. Top chrome (back button + favorite) pinned tight to
///      `SafeArea`.
///
/// Always renders exactly one [ListingCoverImage] with the id-based
/// `Hero` tag so the push transition from the feed always has a
/// single valid destination, regardless of state.
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.listingId, required this.imageUrl});

  final String listingId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _heroHeight,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ListingCoverImage(
              imageUrl: imageUrl,
              heroTag: listingCoverHeroTag(listingId),
            ),
            const _HeroScrim(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _HeroTopControls(listingId: listingId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Very light uniform scrim. The glass tiles on the top controls now
/// carry their own readable background, so the scrim only has to
/// cover the rare case of a fully white sky / body panel — it stays
/// nearly invisible over normal photos.
class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x1F000000), // ~12% black: ambient, not a darken
              Color(0x00000000),
            ],
            stops: [0.0, 0.35],
          ),
        ),
      ),
    );
  }
}

/// Top chrome on the hero: matching glass tiles on the left (back)
/// and right (favorite). Aligned to the page's horizontal gutter and
/// pulled tight to the safe-area top so the tiles feel anchored to
/// the corners of the image, not floating in its middle.
class _HeroTopControls extends StatelessWidget {
  const _HeroTopControls({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pageHPadding, 0, _pageHPadding, 0),
      child: Row(
        children: [
          _HeroGlassTile(
            child: const AppBackButton(fallback: AppRoutes.listings),
          ),
          const Spacer(),
          _HeroGlassTile(
            child: FavoriteToggleButton(listingId: listingId),
          ),
        ],
      ),
    );
  }
}

/// Premium glass tile used for every hero-image overlay control.
///
/// Visual recipe:
///   * 40×40 rounded square, radius 12,
///   * translucent white fill (~72%) so the icon reads over any
///     photo without looking like a pasted-on chip,
///   * backdrop blur behind the fill so the photo is softened,
///     which is the detail that makes it feel like glass,
///   * hairline white inner border + low-opacity elevation shadow
///     for a subtle lift,
///   * dark (`onSurface`) icon theme at 20 px.
///
/// Forwards all pointer events to the hosted [child], so the
/// `AppBackButton` / `FavoriteToggleButton` logic (pop, fallback,
/// auth gating, toggle, pending state) stays intact. The hosted
/// `IconButton` is stripped of its 48 px minimum via a local
/// `IconButtonTheme` so its tap target fits the 40 px tile cleanly.
class _HeroGlassTile extends StatelessWidget {
  const _HeroGlassTile({required this.child});

  final Widget child;

  static const double _size = 40;
  static const double _radius = 12;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurface;

    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: IconTheme.merge(
                data: IconThemeData(color: iconColor, size: _iconSize),
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(_size, _size),
                      maximumSize: const Size(_size, _size),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// Listing content panel (header + body, under the hero)
// --------------------------------------------------------------------

/// Rounded-top white panel that hosts the entire scrollable body
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

/// New listing header that lives at the top of the white content
/// panel (not over the photo). Shows, in order:
///   1. The pager indicator centred just under the image,
///   2. The brand mark,
///   3. Listing title,
///   4. Region + type badges,
///   5. Secondary meta row (year • mileage • city),
///   6. Price in the primary accent colour.
class _ListingHeader extends StatelessWidget {
  const _ListingHeader({required this.listing, required this.indicator});

  final Listing listing;
  final Widget indicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

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
            listing.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
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
                icon: CarzonIcons.calendar,
                value: listing.year.toString(),
              ),
              _FeatureItemData(
                icon: CarzonIcons.gauge,
                value: formatKm(listing.mileageKm),
              ),
              if (listing.city.isNotEmpty)
                _FeatureItemData(
                  icon: CarzonIcons.location,
                  value: listing.city,
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            formatEur(listing.priceEur),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
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
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            data.icon,
            size: 16,
            color: scheme.primary.withValues(alpha: 0.78),
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

/// Small pill that hints at image pagination. Rendered inside the
/// white header panel (centred, just under the photo), not over the
/// image. Carzon's MVP stores a single photo per listing so [total]
/// is effectively always `1` today — the widget is kept so the
/// affordance is in place for the later multi-image migration.
class _ListingPagerIndicator extends StatelessWidget {
  const _ListingPagerIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$current / $total',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          fontSize: 10.5,
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

    return SvgPicture.asset(
      assetPath,
      width: _iconSize,
      height: _iconSize,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const SizedBox(width: _iconSize, height: _iconSize),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.72),
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
    final color = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.07);
    return Divider(height: 1, thickness: 0.5, color: color);
  }
}

/// Below-hero content block: specs list, public-contact notice,
/// secondary links, optional report action.
class _BelowHeroContent extends StatelessWidget {
  const _BelowHeroContent({
    required this.listing,
    required this.reportEmail,
    required this.uriLauncher,
  });

  final Listing listing;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final hasReport = reportEmail != null && reportEmail!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _DetailsList(listing: listing),
        const SizedBox(height: 24),
        Text(
          l10n.contactPublicNotice,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _SecondaryContactLinks(listing: listing),
        if (hasReport) ...[
          const SizedBox(height: 16),
          _ReportLink(
            listing: listing,
            recipientEmail: reportEmail!,
            launcher: uriLauncher ?? _launchExternalUri,
          ),
        ],
      ],
    );
  }
}

/// Flat details list. No card background, subtle dividers, muted
/// labels, medium-weight values.
class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final rows = <_DetailsRowData>[
      _DetailsRowData(l10n.listingFieldMake, listing.make),
      _DetailsRowData(l10n.listingFieldModel, listing.model),
      _DetailsRowData(l10n.listingFieldYear, listing.year.toString()),
      _DetailsRowData(l10n.listingFieldMileage, formatKm(listing.mileageKm)),
      _DetailsRowData(l10n.listingFieldType, formatType(l10n, listing.type)),
      _DetailsRowData(l10n.listingFieldCity, listing.city),
      _DetailsRowData(
        l10n.listingFieldRegion,
        formatMarketRegion(l10n, listing.marketRegion),
      ),
      _DetailsRowData(l10n.listingFieldPosted, formatDate(listing.createdAt)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingDetailsSpecs,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < rows.length; i++) _DetailsRow(data: rows[i]),
      ],
    );
  }
}

class _DetailsRowData {
  const _DetailsRowData(this.label, this.value);
  final String label;
  final String value;
}

/// Flat two-column details row. No divider — the only visual rhythm
/// is vertical padding between rows, which keeps the section feeling
/// like prose rather than a settings table.
class _DetailsRow extends StatelessWidget {
  const _DetailsRow({required this.data});

  final _DetailsRowData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              data.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              data.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Secondary messenger links (Telegram, WhatsApp). Rendered as a
/// low-emphasis Wrap of text buttons below the details list so they
/// remain available without competing with the sticky contact bar.
class _SecondaryContactLinks extends StatelessWidget {
  const _SecondaryContactLinks({required this.listing});

  final Listing listing;

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contactActionFailed)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contactActionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final telegram = listing.telegramUsername;
    final waDigits =
        listing.whatsappEnabled ? whatsappDigits(listing.contactPhone) : null;

    final buttons = <Widget>[
      if (telegram != null && telegram.isNotEmpty)
        TextButton.icon(
          onPressed: () =>
              _launch(context, Uri.parse('https://t.me/$telegram')),
          icon: const Icon(CarzonIcons.send),
          label: Text(l10n.contactTelegramLabel(telegram)),
        ),
      if (waDigits != null)
        TextButton.icon(
          onPressed: () =>
              _launch(context, Uri.parse('https://wa.me/$waDigits')),
          icon: const Icon(CarzonIcons.chat),
          label: Text(l10n.contactWhatsapp),
        ),
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: buttons,
      ),
    );
  }
}

/// Low-emphasis "Report listing" link kept at the bottom of scroll
/// content. Launch behavior unchanged from the previous surface so
/// the existing mailto unit/widget tests keep asserting the same URI.
class _ReportLink extends StatelessWidget {
  const _ReportLink({
    required this.listing,
    required this.recipientEmail,
    required this.launcher,
  });

  final Listing listing;
  final String recipientEmail;
  final ListingDetailsUriLauncher launcher;

  Future<void> _onTap(BuildContext context) async {
    final uri = buildReportListingMailto(
      l10n: context.l10n,
      listing: listing,
      recipientEmail: recipientEmail,
    );
    try {
      final ok = await launcher(uri);
      if (!ok && context.mounted) _showError(context);
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.reportListingMailFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportListingDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _onTap(context),
            icon: const Icon(CarzonIcons.report),
            label: Text(l10n.reportListing),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------
// Bottom contact bar (unchanged behaviour)
// --------------------------------------------------------------------

/// Sticky bottom contact bar. Kept structurally identical to the
/// previous revision — only the hero refactor above this point
/// changed, everything here (chat placeholder, phone reveal flow,
/// inline copy affordance) is preserved.
class _ContactBottomBar extends StatefulWidget {
  const _ContactBottomBar({required this.listing});

  final Listing listing;

  @override
  State<_ContactBottomBar> createState() => _ContactBottomBarState();
}

class _ContactBottomBarState extends State<_ContactBottomBar> {
  bool _phoneRevealed = false;

  Future<void> _onPhoneTap(BuildContext context, String tel) async {
    if (!_phoneRevealed) {
      setState(() => _phoneRevealed = true);
      return;
    }
    try {
      final ok = await launchUrl(
        Uri.parse(tel),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) _showError(context);
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  Future<void> _onCopyPhone(BuildContext context, String rawPhone) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: rawPhone.trim()));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.contactPhoneCopied)),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.contactActionFailed)),
        );
      }
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.contactActionFailed)),
    );
  }

  void _onChatTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.chatNotAvailable)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = widget.listing.contactPhone;
    final tel = telUriString(phone);
    final divider = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Material(
      color: theme.colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: divider, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(
              height: _bottomButtonHeight,
              child: Row(
                children: [
                  _ChatPillButton(onTap: () => _onChatTap(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhonePrimaryPill(
                      tel: tel,
                      rawPhone: phone,
                      revealed: _phoneRevealed,
                      onTap: tel == null
                          ? null
                          : () => _onPhoneTap(context, tel),
                      onCopy: (tel == null || !_phoneRevealed || phone == null)
                          ? null
                          : () => _onCopyPhone(context, phone),
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

const double _bottomButtonHeight = 50;
const double _bottomButtonRadius = 12;

RoundedRectangleBorder _bottomButtonShape() => const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(_bottomButtonRadius)),
    );

class _ChatPillButton extends StatelessWidget {
  const _ChatPillButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    return SizedBox(
      height: _bottomButtonHeight,
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: const Icon(CarzonIcons.chat, size: 20),
        label: Text(l10n.chatLabel),
        style: FilledButton.styleFrom(
          backgroundColor:
              scheme.surfaceContainerHighest.withValues(alpha: 0.9),
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: _bottomButtonShape(),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PhonePrimaryPill extends StatelessWidget {
  const _PhonePrimaryPill({
    required this.tel,
    required this.rawPhone,
    required this.revealed,
    required this.onTap,
    required this.onCopy,
  });

  final String? tel;
  final String? rawPhone;
  final bool revealed;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    ButtonStyle buttonStyle({bool disabled = false}) =>
        FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: _bottomButtonShape(),
          backgroundColor:
              disabled ? theme.colorScheme.surfaceContainerHigh : null,
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        );

    if (tel == null) {
      return SizedBox(
        height: _bottomButtonHeight,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(CarzonIcons.phoneOff, size: 20),
          label: Text(l10n.phoneNotProvided),
          style: buttonStyle(disabled: true),
        ),
      );
    }

    if (!revealed) {
      return SizedBox(
        height: _bottomButtonHeight,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(CarzonIcons.eye, size: 20),
          label: Text(l10n.contactShowPhone),
          style: buttonStyle(),
        ),
      );
    }

    return SizedBox(
      height: _bottomButtonHeight,
      child: FilledButton(
        onPressed: onTap,
        style: buttonStyle().copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.only(left: 18, right: 6),
          ),
        ),
        child: Row(
          children: [
            const Icon(CarzonIcons.phoneCall, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rawPhone!.trim(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 6),
              _InlineCopyAction(
                tooltip: l10n.contactCopyPhone,
                onTap: onCopy!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineCopyAction extends StatelessWidget {
  const _InlineCopyAction({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(CarzonIcons.copy, size: 18),
          ),
        ),
      ),
    );
  }
}
