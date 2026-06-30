import '../../../listings/presentation/utils/listing_details_header_titles.dart';
import '../../domain/entities/conversation.dart';

/// Primary header line: make + model when useful, else listing title.
String threadListingPrimaryLine(Conversation c, String listingIdFallback) {
  final make = c.listingMake?.trim() ?? '';
  final model = c.listingModel?.trim() ?? '';
  if (make.isNotEmpty && model.isNotEmpty) {
    return listingDetailsVehicleIdentityLine(make, model);
  }
  if (make.isNotEmpty) {
    return make;
  }
  if (model.isNotEmpty) {
    return model;
  }
  final title = c.listingTitle?.trim() ?? '';
  if (title.isNotEmpty) {
    return title;
  }
  return listingIdFallback;
}
