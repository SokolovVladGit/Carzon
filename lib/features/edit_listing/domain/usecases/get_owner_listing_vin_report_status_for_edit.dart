import '../../../../core/utils/result.dart';
import '../entities/owner_listing_vin_report_status.dart';
import '../repositories/edit_listing_repository.dart';

class GetOwnerListingVinReportStatusForEdit {
  GetOwnerListingVinReportStatusForEdit(this._repository);

  final EditListingRepository _repository;

  Future<Result<OwnerListingVinReportLookupResult>> call(String listingId) =>
      _repository.fetchOwnerVinReportStatus(listingId);
}
