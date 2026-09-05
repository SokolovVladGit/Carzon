import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/compare_resolved_slot.dart';
import '../models/compare_spec_models.dart';
import 'compare_spec_formatters.dart';

/// Builds grouped compare spec sections from resolved vehicle columns.
class CompareSpecBuilder {
  CompareSpecBuilder(this.l10n, this.slots)
    : _fmt = CompareSpecFormatters(l10n);

  final AppLocalizations l10n;
  final List<CompareResolvedSlot> slots;
  final CompareSpecFormatters _fmt;

  List<CompareSpecSection> buildSections() {
    return [
      CompareSpecSection(
        title: l10n.compareSectionPriceBasics,
        rows: [
          _row(
            'price',
            l10n.compareRowPrice,
            _priceValues(),
            _lowestIndices(slots.map((s) => s.listing?.priceEur).toList()),
          ),
          _row(
            'year',
            l10n.compareRowYear,
            _yearValues(),
            _lowestIndices(
              slots.map((s) {
                final y = s.listing?.year ?? s.item.snapshot.year;
                return y == null ? null : -y;
              }).toList(),
            ),
          ),
          _row(
            'mileage',
            l10n.compareRowMileage,
            _mileageValues(),
            _lowestIndices(slots.map((s) => s.listing?.mileageKm).toList()),
          ),
          _row('city', l10n.compareRowCityRegion, _cityValues()),
          _row('status', l10n.compareRowStatus, _statusValues()),
        ],
      ),
      CompareSpecSection(
        title: l10n.compareSectionVehicle,
        rows: [
          _row('make', l10n.compareRowMake, _makeValues()),
          _row('model', l10n.compareRowModel, _modelValues()),
          _row('variant', l10n.compareRowVariant, _variantValues()),
          _row('body', l10n.compareRowBody, _bodyValues()),
          _row('type', l10n.compareRowVehicleType, _vehicleTypeValues()),
          _row(
            'registration',
            l10n.compareRowRegistration,
            _registrationValues(),
          ),
        ],
      ),
      CompareSpecSection(
        title: l10n.compareSectionSpecs,
        rows: [
          _row('fuel', l10n.compareRowFuel, _fuelValues()),
          _row('engine', l10n.compareRowEngine, _engineValues()),
          _row('power', l10n.compareRowPower, _powerValues()),
          _row('drivetrain', l10n.compareRowDrivetrain, _drivetrainValues()),
          _row(
            'transmission',
            l10n.compareRowTransmission,
            _transmissionValues(),
          ),
          _row(
            'displacement',
            l10n.compareRowDisplacement,
            _displacementValues(),
          ),
        ],
      ),
      CompareSpecSection(
        title: l10n.compareSectionTrustData,
        rows: [
          _row('vin', l10n.compareRowVin, _vinValues()),
          _row('photos', l10n.compareRowPhotos, _photoValues()),
          _row('published', l10n.compareRowPublishedAt, _publishedValues()),
        ],
      ),
    ];
  }

  CompareSpecRow _row(
    String id,
    String label,
    List<String> values, [
    Set<int> highlightIndices = const {},
  ]) {
    return CompareSpecRow(
      id: id,
      label: label,
      values: values,
      highlightIndices: highlightIndices,
    );
  }

  List<String> _priceValues() => slots.map((slot) {
    if (slot.phase == CompareSlotPhase.unavailable) {
      return CompareSpecFormatters.missing;
    }
    if (slot.listing != null) {
      return _fmt.formatPriceFromListing(slot.listing!);
    }
    return _fmt.formatPriceFromSnapshot(slot.item.snapshot);
  }).toList();

  List<String> _yearValues() => slots.map((slot) {
    if (slot.phase == CompareSlotPhase.unavailable) {
      return CompareSpecFormatters.missing;
    }
    return _fmt.formatYear(slot.listing, slot.item.snapshot);
  }).toList();

  List<String> _mileageValues() => slots.map((slot) {
    if (slot.phase == CompareSlotPhase.unavailable) {
      return CompareSpecFormatters.missing;
    }
    return _fmt.formatMileage(slot.listing);
  }).toList();

