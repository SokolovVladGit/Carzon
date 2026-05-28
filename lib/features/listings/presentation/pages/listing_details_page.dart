import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/presentation/localized_user_failure_message.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/brands/brand_logo_glyph.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../../shared/ui/whatsapp_contact_icon.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../compare/presentation/widgets/compare_toggle_button.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../../messaging/presentation/utils/messaging_failure_mapper.dart';
import '../../../messaging/presentation/utils/messaging_user_messages.dart';
import '../../domain/entities/listing.dart';
import '../bloc/listing_details_cubit.dart';
import '../bloc/listing_details_state.dart';
import '../utils/contact_format.dart';
import '../utils/listing_formatters.dart';
import '../utils/listing_details_header_titles.dart';
import '../utils/report_listing_mailto.dart';
import '../widgets/listing_cover_image.dart';
import '../widgets/listing_details_fullscreen_gallery.dart';
import '../widgets/listing_details_vin_entry.dart';
import '../../../sellers/presentation/widgets/seller_trust_section.dart';

/// Minimal launcher seam local to this page — mirrors the
/// `EditListingImagePicker` typedef on the edit-listing page so widget
/// tests can intercept `launchUrl` without owning a global abstraction.
typedef ListingDetailsUriLauncher = Future<bool> Function(Uri uri);

String? _nonEmptyTrimmedDescription(Listing listing) {
  final raw = listing.description;
  if (raw == null) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

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
    this.coverHeroFlightTopRadius,
  });

  final String id;

  /// Optional ops/moderation inbox for the "Report listing" action.
  /// When `null` or empty, the report surface is hidden entirely —
  /// the MVP must never synthesize a fake recipient.
  final String? reportEmail;

  /// Test seam for the "Report listing" mailto launcher.
  final ListingDetailsUriLauncher? uriLauncher;

  /// through `GoRouter` `extra` so the Hero flight matches the tapped
  /// card while [ListingDetailsCubit] has not emitted resolved gallery
  /// URLs yet ([ListingDetailsStatus.loading]). After success, carousel
  /// URLs come exclusively from [`ListingDetailsState.heroImageUrls`].
  final String? initialCoverImageUrl;

  /// Feed card cover top radius for Hero shuttle (null ⇒ regular card default).
  final double? coverHeroFlightTopRadius;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ListingDetailsCubit>()
            ..load(id, initialCoverImageUrl: initialCoverImageUrl),
      child: _ListingDetailsView(
        id: id,
        reportEmail: reportEmail,
        uriLauncher: uriLauncher,
        initialCoverImageUrl: initialCoverImageUrl,
        heroFlightSourceTopRadius: coverHeroFlightTopRadius ?? 20,
      ),
    );
  }
}

class _ListingDetailsView extends StatefulWidget {
  const _ListingDetailsView({
    required this.id,
    required this.reportEmail,
    required this.uriLauncher,
    required this.initialCoverImageUrl,
    required this.heroFlightSourceTopRadius,
  });

  final String id;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;
  final String? initialCoverImageUrl;
  final double heroFlightSourceTopRadius;

  @override
  State<_ListingDetailsView> createState() => _ListingDetailsViewState();
}

class _ListingDetailsViewState extends State<_ListingDetailsView> {
  int _carouselPageIndex = 0;

  final GlobalKey _compareFlySourceKey = GlobalKey(
    debugLabel: 'listing_details_compare_fly_source',
  );
  final GlobalKey _compareToggleFlyKey = GlobalKey(
    debugLabel: 'listing_details_compare_fly_fallback',
  );

