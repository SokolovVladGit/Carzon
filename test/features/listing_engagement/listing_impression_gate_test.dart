import 'dart:async';

import 'package:carzon/features/listing_engagement/presentation/listing_impression_gate.dart';
import 'package:carzon/features/listing_engagement/presentation/listing_impression_session_guard.dart';
import 'package:flutter_test/flutter_test.dart';

class _ManualTimer implements Timer {
  _ManualTimer(this._callback);

  final void Function() _callback;
  bool _isActive = true;

  @override
  void cancel() => _isActive = false;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;

  void fire() {
    if (!_isActive) return;
    _isActive = false;
    _callback();
  }
}

void main() {
  late List<_ManualTimer> scheduled;

  ListingImpressionGate gate({
    required String listingId,
    required ListingImpressionSessionGuard session,
    required void Function() onQualified,
  }) {
    return ListingImpressionGate(
      listingId: listingId,
      session: session,
      onQualified: onQualified,
      timerFactory: (duration, callback) {
        expect(duration, const Duration(milliseconds: 500));
        final timer = _ManualTimer(callback);
        scheduled.add(timer);
        return timer;
      },
    );
  }

  setUp(() {
    scheduled = <_ManualTimer>[];
  });

  test('<50% visible never qualifies', () {
    final qualified = <String>[];
    final observer = gate(
      listingId: 'a',
      session: ListingImpressionSessionGuard(),
      onQualified: () => qualified.add('a'),
    );
    observer.onVisibleFraction(0.49);
    expect(scheduled, isEmpty);
    expect(qualified, isEmpty);
  });

  test('>=50% for less than dwell does not record', () {
    final qualified = <String>[];
    final observer = gate(
      listingId: 'a',
      session: ListingImpressionSessionGuard(),
      onQualified: () => qualified.add('a'),
    );
    observer.onVisibleFraction(0.5);
    expect(scheduled, hasLength(1));
    observer.dispose();
    scheduled.single.fire();
    expect(qualified, isEmpty);
  });

  test('>=50% for dwell records exactly once', () {
    final qualified = <String>[];
    final session = ListingImpressionSessionGuard();
    final observer = gate(
      listingId: 'a',
      session: session,
      onQualified: () => qualified.add('a'),
    );
    observer.onVisibleFraction(0.8);
    scheduled.single.fire();
    expect(qualified, ['a']);
    observer.onVisibleFraction(0.9);
    expect(scheduled, hasLength(1));
    expect(qualified, ['a']);
  });

  test('scroll away before dwell cancels, later dwell can still qualify', () {
    final qualified = <String>[];
    final observer = gate(
      listingId: 'a',
      session: ListingImpressionSessionGuard(),
      onQualified: () => qualified.add('a'),
    );
    observer.onVisibleFraction(0.7);
    observer.onVisibleFraction(0.1);
    scheduled.single.fire();
    expect(qualified, isEmpty);
    observer.onVisibleFraction(0.7);
    scheduled.last.fire();
    expect(qualified, ['a']);
  });

  test('same listing is not re-recorded after scroll away/back', () {
    final qualified = <String>[];
    final session = ListingImpressionSessionGuard();
    final observer = gate(
      listingId: 'a',
      session: session,
      onQualified: () => qualified.add('a'),
    );
    observer.onVisibleFraction(0.7);
    scheduled.single.fire();
    observer.onVisibleFraction(0.0);
    observer.onVisibleFraction(0.9);
    expect(scheduled, hasLength(1));
    expect(qualified, ['a']);
  });

  test('different listings are independent', () {
    final qualified = <String>[];
    final session = ListingImpressionSessionGuard();
    final a = gate(
      listingId: 'a',
      session: session,
      onQualified: () => qualified.add('a'),
    );
    final b = gate(
      listingId: 'b',
      session: session,
      onQualified: () => qualified.add('b'),
    );
    a.onVisibleFraction(0.7);
    b.onVisibleFraction(0.7);
    for (final timer in scheduled) {
      timer.fire();
    }
    expect(qualified, ['a', 'b']);
  });
}