  List<String> _cityValues() => slots.map((slot) {
    if (slot.phase == CompareSlotPhase.unavailable) {
      return CompareSpecFormatters.missing;
    }
    return _fmt.formatCityRegion(slot);
  }).toList();

  List<String> _statusValues() => slots.map((slot) {
    if (slot.phase == CompareSlotPhase.unavailable) {
      return CompareSpecFormatters.missing;
    }
    if (slot.phase == CompareSlotPhase.inactive) {
      return l10n.compareInactiveListing;
    }
    return _fmt.formatListingStatus(slot.listing);
  }).toList();

  List<String> _makeValues() => _snapshotAware(
    (slot) => _fmt.formatMake(slot.listing, slot.item.snapshot),
  );

  List<String> _modelValues() => _snapshotAware(
    (slot) => _fmt.formatModel(slot.listing, slot.item.snapshot),
  );

  List<String> _variantValues() =>
      _listingOnly((slot) => _fmt.formatVariant(slot.listing));

  List<String> _bodyValues() =>
      _listingOnly((slot) => _fmt.formatBody(slot.listing));

  List<String> _vehicleTypeValues() =>
      _listingOnly((slot) => _fmt.formatVehicleType(slot.listing));

  List<String> _registrationValues() =>
      _listingOnly((slot) => _fmt.formatRegistration(slot.listing));

  List<String> _fuelValues() =>
      _listingOnly((slot) => _fmt.formatFuel(slot.listing));

  List<String> _engineValues() =>
      _listingOnly((slot) => _fmt.formatEngine(slot.listing));

  List<String> _powerValues() =>
      _listingOnly((slot) => _fmt.formatPower(slot.listing));

  List<String> _drivetrainValues() =>
      _listingOnly((slot) => _fmt.formatDrivetrain(slot.listing));

  List<String> _transmissionValues() =>
      _listingOnly((slot) => _fmt.formatTransmission(slot.listing));

  List<String> _displacementValues() =>
      _listingOnly((slot) => _fmt.formatDisplacement(slot.listing));

  List<String> _vinValues() => slots.map((slot) {
    if (slot.phase == CompareSlotPhase.unavailable) {
      return CompareSpecFormatters.missing;
    }
    final status = slot.listing?.vinStatus ?? ListingVinStatus.notProvided;
    return _fmt.formatVin(status);
  }).toList();

  List<String> _photoValues() => slots.map((slot) {
    if (slot.phase == CompareSlotPhase.unavailable) {
      return CompareSpecFormatters.missing;
    }
    return _fmt.formatPhotos(slot.photoCount);
  }).toList();

  List<String> _publishedValues() =>
      _listingOnly((slot) => _fmt.formatPublishedAt(slot.listing));

  List<String> _snapshotAware(String Function(CompareResolvedSlot) format) {
    return slots.map((slot) {
      if (slot.phase == CompareSlotPhase.unavailable) {
        return CompareSpecFormatters.missing;
      }
      return format(slot);
    }).toList();
  }

  List<String> _listingOnly(String Function(CompareResolvedSlot) format) {
    return slots.map((slot) {
      if (slot.phase == CompareSlotPhase.unavailable || slot.listing == null) {
        return CompareSpecFormatters.missing;
      }
      return format(slot);
    }).toList();
  }

  /// Indices of columns tied for the minimum numeric value (at least two comparable).
  static Set<int> _lowestIndices(List<num?> values) {
    final parsed = <int, num>{};
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v != null) parsed[i] = v;
    }
    if (parsed.length < 2) return const {};
    final min = parsed.values.reduce((a, b) => a < b ? a : b);
    final winners = parsed.entries
        .where((e) => e.value == min)
        .map((e) => e.key)
        .toSet();
    return winners.length == parsed.length ? const {} : winners;
  }
}

List<CompareSpecSection> filterOnlyDifferences(
  List<CompareSpecSection> sections,
) {
  return sections
      .map((section) {
        final rows = section.rows.where((r) => !r.allValuesEqual).toList();
        if (rows.isEmpty) return null;
        return CompareSpecSection(title: section.title, rows: rows);
      })
      .whereType<CompareSpecSection>()
      .toList();
}
