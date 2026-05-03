import 'package:equatable/equatable.dart';

/// Ordered gallery row backing `public.listing_images` (read-only in the app
/// for Phase 2; writes go through RPCs in later phases).
class ListingImage extends Equatable {
  const ListingImage({
    required this.id,
    required this.listingId,
    required this.publicUrl,
    this.storagePath,
    required this.position,
    required this.createdAt,
  });

  final String id;
  final String listingId;

  /// Public `https://` Supabase Storage URL (or compatible).
  final String publicUrl;

  /// Optional object path inside the listing-images bucket.
  final String? storagePath;

  /// 0-based order; 0 is the cover / `listings.cover_image_url` projection.
  final int position;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    listingId,
    publicUrl,
    storagePath,
    position,
    createdAt,
  ];
}