  /// Single source of truth for the hoisted hero PageView (loading route
  /// extra, success `heroImageUrls`, or `listing.coverImageUrl` fallback).
  List<String> _effectiveHeroUrls(ListingDetailsState state) {
    switch (state.status) {
      case ListingDetailsStatus.loading:
      case ListingDetailsStatus.initial:
        final s = widget.initialCoverImageUrl?.trim();
        return (s != null && s.isNotEmpty) ? [s] : const <String>[];
      case ListingDetailsStatus.success:
        if (state.heroImageUrls.isNotEmpty) {
          return List<String>.from(state.heroImageUrls);
        }
        final c = state.listing?.coverImageUrl?.trim();
        return (c != null && c.isNotEmpty) ? [c] : const <String>[];
      case ListingDetailsStatus.failure:
        return const <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ListingDetailsCubit, ListingDetailsState>(
      listenWhen: (prev, curr) =>
          curr.status == ListingDetailsStatus.loading ||
          prev.listing?.id != curr.listing?.id ||
          !_urlsListEquiv(prev.heroImageUrls, curr.heroImageUrls),
      listener: (context, s) {
        if (!context.mounted) return;
        setState(() {
          _carouselPageIndex = 0;
          switch (s.status) {
            case ListingDetailsStatus.initial:
            case ListingDetailsStatus.loading:
            case ListingDetailsStatus.success:
            case ListingDetailsStatus.failure:
              break;
          }
        });
      },
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark ? null : scheme.surface,
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: AppTheme.editorialDarkFilterCanvasGradient(
                          scheme,
                        ),
                        stops: const [0, 0.35, 1],
                      )
                    : null,
                color: isDark ? null : scheme.surface,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
                      buildWhen: (p, c) =>
                          p.status != c.status ||
                          !_urlsListEquiv(p.heroImageUrls, c.heroImageUrls) ||
                          p.listing?.id != c.listing?.id ||
                          p.listing?.coverImageUrl != c.listing?.coverImageUrl,
                      builder: (context, state) {
                        final carouselUrls = _effectiveHeroUrls(state);
                        return SizedBox(
                          height: _heroHeight,
                          width: double.infinity,
                          child: _ListingHeroCarousel(
                            listingId: widget.id,
                            listing: state.listing,
                            urls: carouselUrls,
                            heroFlightSourceTopRadius:
                                widget.heroFlightSourceTopRadius,
                            flySourceKey: _compareFlySourceKey,
                            compareFlyFallbackKey: _compareToggleFlyKey,
                            onPageChanged: (i) =>
                                setState(() => _carouselPageIndex = i),
                          ),
                        );
                      },
                    ),
                    BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
                      builder: (context, state) {
                        switch (state.status) {
                          case ListingDetailsStatus.initial:
                          case ListingDetailsStatus.loading:
                            return const _LoadingBelowHero();
                          case ListingDetailsStatus.failure:
                            final l10n = context.l10n;
                            final msg = state.loadFailure != null
                                ? localizedUserFailureMessage(
                                    l10n,
                                    state.loadFailure!,
                                    surface:
                                        LocalizedFailureSurface.listingDetails,
                                  )
                                : l10n.listingDetailsLoadFailed;
                            return _FailureBelowHero(
                              message: msg,
                              onRetry: () =>
                                  context.read<ListingDetailsCubit>().load(
                                    widget.id,
                                    initialCoverImageUrl:
                                        widget.initialCoverImageUrl,
                                  ),
                            );
                          case ListingDetailsStatus.success:
                            final heroUrls = _effectiveHeroUrls(state);
                            final n = heroUrls.length;
                            final clipped = n > 0
                                ? _carouselPageIndex.clamp(0, n - 1)
                                : 0;
                            return _SuccessBelowHero(
                              listing: state.listing!,
                              carouselPageZeroBased: clipped,
                              carouselPhotoCount: n,
                              reportEmail: widget.reportEmail,
                              uriLauncher: widget.uriLauncher,
                            );
                        }
                      },
                    ),
                  ],
                ),
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
        },
      ),
    );
  }
}

