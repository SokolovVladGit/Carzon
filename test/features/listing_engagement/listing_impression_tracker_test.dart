import 'package:carzon/features/listing_engagement/domain/entities/listing_engagement_event_type.dart';
import 'package:carzon/features/listing_engagement/domain/usecases/record_listing_engagement.dart';
import 'package:carzon/features/listing_engagement/presentation/listing_impression_gate.dart';
import 'package:carzon/features/listing_engagement/presentation/listing_impression_session_guard.dart';
import 'package:carzon/features/listing_engagement/presentation/listing_impression_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _MockRecorder extends Mock implements RecordListingEngagement {}

void main() {
  setUpAll(() {
    registerFallbackValue(ListingEngagementEventType.impression);
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDownAll(() {
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
  });

  testWidgets('telemetry failure does not break tap/navigation', (
    tester,
  ) async {
    final recorder = _MockRecorder();
    when(
      () => recorder.recordFireAndForget(
        listingId: any(named: 'listingId'),
        eventType: any(named: 'eventType'),
      ),
    ).thenThrow(StateError('rpc down'));

    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListingImpressionTracker(
            listingId: 'l1',
            recorder: recorder,
            session: ListingImpressionSessionGuard(),
            policy: const ListingImpressionPolicy(dwell: Duration.zero),
            child: GestureDetector(
              onTap: () => taps += 1,
              child: const SizedBox.expand(child: Text('card')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('card'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
