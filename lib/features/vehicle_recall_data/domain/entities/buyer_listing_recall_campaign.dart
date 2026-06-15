import 'package:equatable/equatable.dart';

/// One buyer-safe recall campaign from `normalized_summary.campaigns[]`.
class BuyerListingRecallCampaign extends Equatable {
  const BuyerListingRecallCampaign({
    this.campaignNumber,
    this.manufacturer,
    this.component,
    this.summary,
    this.consequence,
    this.remedy,
    this.notes,
    this.reportReceivedDate,
    this.nhtsaActionNumber,
    this.parkIt,
    this.parkOutside,
    this.overTheAirUpdate,
    this.modelYear,
    this.make,
    this.model,
  });

  final String? campaignNumber;
  final String? manufacturer;
  final String? component;
  final String? summary;
  final String? consequence;
  final String? remedy;
  final String? notes;
  final String? reportReceivedDate;
  final String? nhtsaActionNumber;
  final bool? parkIt;
  final bool? parkOutside;
  final bool? overTheAirUpdate;
  final int? modelYear;
  final String? make;
  final String? model;

  static const Set<String> _forbiddenKeys = {
    'source_metadata',
    'cache_key',
    'job_id',
    'error_code',
    'error_message',
    'vin_hash',
    'vin_normalized',
    'listing_id',
    'raw_provider',
    'provider_response',
  };

  static String? _trim(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool? _bool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == 'yes' || text == 'y') return true;
    if (text == 'false' || text == 'no' || text == 'n') return false;
    return null;
  }

  static int? _modelYear(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return value >= 1900 && value <= 2100 ? value : null;
    }
    final parsed = int.tryParse(value.toString().trim());
    if (parsed == null || parsed < 1900 || parsed > 2100) return null;
    return parsed;
  }

  static BuyerListingRecallCampaign? tryParse(Map<String, dynamic> raw) {
    try {
      for (final key in raw.keys) {
        if (_forbiddenKeys.contains(key.trim().toLowerCase())) {
          return null;
        }
      }

      final campaign = BuyerListingRecallCampaign(
        campaignNumber: _trim(raw['campaign_number']),
        manufacturer: _trim(raw['manufacturer']),
        component: _trim(raw['component']),
        summary: _trim(raw['summary']),
        consequence: _trim(raw['consequence']),
        remedy: _trim(raw['remedy']),
        notes: _trim(raw['notes']),
        reportReceivedDate: _trim(raw['report_received_date']),
        nhtsaActionNumber: _trim(raw['nhtsa_action_number']),
        parkIt: _bool(raw['park_it']),
        parkOutside: _bool(raw['park_outside']),
        overTheAirUpdate: _bool(raw['over_the_air_update']),
        modelYear: _modelYear(raw['model_year']),
        make: _trim(raw['make']),
        model: _trim(raw['model']),
      );

      if (!campaign.hasDisplayableField) return null;
      return campaign;
    } catch (_) {
      return null;
    }
  }

  bool get hasDisplayableField =>
      campaignNumber != null ||
      manufacturer != null ||
      component != null ||
      summary != null ||
      consequence != null ||
      remedy != null ||
      notes != null ||
      reportReceivedDate != null ||
      nhtsaActionNumber != null ||
      parkIt != null ||
      parkOutside != null ||
      overTheAirUpdate != null ||
      modelYear != null ||
      make != null ||
      model != null;

  @override
  List<Object?> get props => [
    campaignNumber,
    manufacturer,
    component,
    summary,
    consequence,
    remedy,
    notes,
    reportReceivedDate,
    nhtsaActionNumber,
    parkIt,
    parkOutside,
    overTheAirUpdate,
    modelYear,
    make,
    model,
  ];
}
