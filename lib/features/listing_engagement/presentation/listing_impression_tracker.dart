import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../app/di/injection.dart';
import '../../../core/utils/logger.dart';
import '../domain/entities/listing_engagement_event_type.dart';
import '../domain/usecases/record_listing_engagement.dart';
import 'listing_impression_gate.dart';
import 'listing_impression_session_guard.dart';

/// Records one impression after meaningful card exposure.
///
/// No-ops when telemetry is not registered (tests / seller management
/// surfaces that never wrap this widget).
class ListingImpressionTracker extends StatefulWidget {
  const ListingImpressionTracker({
    super.key,
    required this.listingId,
    required this.child,
    this.recorder,
    this.session,
    this.policy = const ListingImpressionPolicy(),
  });

  final String listingId;
  final Widget child;
  final RecordListingEngagement? recorder;
  final ListingImpressionSessionGuard? session;
  final ListingImpressionPolicy policy;

  @override
  State<ListingImpressionTracker> createState() =>
      _ListingImpressionTrackerState();
}

class _ListingImpressionTrackerState extends State<ListingImpressionTracker> {
  ListingImpressionGate? _gate;

  @override
  void initState() {
    super.initState();
    _syncGate();
  }

  @override
  void didUpdateWidget(covariant ListingImpressionTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId ||
        oldWidget.recorder != widget.recorder ||
        oldWidget.session != widget.session) {
      _gate?.dispose();
      _gate = null;
      _syncGate();
    }
  }

  @override
  void dispose() {
    _gate?.dispose();
    super.dispose();
  }

  void _syncGate() {
    final recorder = _resolveRecorder();
    final session = _resolveSession();
    if (recorder == null || session == null) return;
    _gate = ListingImpressionGate(
      listingId: widget.listingId,
      session: session,
      policy: widget.policy,
      onQualified: () {
        try {
          recorder.recordFireAndForget(
            listingId: widget.listingId,
            eventType: ListingEngagementEventType.impression,
          );
        } catch (e, st) {
          AppLogger(
            'ListingImpressionTracker',
          ).error('impression telemetry threw for ${widget.listingId}', e, st);
        }
      },
    );
  }

  RecordListingEngagement? _resolveRecorder() {
    if (widget.recorder != null) return widget.recorder;
    if (!sl.isRegistered<RecordListingEngagement>()) return null;
    return sl<RecordListingEngagement>();
  }

  ListingImpressionSessionGuard? _resolveSession() {
    if (widget.session != null) return widget.session;
    if (!sl.isRegistered<ListingImpressionSessionGuard>()) return null;
    return sl<ListingImpressionSessionGuard>();
  }

  @override
  Widget build(BuildContext context) {
    final gate = _gate;
    if (gate == null) return widget.child;
    return VisibilityDetector(
      key: Key('listing_impression_${widget.listingId}'),
      onVisibilityChanged: (info) =>
          gate.onVisibleFraction(info.visibleFraction),
      child: widget.child,
    );
  }
}
