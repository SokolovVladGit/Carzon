import '../../../../core/utils/result.dart';
import '../../domain/entities/listing_report_reason.dart';

typedef ListingReportSubmitter =
    Future<Result<void>> Function({
      required String listingId,
      required ListingReportReason reason,
      String? note,
    });