bool _urlsListEquiv(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// --------------------------------------------------------------------
// State-specific content below the (hoisted) hero section
// --------------------------------------------------------------------
//
// These widgets render only the content that sits UNDER the hero
// image. The hero carousel stays structurally stable (see
// `_ListingHeroCarousel`): first-slot URL aligns loading→success when the feed
// supplies route-extra cover; Gallery merges preserve that ordering via the cubit.

class _SuccessBelowHero extends StatelessWidget {
  const _SuccessBelowHero({
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
        body: _BelowHeroContent(
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

class _LoadingBelowHero extends StatelessWidget {
  const _LoadingBelowHero();

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

class _FailureBelowHero extends StatelessWidget {
  const _FailureBelowHero({required this.message, required this.onRetry});

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
// Hero carousel (ordered gallery URLs + Hero on first slide)
// --------------------------------------------------------------------

Iterable<Widget>? _spreadOptionalTrailing(Widget? w) =>
    w == null ? null : <Widget>[w];

/// Full-bleed hero: stable `PageView` whenever URLs exist (including exactly one).
/// Placeholder only when empty. Index 0 carries the sole listing-cover `Hero`.
class _ListingHeroCarousel extends StatefulWidget {
  const _ListingHeroCarousel({
    required this.listingId,
    this.listing,
    required this.urls,
    required this.heroFlightSourceTopRadius,
    this.flySourceKey,
    this.compareFlyFallbackKey,
    required this.onPageChanged,
  });

  final String listingId;
  final Listing? listing;
  final List<String> urls;
  final double heroFlightSourceTopRadius;
  final GlobalKey? flySourceKey;
  final GlobalKey? compareFlyFallbackKey;
  final ValueChanged<int> onPageChanged;

  @override
  State<_ListingHeroCarousel> createState() => _ListingHeroCarouselState();
}

class _ListingHeroCarouselState extends State<_ListingHeroCarousel> {
  late PageController _pageController = PageController(initialPage: 0);
  int _pageIndexVisual = 0;

  @override
  void didUpdateWidget(covariant _ListingHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _pageController.dispose();
      _pageController = PageController(initialPage: 0);
      _pageIndexVisual = 0;
      return;
    }
    if (_urlsListEquiv(widget.urls, oldWidget.urls)) return;
    final len = widget.urls.length;
    if (len == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      final maxIndex = len - 1;
      final raw = (_pageController.page ?? _pageIndexVisual.toDouble()).round();
      if (raw > maxIndex || raw < 0) {
        _pageController.jumpToPage(0);
        setState(() => _pageIndexVisual = 0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _heroStack({required Widget backdrop, Widget? pageDots}) {
    final stack = ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          backdrop,
          const _HeroScrim(),
          ...?_spreadOptionalTrailing(pageDots),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _HeroTopControls(
                listingId: widget.listingId,
                listing: widget.listing,
                flySourceKey: widget.flySourceKey,
                compareFlyFallbackKey: widget.compareFlyFallbackKey,
              ),
            ),
          ),
        ],
      ),
    );
    final key = widget.flySourceKey;
    if (key == null) return stack;
    return KeyedSubtree(key: key, child: stack);
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final tag = listingCoverHeroTag(widget.listingId);
    final rHero = widget.heroFlightSourceTopRadius;

    if (urls.isEmpty) {
      return _heroStack(
        backdrop: ListingCoverImage(
          imageUrl: null,
          heroTag: tag,
          heroFlightSourceTopRadius: rHero,
        ),
      );
    }

    final pageDots = urls.length > 1
        ? Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active =
                      i == _pageIndexVisual.clamp(0, urls.length - 1);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 7 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: active ? 0.95 : 0.35,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: active ? 0.35 : 0.22,
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          )
        : null;

    return _heroStack(
      pageDots: pageDots,
      backdrop: PageView.builder(
        controller: _pageController,
        itemCount: urls.length,
        onPageChanged: (i) {
          setState(() => _pageIndexVisual = i);
          widget.onPageChanged(i);
        },
        itemBuilder: (context, i) {
          final pageHeroTag = i == 0
              ? tag
              : listingDetailsGalleryHeroTag(widget.listingId, i);
          return GestureDetector(
            onTap: () => openListingDetailsFullscreenGallery(
              context,
              listingId: widget.listingId,
              urls: urls,
              initialIndex: i,
              heroFlightSourceTopRadius: rHero,
            ),
            behavior: HitTestBehavior.opaque,
            child: ListingCoverImage(
              imageUrl: urls[i],
              heroTag: pageHeroTag,
              heroFlightSourceTopRadius: rHero,
            ),
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0x52000000),
                    Color(0x00000000),
                    Color(0x38000000),
                  ]
                : const [Color(0x1F000000), Color(0x00000000)],
            stops: isDark ? const [0.0, 0.45, 1.0] : const [0.0, 0.35],
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
  const _HeroTopControls({
    required this.listingId,
    this.listing,
    this.flySourceKey,
    this.compareFlyFallbackKey,
  });

  final String listingId;
  final Listing? listing;
  final GlobalKey? flySourceKey;
  final GlobalKey? compareFlyFallbackKey;

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
          if (listing != null) ...[
            _HeroGlassTile(
              child: CompareToggleButton.fromListing(
                listing!,
                density: CompareToggleDensity.hero,
                flySourceKey: flySourceKey,
                flySourceFallbackKey: compareFlyFallbackKey,
              ),
            ),
            const SizedBox(width: 8),
          ],
          _HeroGlassTile(child: FavoriteToggleButton(listingId: listingId)),
        ],
      ),
    );
  }
}

/// Premium glass tile used for every hero-image overlay control.
///
/// Visual recipe:
///   * 40×40 rounded square, radius 12,
///   * light mode: translucent white fill (~72%) and hairline white border
///     so the icon reads over any photo without looking pasted-on,
///   * dark mode: frosted `surface` fill + `outline` border (no harsh white tile),
///   * backdrop blur behind the fill so the photo is softened,
///     which is the detail that makes it feel like glass,
///   * low-opacity elevation shadow for a subtle lift,
///   * `onSurface` icon theme at 20 px.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.94)
        : scheme.onSurface;
    final fillColor = isDark ? null : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.32)
        : Colors.white.withValues(alpha: 0.55);
    final shadowColor = isDark
        ? scheme.primary.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.18);
    final darkFill = isDark
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor, width: 0.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.16),
                  scheme.surfaceContainerHigh.withValues(alpha: 0.90),
                ),
                Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: 0.06),
                  scheme.surfaceContainerLow.withValues(alpha: 0.88),
                ),
              ],
            ),
          )
        : null;

    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isDark ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration:
                  darkFill ??
                  BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: borderColor, width: 0.5),
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
                value: formatKm(listing.mileageKm),
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
        if (_nonEmptyTrimmedDescription(listing) case final desc?) ...[
          const SizedBox(height: 28),
          _ListingDescriptionBlock(text: desc),
        ],
        const SizedBox(height: 24),
        if (listing.sellerId != null &&
            listing.sellerId!.trim().isNotEmpty) ...[
          SellerTrustSection(sellerId: listing.sellerId!.trim()),
        ],
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

