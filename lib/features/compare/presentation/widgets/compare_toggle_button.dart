import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/compare_listing_snapshot.dart';
import '../cubit/compare_cubit.dart';
import '../cubit/compare_state.dart';
import '../utils/compare_fly_to_tray_runner.dart';
import '../utils/compare_tray_feedback_runner.dart';
import '../utils/compare_tray_layout.dart';

/// Visual density for [CompareToggleButton] (card vs details hero).
enum CompareToggleDensity { compact, hero }

/// Toggles a listing in the local compare set (no auth, no navigation).
class CompareToggleButton extends StatelessWidget {
  const CompareToggleButton({
    super.key,
    required this.listingId,
    this.listing,
    this.density = CompareToggleDensity.compact,
    this.flySourceKey,
    this.flySourceFallbackKey,
    this.flyToTrayEnabled = true,
  });

  /// Creates a button from a full [Listing] (preferred for add snapshot).
  factory CompareToggleButton.fromListing(
    Listing listing, {
    Key? key,
    CompareToggleDensity density = CompareToggleDensity.compact,
    GlobalKey? flySourceKey,
    GlobalKey? flySourceFallbackKey,
    bool flyToTrayEnabled = true,
  }) {
    return CompareToggleButton(
      key: key,
      listingId: listing.id,
      listing: listing,
      density: density,
      flySourceKey: flySourceKey,
      flySourceFallbackKey: flySourceFallbackKey,
      flyToTrayEnabled: flyToTrayEnabled,
    );
  }

  final String listingId;
  final Listing? listing;
  final CompareToggleDensity density;

  /// Primary fly source (e.g. listing card cover or details hero).
  final GlobalKey? flySourceKey;

  /// Used when [flySourceKey] is not measurable (e.g. details compare button).
  final GlobalKey? flySourceFallbackKey;

  /// When false, add still works but no fly animation is requested.
  final bool flyToTrayEnabled;

  bool _shouldRequestFlyAnimation(BuildContext context) {
    if (!flyToTrayEnabled) return false;
    if (flySourceKey == null && flySourceFallbackKey == null) return false;
    final router = GoRouter.maybeOf(context);
    if (router == null) return false;
    final location =
        router.routerDelegate.currentConfiguration.uri.toString();
    return !compareTrayHiddenForRoute(location);
  }

  Future<void> _handleTap(BuildContext context) async {
    final cubit = context.read<CompareCubit>();
    final state = cubit.state;
    final inCompare = state.containsListing(listingId);

    if (inCompare) {
      await cubit.remove(listingId);
      return;
    }

    if (state.isFull) {
      showCompareTrayMaxLimitFeedback(context: context);
      return;
    }

    final snap = listing != null
        ? CompareListingSnapshot.fromListing(listing!)
        : CompareListingSnapshot(
            listingId: listingId,
            addedAt: DateTime.now().toUtc(),
          );

    final countBefore = state.count;
    await cubit.addSnapshot(snap);
    if (!context.mounted) return;

    final itemWasAdded = cubit.state.count > countBefore;
    if (_shouldRequestFlyAnimation(context) && itemWasAdded) {
      requestCompareFlyToTray(
        context: context,
        sourceKey: flySourceKey,
        sourceFallbackKey: flySourceFallbackKey,
        imageUrl: snap.coverImageUrl ?? listing?.coverImageUrl,
        itemWasAdded: true,
        trayWasHiddenBeforeAdd: countBefore == 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isHero = density == CompareToggleDensity.hero;
    final iconSize = isHero ? 20.0 : 18.0;
    final minSide = isHero ? 40.0 : 36.0;

    return BlocBuilder<CompareCubit, CompareState>(
      buildWhen: (prev, curr) =>
          prev.containsListing(listingId) != curr.containsListing(listingId) ||
          prev.count != curr.count,
      builder: (context, state) {
        final selected = state.containsListing(listingId);
        final canAdd = listing != null || selected;
        final muted = scheme.onSurface.withValues(alpha: 0.88);
        final selectedColor = scheme.primary;
        final iconColor = selected ? selectedColor : muted;

        return IconButton(
          key: ValueKey('compare_toggle_$listingId'),
          tooltip: selected ? l10n.compareRemoveTooltip : l10n.compareAddTooltip,
          constraints: BoxConstraints(minWidth: minSide, minHeight: minSide),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: iconColor,
            disabledForegroundColor: muted.withValues(alpha: 0.45),
          ),
          onPressed: canAdd ? () => _handleTap(context) : null,
          icon: Padding(
            padding: const EdgeInsets.all(2),
            child: selected
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(isHero ? 8 : 6),
                    ),
                    child: Icon(
                      CarzonIcons.compare,
                      size: iconSize,
                      color: iconColor,
                    ),
                  )
                : Icon(
                    CarzonIcons.compare,
                    size: iconSize,
                    color: iconColor,
                  ),
          ),
        );
      },
    );
  }
}
