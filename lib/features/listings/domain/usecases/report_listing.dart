import '../../../../core/utils/result.dart';
import '../entities/listing_report_reason.dart';
import '../repositories/listings_repository.dart';

class ReportListing {
  const ReportListing(this._repository);

  final ListingsRepository _repository;

  Future<Result<void>> call({
    required String listingId,
    required ListingReportReason reason,
    String? note,
  }) => _repository.reportListing(
    listingId: listingId,
    reason: reason,
    note: note,
  );
}
