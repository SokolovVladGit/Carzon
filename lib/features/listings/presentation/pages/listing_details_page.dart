import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/presentation/localized_user_failure_message.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/listing_details_cubit.dart';
import '../bloc/listing_details_state.dart';
import '../utils/listing_details_uri_launcher.dart';
import '../widgets/listing_details_contact_bar.dart';
import '../widgets/listing_details_content_panel.dart';
import '../widgets/listing_details_hero.dart';

/// Fixed height of the hero image section. Taller than the old
/// overlay-heavy hero so the photo feels like a proper showcase
/// while still leaving the below-panel header visible above the
/// fold on a standard 5.5" device.
const double _heroHeight = 380;

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
                          child: ListingHeroCarousel(
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
                            return const LoadingBelowHero();
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
                            return FailureBelowHero(
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
                            return SuccessBelowHero(
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
                    return ListingDetailsContactBar(listing: state.listing!);
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
