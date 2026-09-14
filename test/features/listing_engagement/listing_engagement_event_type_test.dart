import 'package:carzon/features/listing_engagement/domain/entities/listing_engagement_event_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('event enum wire values match backend taxonomy exactly', () {
    expect(ListingEngagementEventType.impression.wireValue, 'impression');
    expect(ListingEngagementEventType.phone.wireValue, 'phone');
    expect(ListingEngagementEventType.whatsapp.wireValue, 'whatsapp');
    expect(ListingEngagementEventType.telegram.wireValue, 'telegram');
    expect(ListingEngagementEventType.share.wireValue, 'share');
  });
}
