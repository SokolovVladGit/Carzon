import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../listings/presentation/widgets/listing_card.dart';
import '../../../listings/presentation/widgets/listing_tile.dart';
import '../bloc/seller_profile_cubit.dart';
import '../bloc/seller_profile_state.dart';
import '../widgets/seller_profile_header_card.dart';

/// Public seller profile: identity header + first page of active listings.
class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({super.key, required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SellerProfileCubit(
        getSellerPublicProfile: sl(),
        getListings: sl(),
        sellerId: sellerId,
      )..load(),
      child: const _SellerProfileView(),
    );
  }
}

class _SellerProfileView extends StatelessWidget {
  const _SellerProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<SellerProfileCubit, SellerProfileState>(
      builder: (context, state) {
        if (state.isInitialSkeleton) {
          return _SellerProfileScaffold(
            body: const _SellerProfilePageLoadingBody(),
          );
        }

        if (state.profileFailure != null) {
          return _SellerProfileScaffold(
            body: _SellerProfilePageFailureBody(
              message: l10n.sellerProfileLoadFailed,
              onRetry: () => context.read<SellerProfileCubit>().retry(),
            ),
          );
        }

        return _SellerProfileScaffold(
          body: RefreshIndicator(
            onRefresh: () => context.read<SellerProfileCubit>().load(),
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: state.showProfileUnavailable
                      ? SellerProfileHeaderCard.unavailable()
                      : SellerProfileHeaderCard.loaded(profile: state.profile!),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: _SellerListingsSectionTitle(
                      title: l10n.sellerListingsSectionTitle,
                    ),
                  ),
                ),
                if (state.listingsLoading && state.listings.isEmpty)
                  const SliverToBoxAdapter(
                    child: _SellerProfileListingsLoadingBody(),
                  )
                else if (state.listingsFailure != null &&
                    state.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: _SellerProfileListingsFailureBody(
                      message: l10n.sellerListingsLoadFailed,
                      onRetry: () => context.read<SellerProfileCubit>().retry(),
                    ),
                  )
                else if (!state.listingsLoading &&
                    state.listings.isEmpty &&
                    state.listingsFailure == null)
                  SliverToBoxAdapter(
                    child: _SellerProfileListingsEmptyBody(
                      title: l10n.sellerNoActiveListingsTitle,
                      message: l10n.sellerNoActiveListingsMessage,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final listing = state.listings[index];
                        return ListingTile(
                          listing: listing,
                          onTap: () => context.push(
                            AppRoutes.listingDetailsPath(listing.id),
                            extra: ListingDetailsExtra(
                              coverImageUrl: listing.coverImageUrl,
                              coverHeroFlightTopRadius:
                                  ListingCard.coverHeroFlightTopRadius(
                                    ListingCardVariant.regular,
                                  ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemCount: state.listings.length,
                    ),
                  ),
                if (state.hasMoreListings &&
                    state.listings.isNotEmpty &&
                    state.listingsFailure == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Center(
                        child: state.loadingMoreListings
                            ? const _SellerProfileLoadMoreSpinner()
                            : _SellerProfileLoadMoreButton(
                                label: l10n.sellerLoadMore,
                                onPressed: () => context
                                    .read<SellerProfileCubit>()
                                    .loadMoreListings(),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SellerProfileScaffold extends StatelessWidget {
  const _SellerProfileScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: isDark ? null : scheme.surface,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.sellerProfileTitle),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? Colors.transparent : scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: isDark
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.editorialDarkFilterCanvasGradient(scheme),
                  stops: const [0, 0.35, 1],
                ),
              ),
              child: body,
            )
          : body,
    );
  }
}

class _SellerProfilePageLoadingBody extends StatelessWidget {
  const _SellerProfilePageLoadingBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (theme.brightness == Brightness.light) {
      return const Center(child: LoadingView());
    }
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.editorialAccentColor(scheme),
        strokeWidth: 2.5,
      ),
    );
  }
}

class _SellerProfilePageFailureBody extends StatelessWidget {
  const _SellerProfilePageFailureBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = ErrorView(message: message, onRetry: onRetry);
    if (theme.brightness == Brightness.light) {
      return Center(child: error);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _SellerProfileEditorialInset(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            child: error,
          ),
        ),
      ),
    );
  }
}

class _SellerListingsSectionTitle extends StatelessWidget {
  const _SellerListingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.08,
        color: theme.brightness == Brightness.dark
            ? scheme.onSurface.withValues(alpha: 0.96)
            : null,
      ),
    );
  }
}

class _SellerProfileListingsLoadingBody extends StatelessWidget {
  const _SellerProfileListingsLoadingBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final indicator = theme.brightness == Brightness.dark
        ? CircularProgressIndicator(
            color: AppTheme.editorialAccentColor(scheme),
            strokeWidth: 2.5,
          )
        : const LoadingView();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: indicator),
    );
  }
}

class _SellerProfileListingsFailureBody extends StatelessWidget {
  const _SellerProfileListingsFailureBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.84 : 0.9,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onRetry,
          style: isDark
              ? FilledButton.styleFrom(
                  backgroundColor: Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.12),
                    scheme.surfaceContainerHigh,
                  ),
                  foregroundColor: scheme.onSurface.withValues(alpha: 0.94),
                  side: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.28),
                  ),
                )
              : null,
          child: Text(context.l10n.commonRetry),
        ),
      ],
    );

    if (!isDark) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: _SellerProfileEditorialInset(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: content,
      ),
    );
  }
}

class _SellerProfileListingsEmptyBody extends StatelessWidget {
  const _SellerProfileListingsEmptyBody({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      children: [
        if (isDark) ...[
          Icon(
            CarzonIcons.inventoryEmpty,
            size: 32,
            color: AppTheme.editorialAccentColor(
              scheme,
            ).withValues(alpha: 0.72),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? scheme.onSurface.withValues(alpha: 0.94) : null,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.82 : 0.92,
            ),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (!isDark) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: _SellerProfileEditorialInset(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: content,
      ),
    );
  }
}

class _SellerProfileLoadMoreSpinner extends StatelessWidget {
  const _SellerProfileLoadMoreSpinner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 36,
      width: 36,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: isDark ? AppTheme.editorialAccentColor(scheme) : null,
      ),
    );
  }
}

class _SellerProfileLoadMoreButton extends StatelessWidget {
  const _SellerProfileLoadMoreButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: onPressed,
      style: isDark
          ? OutlinedButton.styleFrom(
              foregroundColor: scheme.onSurface.withValues(alpha: 0.92),
              side: BorderSide(
                color: AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: 0.38),
              ),
            )
          : null,
      child: Text(label),
    );
  }
}

/// Lifted charcoal inset used for seller-profile empty/error blocks in dark mode.
class _SellerProfileEditorialInset extends StatelessWidget {
  const _SellerProfileEditorialInset({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decoration = AppTheme.editorialDarkSectionCard(
      scheme,
      borderRadius: 16,
    );
    return DecoratedBox(
      decoration: decoration!,
      child: Padding(padding: padding, child: child),
    );
  }
}
