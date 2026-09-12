import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

class SellerListingDefaults extends Equatable {
  const SellerListingDefaults({
    this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled = false,
    this.marketRegion,
    this.city,
  });

  const SellerListingDefaults.empty() : this();

  final String? contactPhone;
  final String? telegramUsername;
  final bool whatsappEnabled;
  final MarketRegion? marketRegion;
  final String? city;

  bool get isEmpty =>
      contactPhone == null &&
      telegramUsername == null &&
      !whatsappEnabled &&
      marketRegion == null &&
      city == null;

  @override
  List<Object?> get props => [
    contactPhone,
    telegramUsername,
    whatsappEnabled,
    marketRegion,
    city,
  ];
}

class SellerListingDefaultsPrefill extends Equatable {
  const SellerListingDefaultsPrefill({
    this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled,
    this.marketRegion,
    this.city,
  });

  final String? contactPhone;
  final String? telegramUsername;
  final bool? whatsappEnabled;
  final MarketRegion? marketRegion;
  final String? city;

  bool get hasAny =>
      contactPhone != null ||
      telegramUsername != null ||
      whatsappEnabled != null ||
      marketRegion != null ||
      city != null;

  @override
  List<Object?> get props => [
    contactPhone,
    telegramUsername,
    whatsappEnabled,
    marketRegion,
    city,
  ];
}

MarketRegion? parseListingDefaultsMarketRegion(Object? raw) {
  if (raw is! String) return null;
  return switch (raw.trim()) {
    'transnistria' => MarketRegion.transnistria,
    'moldova' => MarketRegion.moldova,
    _ => null,
  };
}

SellerListingDefaults sellerListingDefaultsFromSubmitted({
  required String contactPhone,
  String? telegramUsername,
  required bool whatsappEnabled,
  required MarketRegion marketRegion,
  required String city,
}) {
  final phone = contactPhone.trim();
  final cityTrim = city.trim();
  return SellerListingDefaults(
    contactPhone: phone.isEmpty ? null : phone,
    telegramUsername: telegramUsername,
    whatsappEnabled: whatsappEnabled,
    marketRegion: marketRegion,
    city: cityTrim.isEmpty ? null : cityTrim,
  );
}
