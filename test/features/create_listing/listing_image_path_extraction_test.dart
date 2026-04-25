import 'package:carzon/features/create_listing/data/datasources/create_listing_image_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers [SupabaseCreateListingImageRemoteDataSource.extractStoragePathFromPublicUrl]
/// in isolation: path derivation must be safe enough to feed directly
/// into Storage delete — any ambiguous input must return null so the
/// caller skips deletion entirely.
void main() {
  group('extractStoragePathFromPublicUrl', () {
    test('extracts the object path from a Supabase public URL', () {
      const url = 'https://proj.supabase.co/storage/v1/object/public/'
          'listing-images/listings/user-1/2026-04-25.jpg';
      expect(
        SupabaseCreateListingImageRemoteDataSource
            .extractStoragePathFromPublicUrl(url),
        'listings/user-1/2026-04-25.jpg',
      );
    });

    test('returns null for signed-URL shapes', () {
      const url = 'https://proj.supabase.co/storage/v1/object/sign/'
          'listing-images/listings/user-1/2026-04-25.jpg?token=abc';
      expect(
        SupabaseCreateListingImageRemoteDataSource
            .extractStoragePathFromPublicUrl(url),
        isNull,
      );
    });

    test('returns null for URLs outside the expected bucket', () {
      const url = 'https://proj.supabase.co/storage/v1/object/public/'
          'other-bucket/listings/user-1/x.jpg';
      expect(
        SupabaseCreateListingImageRemoteDataSource
            .extractStoragePathFromPublicUrl(url),
        isNull,
      );
    });

    test('returns null for non-http schemes', () {
      expect(
        SupabaseCreateListingImageRemoteDataSource
            .extractStoragePathFromPublicUrl(
          'ftp://proj.supabase.co/storage/v1/object/public/listing-images/x',
        ),
        isNull,
      );
    });

    test('returns null when the bucket segment is the final one', () {
      const url = 'https://proj.supabase.co/storage/v1/object/public/'
          'listing-images/';
      expect(
        SupabaseCreateListingImageRemoteDataSource
            .extractStoragePathFromPublicUrl(url),
        isNull,
      );
    });

    test('returns null for malformed input', () {
      expect(
        SupabaseCreateListingImageRemoteDataSource
            .extractStoragePathFromPublicUrl(''),
        isNull,
      );
      expect(
        SupabaseCreateListingImageRemoteDataSource
            .extractStoragePathFromPublicUrl('not a url'),
        isNull,
      );
    });
  });
}
