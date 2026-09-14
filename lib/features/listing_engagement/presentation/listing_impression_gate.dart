import 'dart:async';

import 'listing_impression_session_guard.dart';

/// Card impression: >= 50% visible for ~500 ms.
class ListingImpressionPolicy {
  const ListingImpressionPolicy({
    this.visibleFractionThreshold = 0.5,
    this.dwell = const Duration(milliseconds: 500),
  });

  final double visibleFractionThreshold;
  final Duration dwell;
}

typedef ImpressionTimerFactory =
    Timer Function(Duration duration, void Function() callback);

/// Deterministic visibility/dwell gate. Widget tests drive
/// [onVisibleFraction] instead of depending on scroll geometry.
class ListingImpressionGate {
  ListingImpressionGate({
    required this.listingId,
    required this.session,
    required this.onQualified,
    this.policy = const ListingImpressionPolicy(),
    ImpressionTimerFactory? timerFactory,
  }) : _timerFactory = timerFactory ?? Timer.new;

  final String listingId;
  final ListingImpressionSessionGuard session;
  final VoidCallback onQualified;
  final ListingImpressionPolicy policy;
  final ImpressionTimerFactory _timerFactory;

  Timer? _timer;

  void onVisibleFraction(double fraction) {
    if (fraction < policy.visibleFractionThreshold) {
      _cancelDwell();
      return;
    }
    if (_timer != null || session.contains(listingId)) return;
    _timer = _timerFactory(policy.dwell, _onDwellElapsed);
  }

  void dispose() => _cancelDwell();

  void _onDwellElapsed() {
    _timer = null;
    if (!session.claim(listingId)) return;
    onQualified();
  }

  void _cancelDwell() {
    _timer?.cancel();
    _timer = null;
  }
}

typedef VoidCallback = void Function();
