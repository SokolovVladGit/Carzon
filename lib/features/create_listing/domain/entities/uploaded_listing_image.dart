import 'package:equatable/equatable.dart';

/// Metadata for one uploaded object in `listing-images/listings/<userId>/...`.
/// Ordered by collection index before calling `create_listing_v2`.
class UploadedListingImage extends Equatable {
  const UploadedListingImage({required this.publicUrl, this.storagePath});

  final String publicUrl;
  final String? storagePath;

  @override
  List<Object?> get props => [publicUrl, storagePath];
}
