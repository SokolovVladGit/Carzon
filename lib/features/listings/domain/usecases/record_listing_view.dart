import '../../../../core/utils/result.dart';
import '../repositories/anonymous_viewer_id_repository.dart';
import '../entities/listing_view_stats.dart';
import '../repositories/listings_repository.dart';

class RecordListingView {
  RecordListingView(this._repository, this._anonymousViewerIds);

  final ListingsRepository _repository;
  final AnonymousViewerIdRepository _anonymousViewerIds;

  Future<Result<ListingViewStats>> call(String listingId) async {
    final anonymousViewerId = await _anonymousViewerIds.getOrCreate();
    return _repository.recordListingView(listingId, anonymousViewerId);
  }
}
