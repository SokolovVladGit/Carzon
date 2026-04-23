import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';

/// Backend contract for the current authenticated user's favorites.
/// Implementations infer ownership from the auth session — the client
/// never passes a user id.
abstract interface class FavoritesRepository {
  Future<Result<Set<String>>> getFavoriteIds();
  Future<Result<List<Listing>>> getFavoriteListings();
  Future<Result<void>> add(String listingId);
  Future<Result<void>> remove(String listingId);
}
