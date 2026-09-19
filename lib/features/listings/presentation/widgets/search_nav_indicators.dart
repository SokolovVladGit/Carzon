import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../data/local/last_applied_listing_discovery_repository.dart';
import '../../domain/listing_discovery_state_sync.dart';
import '../bloc/listings_bloc.dart';
import '../bloc/listings_state.dart';
import '../cubit/browse_catalog_filter_alerts_cubit.dart';
import '../utils/discovery_feed_chip_labels.dart';
import 'filters/catalog_filter_alert_ui_constants.dart';

/// Applied-discovery snapshot used only to paint Search-tab chrome.
class SearchNavIndicatorData {
  const SearchNavIndicatorData({required this.active, required this.bell});

  final bool active;
  final bool bell;

  String semanticsLabel(BuildContext context) {
    final l10n = context.l10n;
    if (active && bell) return l10n.navSearchFiltersAndAlertsSemantics;
    if (active) return l10n.navSearchFiltersActiveSemantics;
    if (bell) return l10n.navSearchAlertsEnabledSemantics;
    return l10n.navListings;
  }
}

SearchNavIndicatorData resolveSearchNavIndicatorData({
  required ListingsState applied,
  required BrowseCatalogFilterAlertsCubit alerts,
}) {
  return SearchNavIndicatorData(
    active: listingsDiscoveryActiveFilterGroupCount(applied) > 0,
    bell: alerts.catalogBellBadgeVisibleForApplied(applied),
  );
}

class SearchNavIndicatorScope extends StatefulWidget {
  const SearchNavIndicatorScope({super.key, required this.child});

  final Widget child;

  static SearchNavIndicatorData of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_SearchNavIndicatorInherited>()
            ?.data ??
        const SearchNavIndicatorData(active: false, bell: false);
  }

  @override
  State<SearchNavIndicatorScope> createState() =>
      _SearchNavIndicatorScopeState();
}

class _SearchNavIndicatorScopeState extends State<SearchNavIndicatorScope> {
  ListingsState? _storedApplied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hydrateStored());
    });
  }

  ListingsBloc? _liveListingsBloc() {
    try {
      return BlocProvider.of<ListingsBloc>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _hydrateStored() async {
    if (!mounted) return;
    if (_liveListingsBloc() != null) return;
    if (!sl.isRegistered<LastAppliedListingDiscoveryRepository>()) return;
    final local = await sl<LastAppliedListingDiscoveryRepository>().load();
    if (!mounted) return;
    setState(() {
      _storedApplied = local == null
          ? const ListingsState()
          : listingsStateFromDiscoveryCriteria(local);
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveBloc = _liveListingsBloc();
    final alerts = sl.isRegistered<BrowseCatalogFilterAlertsCubit>()
        ? sl<BrowseCatalogFilterAlertsCubit>()
        : null;

    Widget wrap(SearchNavIndicatorData data) {
      return _SearchNavIndicatorInherited(data: data, child: widget.child);
    }

    if (alerts == null) {
      return wrap(const SearchNavIndicatorData(active: false, bell: false));
    }

    return BlocProvider<BrowseCatalogFilterAlertsCubit>.value(
      value: alerts,
      child:
          BlocBuilder<
            BrowseCatalogFilterAlertsCubit,
            BrowseCatalogFilterAlertsState
          >(
            builder: (context, _) {
              if (liveBloc != null) {
                return BlocBuilder<ListingsBloc, ListingsState>(
                  bloc: liveBloc,
                  builder: (context, state) {
                    return wrap(
                      resolveSearchNavIndicatorData(
                        applied: state,
                        alerts: alerts,
                      ),
                    );
                  },
                );
              }
              final stored = _storedApplied ?? const ListingsState();
              return wrap(
                resolveSearchNavIndicatorData(applied: stored, alerts: alerts),
              );
            },
          ),
    );
  }
}

class _SearchNavIndicatorInherited extends InheritedWidget {
  const _SearchNavIndicatorInherited({
    required this.data,
    required super.child,
  });

  final SearchNavIndicatorData data;

  @override
  bool updateShouldNotify(_SearchNavIndicatorInherited oldWidget) {
    return data.active != oldWidget.data.active ||
        data.bell != oldWidget.data.bell;
  }
}

/// Corner badges for the Search capsule item. IgnorePointer — tap opens Search.
class SearchNavIconOverlay extends StatelessWidget {
  const SearchNavIconOverlay({super.key});

  static const Key activeCheckKey = ValueKey<Object>(
    'search_nav_active_filter_check',
  );

  @override
  Widget build(BuildContext context) {
    final data = SearchNavIndicatorScope.of(context);
    if (!data.active && !data.bell) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final outline = Theme.of(context).brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : Colors.white;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (data.active)
            Positioned(
              top: 2,
              right: 2,
              child: _SearchNavCornerBadge(
                ornamentKey: activeCheckKey,
                background: scheme.primary,
                outline: outline,
                icon: Icons.check,
                iconColor: scheme.onPrimary,
              ),
            ),
          if (data.bell)
            Positioned(
              bottom: 2,
              right: 2,
              child: _SearchNavCornerBadge(
                ornamentKey:
                    CatalogFilterAlertAccent.discoveryFilterFABAlertBellKey,
                background: CatalogFilterAlertAccent.amber,
                outline: outline,
                icon: Icons.notifications,
                iconColor: scheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchNavCornerBadge extends StatelessWidget {
  const _SearchNavCornerBadge({
    this.ornamentKey,
    required this.background,
    required this.outline,
    required this.icon,
    required this.iconColor,
  });

  final Key? ornamentKey;
  final Color background;
  final Color outline;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: outline, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, key: ornamentKey, size: 8, color: iconColor),
        ),
      ),
    );
  }
}
