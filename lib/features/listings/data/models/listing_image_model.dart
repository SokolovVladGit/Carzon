import '../../domain/entities/listing_image.dart';

class ListingImageModel extends ListingImage {
  const ListingImageModel({
    required super.id,
    required super.listingId,
    required super.publicUrl,
    super.storagePath,
    required super.position,
    required super.createdAt,
  });

  factory ListingImageModel.fromJson(Map<String, dynamic> json) {
    return ListingImageModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      publicUrl: json['public_url'] as String,
      storagePath: json['storage_path'] as String?,
      position: (json['position'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
