import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/fuel_price_snapshot.dart';
import '../cubit/fuel_prices_cubit.dart';
import 'fuel_prices_board.dart';
import 'fuel_prices_territory_control.dart';

/// Territory tabs and price board as one connected editorial module.
class FuelPricesBoardModule extends StatelessWidget {
  const FuelPricesBoardModule({
    super.key,
    required this.selected,
    required this.onTerritoryChanged,
    this.snapshot,
  });

  final FuelPricesTerritory selected;
  final ValueChanged<FuelPricesTerritory> onTerritoryChanged;
  final FuelPriceSnapshot? snapshot;

  static const double _moduleRadius = 22;

  bool get _hasBoard => snapshot != null && snapshot!.isAvailable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(
      _hasBoard ? _moduleRadius : FuelPricesTerritoryControl.trackRadius,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.17),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.035),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -4,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.editorialModuleAtmosphereWash(scheme),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 132,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.editorialModuleAtmosphereHighlight(scheme),
                  ),
                ),
              ),
            ),
            Column(
              key: const ValueKey<String>('fuel_prices_board_module'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FuelPricesTerritoryControl(
                  selected: selected,
                  onChanged: onTerritoryChanged,
                  connectToBoard: _hasBoard,
                ),
                if (_hasBoard) FuelPricesBoard(snapshot: snapshot!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