/// Free-text seller description (shown only when non-empty).
class _ListingDescriptionBlock extends StatelessWidget {
  const _ListingDescriptionBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.listingDetailsDescriptionSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

/// Flat details list. Rows use editorial label/value layout; empty values omitted.
class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    bool hasValue(String v) => v.trim().isNotEmpty;

    final rows = <_DetailsRowData>[
      if (hasValue(listing.make))
        _DetailsRowData(l10n.listingFieldMake, listing.make.trim()),
      if (hasValue(listing.model))
        _DetailsRowData(l10n.listingFieldModel, listing.model.trim()),
      _DetailsRowData(l10n.listingFieldYear, listing.year.toString()),
      _DetailsRowData(l10n.listingFieldMileage, formatKm(listing.mileageKm)),
      _DetailsRowData(l10n.listingFieldType, formatType(l10n, listing.type)),
      if (listing.bodyType != null)
        _DetailsRowData(
          l10n.listingFieldBodyType,
          formatListingBodyType(l10n, listing.bodyType!),
        ),
      if (hasValue(listing.city))
        _DetailsRowData(l10n.listingFieldCity, listing.city.trim()),
      if (listing.fuelType != null)
        _DetailsRowData(
          l10n.listingFuelType,
          formatListingFuelType(l10n, listing.fuelType!),
        ),
      if (listing.engineDisplacementLiters != null)
        _DetailsRowData(
          l10n.listingEngineDisplacement,
          formatEngineDisplacementForDisplay(
            l10n,
            listing.engineDisplacementLiters,
          ),
        ),
      if (listing.enginePowerHp != null)
        _DetailsRowData(
          l10n.listingEnginePower,
          formatEnginePowerHpDisplay(l10n, listing.enginePowerHp),
        ),
      if (listing.drivetrain != null)
        _DetailsRowData(
          l10n.listingDrivetrain,
          formatListingDrivetrain(l10n, listing.drivetrain!),
        ),
      if (listing.registration != null &&
          listing.registration!.trim().isNotEmpty)
        _DetailsRowData(l10n.listingRegistration, listing.registration!.trim()),
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
        ListingDetailsVinEntry(listing: listing),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++)
          _ListingSpecRow(
            data: rows[i],
            showBottomDivider: i < rows.length - 1,
          ),
      ],
    );
  }
}

class _DetailsRowData {
  const _DetailsRowData(this.label, this.value);
  final String label;
  final String value;
}

