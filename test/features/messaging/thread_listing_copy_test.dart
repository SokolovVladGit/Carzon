import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/presentation/utils/thread_listing_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 7, 2);

  Conversation conversation({
    String? listingMake,
    String? listingModel,
    String? listingTitle,
  }) => Conversation(
    id: 'c1',
    listingId: 'l1',
    buyerId: 'b',
    sellerId: 's',
    createdAt: t0,
    updatedAt: t0,
    listingMake: listingMake,
    listingModel: listingModel,
    listingTitle: listingTitle,
  );

  test('threadListingPrimaryLine dedupes make repeated in model', () {
    expect(
      threadListingPrimaryLine(
        conversation(
          listingMake: 'Toyota',
          listingModel: 'Toyota RAV4 Hybrid',
        ),
        'fallback',
      ),
      'Toyota RAV4 Hybrid',
    );
  });

  test('threadListingPrimaryLine falls back to listing title', () {
    expect(
      threadListingPrimaryLine(
        conversation(listingTitle: 'Custom headline'),
        'fallback',
      ),
      'Custom headline',
    );
  });
}
