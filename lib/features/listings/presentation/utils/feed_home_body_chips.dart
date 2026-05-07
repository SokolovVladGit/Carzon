import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';
import '../widgets/category_chip.dart';

const _bodyChipSvgPrefix = 'assets/categories/svg';

/// Feed header row: localized labels + body-type SVGs (with icon fallback).
List<FeedBodyChipDescriptor> feedHomeBodyChipDescriptors(
  AppLocalizations l10n,
) {
  return [
    FeedBodyChipDescriptor(
      id: 'all',
      label: l10n.listingsBodyChipAll,
      icon: Icons.grid_view_outlined,
      svgAssetPath: '$_bodyChipSvgPrefix/all.svg',
    ),
    FeedBodyChipDescriptor(
      id: ListingBodyType.sedan.name,
      label: l10n.listingBodyTypeSedan,
      icon: Icons.directions_car_outlined,
      svgAssetPath: '$_bodyChipSvgPrefix/sedan.svg',
    ),
    FeedBodyChipDescriptor(
      id: ListingBodyType.suv.name,
      label: l10n.listingBodyTypeSuv,
      icon: Icons.airport_shuttle_outlined,
      svgAssetPath: '$_bodyChipSvgPrefix/suv.svg',
    ),
    FeedBodyChipDescriptor(
      id: ListingBodyType.hatchback.name,
      label: l10n.listingBodyTypeHatchback,
      icon: Icons.time_to_leave_outlined,
      svgAssetPath: '$_bodyChipSvgPrefix/hatch.svg',
    ),
    FeedBodyChipDescriptor(
      id: ListingBodyType.wagon.name,
      label: l10n.listingBodyTypeWagon,
      icon: Icons.luggage_outlined,
      svgAssetPath: '$_bodyChipSvgPrefix/wagon.svg',
    ),
    FeedBodyChipDescriptor(
      id: ListingBodyType.minivan.name,
      label: l10n.listingBodyTypeMinivan,
      icon: Icons.airport_shuttle,
      svgAssetPath: '$_bodyChipSvgPrefix/minivan.svg',
    ),
    FeedBodyChipDescriptor(
      id: ListingBodyType.pickup.name,
      label: l10n.listingBodyTypePickup,
      icon: Icons.local_shipping_outlined,
      svgAssetPath: '$_bodyChipSvgPrefix/pickup.svg',
    ),
    FeedBodyChipDescriptor(
      id: ListingBodyType.coupe.name,
      label: l10n.listingBodyTypeCoupe,
      icon: Icons.sports_motorsports_outlined,
      svgAssetPath: '$_bodyChipSvgPrefix/coupe.svg',
    ),
  ];
}

/// Maps a chip [id] from [feedHomeBodyChipDescriptors] to the domain filter value.
ListingBodyType? listingBodyTypeFromFeedChipId(String id) {
  if (id == 'all') return null;
  try {
    return ListingBodyType.values.byName(id);
  } on ArgumentError {
    return null;
  }
}