/// Two-column spec row: muted label left, strong value right; optional
/// full-width row divider only (no label/value connector).
class _ListingSpecRow extends StatelessWidget {
  const _ListingSpecRow({required this.data, required this.showBottomDivider});

  final _DetailsRowData data;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dividerAlpha = isDark ? 0.26 : 0.16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 46,
                child: Text(
                  data.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.06,
                    height: 1.38,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 54,
                child: Text(
                  data.value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showBottomDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withValues(alpha: dividerAlpha),
          ),
      ],
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
    final waDigits = listing.whatsappEnabled
        ? whatsappDigits(listing.contactPhone)
        : null;

    final buttons = <Widget>[
      if (telegram != null && telegram.isNotEmpty)
        TextButton.icon(
          onPressed: () =>
              _launch(context, Uri.parse('https://t.me/$telegram')),
          icon: const Icon(CarzonIcons.send),
          label: Text(l10n.contactTelegram),
        ),
      if (waDigits != null)
        TextButton.icon(
          onPressed: () =>
              _launch(context, Uri.parse('https://wa.me/$waDigits')),
          icon: const WhatsappContactIcon(size: 20),
          label: Text(l10n.contactWhatsapp),
        ),
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 4, runSpacing: 4, children: buttons),
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

// Bottom contact bar (chat + phone reveal + copy).
class _ContactBottomBar extends StatefulWidget {
  const _ContactBottomBar({required this.listing});

  final Listing listing;

  @override
  State<_ContactBottomBar> createState() => _ContactBottomBarState();
}

class _ContactBottomBarState extends State<_ContactBottomBar> {
  bool _phoneRevealed = false;
  bool _openingChat = false;

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
      messenger.showSnackBar(SnackBar(content: Text(l10n.contactPhoneCopied)));
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.contactActionFailed)),
        );
      }
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.contactActionFailed)));
  }

  Future<void> _onChatTap(BuildContext context) async {
    final l10n = context.l10n;
    final auth = context.read<AuthCubit>().state;
    if (auth.status != AuthStatus.authenticated || auth.user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messagingSignInRequired),
          action: SnackBarAction(
            label: l10n.commonSignIn,
            onPressed: () => context.go(AppRoutes.signIn),
          ),
        ),
      );
      return;
    }
    final listing = widget.listing;
    if (listing.sellerId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.messagingUnavailableNoSeller)),
      );
      return;
    }
    if (listing.sellerId == auth.user!.id) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.messagingCannotMessageSelf)));
      return;
    }

    setState(() => _openingChat = true);
    try {
      final result = await context
          .read<ListingDetailsCubit>()
          .startConversationForListing(listing.id);
      if (!context.mounted) return;
      switch (result) {
        case FailureResult(:final failure):
          final kind = messagingFailureKindFrom(failure);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                messagingFailureMessage(l10n, kind, isSendAction: true),
              ),
            ),
          );
        case Success(:final value):
          await context.push(AppRoutes.messagesThreadPath(value));
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = widget.listing.contactPhone;
    final tel = telUriString(phone);
    final footerDecoration = AppTheme.editorialDarkFilterFooter(scheme);
    final divider = scheme.outlineVariant.withValues(alpha: 0.4);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration:
            footerDecoration ??
            BoxDecoration(
              color: scheme.surface,
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
                  _ChatPillButton(
                    loading: _openingChat,
                    onPressed: _openingChat ? null : () => _onChatTap(context),
                  ),
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
  const _ChatPillButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: _bottomButtonHeight,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onSurface,
                ),
              )
            : const Icon(CarzonIcons.chat, size: 20),
        label: Text(l10n.chatLabel),
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.10),
                  scheme.surfaceContainerHigh,
                )
              : scheme.surfaceContainerHighest.withValues(alpha: 0.9),
          foregroundColor: scheme.onSurface.withValues(
            alpha: isDark ? 0.94 : 1,
          ),
          side: isDark
              ? BorderSide(color: scheme.outline.withValues(alpha: 0.28))
              : null,
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

    ButtonStyle buttonStyle({bool disabled = false}) => FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: _bottomButtonShape(),
      backgroundColor: disabled ? theme.colorScheme.surfaceContainerHigh : null,
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
              _InlineCopyAction(tooltip: l10n.contactCopyPhone, onTap: onCopy!),
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
