import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import 'create_listing_compose_layout.dart';

/// Collapsed technical facts. Presentation only: never invents a value.
///
/// Takes the first four real facts in priority order: body, engine,
/// drivetrain, transmission, power, fuel, year, registration. Fuel leaves
/// the engine line only when it is one of those four cells.
List<CreateListingCharacteristicFact> buildCreateListingTechnicalFacts(
  AppLocalizations l10n, {
  ListingBodyType? bodyType,
  double? displacementLiters,
  ListingFuelType? fuelType,
  ListingDrivetrain? drivetrain,
  ListingTransmissionType? transmissionType,
  int? powerHp,
  int? year,
  String? registration,
}) {
  final fuelText = fuelType == null
      ? null
      : formatListingFuelType(l10n, fuelType);
  final displacementText = displacementLiters == null
      ? null
      : formatEngineDisplacementForDisplay(l10n, displacementLiters);
  final displacementShown = displacementText == null || displacementText.isEmpty
      ? null
      : displacementText;
  final registrationText = registration?.trim();
  final registrationShown = registrationText == null || registrationText.isEmpty
      ? null
      : registrationText;

  final slots = <({bool engine, CreateListingCharacteristicFact fact})>[
    if (bodyType != null)
      (
        engine: false,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconBody,
          label: l10n.listingFieldBodyType,
          value: formatListingBodyType(l10n, bodyType),
        ),
      ),
    if (displacementShown != null)
      (
        engine: true,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconEngine,
          label: l10n.compareRowEngine,
          value: displacementShown,
        ),
      ),
    if (drivetrain != null)
      (
        engine: false,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconDrivetrain,
          label: l10n.compareRowDrivetrain,
          value: formatListingDrivetrain(l10n, drivetrain),
        ),
      ),
    if (transmissionType != null)
      (
        engine: false,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconTransmission,
          label: l10n.compareRowTransmission,
          value: formatListingTransmissionType(l10n, transmissionType),
        ),
      ),
    if (powerHp != null)
      (
        engine: false,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconPower,
          label: l10n.compareRowPower,
          value: formatEnginePowerHpDisplay(l10n, powerHp),
        ),
      ),
    if (fuelText != null)
      (
        engine: false,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconFuel,
          label: l10n.listingFuelType,
          value: fuelText,
        ),
      ),
    if (year != null)
      (
        engine: false,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconYear,
          label: l10n.compareRowYear,
          value: '$year',
        ),
      ),
    if (registrationShown != null)
      (
        engine: false,
        fact: CreateListingCharacteristicFact(
          icon: kCreateListingIconRegistration,
          label: l10n.compareRowRegistration,
          value: registrationShown,
        ),
      ),
  ];

  final selected = slots.take(4).toList();
  final fuelKept = selected.any(
    (slot) => slot.fact.label == l10n.listingFuelType,
  );
  if (!fuelKept && fuelText != null) {
    final engineIndex = selected.indexWhere((slot) => slot.engine);
    if (engineIndex >= 0) {
      final engine = selected[engineIndex].fact;
      selected[engineIndex] = (
        engine: true,
        fact: CreateListingCharacteristicFact(
          icon: engine.icon,
          label: engine.label,
          value: '${engine.value} · $fuelText',
        ),
      );
    }
  }

  return [for (final slot in selected) slot.fact];
}

/// Two-column characteristics summary. Empty facts render nothing.
class CreateListingCharacteristicsFacts extends StatelessWidget {
  const CreateListingCharacteristicsFacts({super.key, required this.facts});

  static const Key summaryKey = ValueKey(
    'create_listing_characteristics_summary',
  );

  static const double _gap = 6;

  /// Below this width the cells stack. 320pt content still stays two columns.
  static const double _stackBelow = 240;

  final List<CreateListingCharacteristicFact> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      key: summaryKey,
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < _stackBelow;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < facts.length; i++) ...[
                if (i > 0) const SizedBox(height: _gap),
                _FactCell(fact: facts[i], theme: theme, cs: cs),
              ],
            ],
          );
        }
        final cellWidth = (constraints.maxWidth - _gap) / 2;
        final cellHeight = _tallestFactCellHeight(
          context,
          facts: facts,
          width: cellWidth,
          theme: theme,
          cs: cs,
        );
        final rowCount = (facts.length + 1) ~/ 2;
        return Column(
          children: [
            for (var row = 0; row < rowCount; row++) ...[
              if (row > 0) const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FactCell(
                      fact: facts[row * 2],
                      theme: theme,
                      cs: cs,
                      height: cellHeight,
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: row * 2 + 1 < facts.length
                        ? _FactCell(
                            fact: facts[row * 2 + 1],
                            theme: theme,
                            cs: cs,
                            height: cellHeight,
                          )
                        : SizedBox(height: cellHeight),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class CreateListingCharacteristicFact {
  const CreateListingCharacteristicFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _FactCell extends StatelessWidget {
  const _FactCell({
    required this.fact,
    required this.theme,
    required this.cs,
    this.height,
  });

  final CreateListingCharacteristicFact fact;
  final ThemeData theme;
  final ColorScheme cs;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: createListingFactSurfaceDecoration(theme),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CreateListingFactIconChip(icon: fact.icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fact.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _factLabelStyle(theme, cs),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                fact.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _factValueStyle(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _factLabelStyle(ThemeData theme, ColorScheme cs) {
  return theme.textTheme.labelSmall?.copyWith(
        color: cs.onSurface.withValues(
          alpha: theme.brightness == Brightness.light ? 0.52 : 0.66,
        ),
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 1.1,
      ) ??
      const TextStyle(fontSize: 11, height: 1.1, fontWeight: FontWeight.w600);
}

TextStyle _factValueStyle(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        letterSpacing: -0.2,
        height: 1.15,
        color: theme.colorScheme.onSurface.withValues(alpha: light ? 1 : 0.98),
      ) ??
      const TextStyle(fontSize: 14, height: 1.15, fontWeight: FontWeight.w700);
}

double _tallestFactCellHeight(
  BuildContext context, {
  required List<CreateListingCharacteristicFact> facts,
  required double width,
  required ThemeData theme,
  required ColorScheme cs,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final inner = width - 16;
  final labelWidth = inner - kCreateListingFactIconChipExtent - 8;
  var tallest = 0.0;
  for (final fact in facts) {
    final label = TextPainter(
      text: TextSpan(text: fact.label, style: _factLabelStyle(theme, cs)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: labelWidth);
    final value = TextPainter(
      text: TextSpan(text: fact.value, style: _factValueStyle(theme)),
      maxLines: 2,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: inner);
    final height =
        16 +
        (label.height > kCreateListingFactIconChipExtent
            ? label.height
            : kCreateListingFactIconChipExtent) +
        4 +
        value.height;
    if (height > tallest) tallest = height;
  }
  return tallest;
}
