import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';

/// Contact and location values that arrived without a seller edit.
///
/// Seller defaults and the initial region/deal/currency live here so an
/// untouched form can leave without a warning.
class CreateListingExitBaseline {
  const CreateListingExitBaseline({
    this.phone = '',
    this.telegram = '',
    this.whatsapp = false,
    this.region = MarketRegion.transnistria,
    this.city = '',
  });

  final String phone;
  final String telegram;
  final bool whatsapp;
  final MarketRegion region;
  final String city;

  CreateListingExitBaseline copyWithApplied({
    String? phone,
    String? telegram,
    bool? whatsapp,
    MarketRegion? region,
    String? city,
  }) {
    return CreateListingExitBaseline(
      phone: phone ?? this.phone,
      telegram: telegram ?? this.telegram,
      whatsapp: whatsapp ?? this.whatsapp,
      region: region ?? this.region,
      city: city ?? this.city,
    );
  }
}

/// True when the seller has authored listing content worth keeping.
///
/// Automatic defaults are compared against [baseline]. Deal type and
/// currency count only when they differ from the initial sale / EUR.
bool createListingRouteExitIsDirty({
  required String vin,
  required bool identityConfirmed,
  required String make,
  required String model,
  required String customMake,
  required String variant,
  required int? year,
  required bool brandChosen,
  required int photoCount,
  required String price,
  required String mileage,
  required ListingType dealType,
  required ListingCurrency currency,
  required String description,
  required bool hasTechnicalValue,
  required String phone,
  required String telegram,
  required bool whatsapp,
  required MarketRegion region,
  required String city,
  required CreateListingExitBaseline baseline,
}) {
  if (vin.trim().isNotEmpty || identityConfirmed) return true;
  if (brandChosen || year != null) return true;
  if (make.trim().isNotEmpty ||
      model.trim().isNotEmpty ||
      customMake.trim().isNotEmpty ||
      variant.trim().isNotEmpty) {
    return true;
  }
  if (photoCount > 0) return true;
  if (price.trim().isNotEmpty || mileage.trim().isNotEmpty) return true;
  if (dealType != ListingType.sale || currency != ListingCurrency.eur) {
    return true;
  }
  if (description.trim().isNotEmpty || hasTechnicalValue) return true;
  if (phone.trim() != baseline.phone.trim()) return true;
  if (telegram.trim() != baseline.telegram.trim()) return true;
  if (whatsapp != baseline.whatsapp) return true;
  if (region != baseline.region) return true;
  if (city.trim() != baseline.city.trim()) return true;
  return false;
}
