import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../cubit/fuel_prices_cubit.dart';
import '../widgets/fuel_prices_board.dart';
import '../widgets/fuel_prices_disclaimer_callout.dart';
import '../widgets/fuel_prices_metadata_footer.dart';
import '../widgets/fuel_prices_territory_control.dart';

/// Utility screen for Moldova and PMR fuel price reference boards.
class FuelPricesPage extends StatelessWidget {
  const FuelPricesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FuelPricesCubit(getFuelPricesForApp: sl())..load(),
      child: const FuelPricesChrome(),
    );
  }
}

@visibleForTesting
Widget fuelPricesTestHarness({
  required FuelPricesCubit cubit,
  required Widget child,
}) {
  return BlocProvider<FuelPricesCubit>.value(
    value: cubit,
    child: child,
  );
}

@visibleForTesting
class FuelPricesChrome extends StatelessWidget {
  const FuelPricesChrome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _fuelPricesPageBackground(context),
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.menu),
        title: Text(l10n.fuelPricesTitle),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _fuelPricesCanvasGradient(context),
            stops: const [0, 0.42, 1],
          ),
        ),
        child: BlocBuilder<FuelPricesCubit, FuelPricesState>(
          builder: (context, state) {
            return switch (state.phase) {
              FuelPricesLoadPhase.initial ||
              FuelPricesLoadPhase.loading => const LoadingView(),
              FuelPricesLoadPhase.failure => ErrorView(
                message: l10n.fuelPricesLoadFailed,
                onRetry: () => context.read<FuelPricesCubit>().load(),
              ),
              FuelPricesLoadPhase.ready => FuelPricesBody(state: state),
            };
          },
        ),
      ),
    );
  }
}

class FuelPricesBody extends StatelessWidget {
  const FuelPricesBody({super.key, required this.state});

  final FuelPricesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final snapshot = state.selectedSnapshot;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottomInset),
      children: [
        const FuelPricesDisclaimerCallout(),
        const SizedBox(height: 20),
        FuelPricesTerritoryControl(
          selected: state.selectedTerritory,
          onChanged: context.read<FuelPricesCubit>().selectTerritory,
        ),
        const SizedBox(height: 20),
        if (snapshot == null || !snapshot.isAvailable)
          EmptyStateView(
            icon: Icons.local_gas_station_outlined,
            title: l10n.fuelPricesEmpty,
            body: l10n.fuelPricesTerritoryUnavailable,
            expand: false,
            primaryAction: EmptyStateAction(
              label: l10n.commonRetry,
              onPressed: () => context.read<FuelPricesCubit>().load(),
            ),
          )
        else ...[
          FuelPricesBoard(snapshot: snapshot),
          const SizedBox(height: 16),
          FuelPricesMetadataFooter(snapshot: snapshot),
        ],
      ],
    );
  }
}

Color _fuelPricesPageBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.050),
      scheme.surface,
    );
  }
  return scheme.surface;
}

List<Color> _fuelPricesCanvasGradient(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    return AppTheme.editorialDarkFilterCanvasGradient(scheme);
  }
  return [
    scheme.surface,
    Color.alphaBlend(scheme.primary.withValues(alpha: 0.035), scheme.surface),
    scheme.surfaceContainerLowest,
  ];
}
