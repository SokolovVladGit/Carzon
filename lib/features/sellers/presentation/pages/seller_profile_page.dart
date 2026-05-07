import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return BlocBuilder<SellerProfileCubit, SellerProfileState>(
      builder: (context, state) {
        if (state.isInitialSkeleton) {
          return Scaffold(
            backgroundColor: scheme.surface,
            appBar: AppBar(
              leading: const AppBackButton(),
              title: Text(l10n.sellerProfileTitle),
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              foregroundColor: scheme.onSurface,
              systemOverlayStyle: scheme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
            ),
            body: const Center(child: LoadingView()),
          );
        }

        if (state.profileFailure != null) {
          return Scaffold(
            backgroundColor: scheme.surface,
            appBar: AppBar(
              leading: const AppBackButton(),
              title: Text(l10n.sellerProfileTitle),
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              foregroundColor: scheme.onSurface,
              systemOverlayStyle: scheme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
            ),
            body: ErrorView(
              message: l10n.sellerProfileLoadFailed,
              onRetry: () => context.read<SellerProfileCubit>().retry(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            leading: const AppBackButton(),
            title: Text(l10n.sellerProfileTitle),
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            systemOverlayStyle: scheme.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<SellerProfileCubit>().load(),
            color: scheme.primary,
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
                    child: Text(
                      l10n.sellerListingsSectionTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.08,
                      ),
                    ),
                  ),
                ),
                if (state.listingsLoading && state.listings.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: LoadingView()),
                    ),
                  )
                else if (state.listingsFailure != null &&
                    state.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.sellerListingsLoadFailed,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.read<SellerProfileCubit>().retry(),
                            child: Text(l10n.commonRetry),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!state.listingsLoading &&
                    state.listings.isEmpty &&
                    state.listingsFailure == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.sellerNoActiveListingsTitle,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.sellerNoActiveListingsMessage,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.92,
                                  ),
                                  height: 1.35,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
                            ? const SizedBox(
                                height: 36,
                                width: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () => context
                                    .read<SellerProfileCubit>()
                                    .loadMoreListings(),
                                child: Text(l10n.sellerLoadMore),
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
