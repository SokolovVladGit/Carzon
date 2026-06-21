import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards for `20260709120000_buyer_official_data_pending_signals.sql`.
void main() {
  group('20260709120000_buyer_official_data_pending_signals.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260709120000_buyer_official_data_pending_signals.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('updates all three buyer RPCs', () {
      expect(
        lower,
        contains(
          'create or replace function public.get_listing_vin_report_for_buyer',
        ),
      );
      expect(
        lower,
        contains(
          'create or replace function public.get_listing_model_data_for_buyer',
        ),
      );
      expect(
        lower,
        contains(
          'create or replace function public.get_listing_recalls_for_buyer',
        ),
      );
    });

    test('VIN pending signal reads snapshot without exposing private fields', () {
      expect(lower, contains('listing_vin_report_snapshot'));
      expect(lower, contains("s.processing_status in ('pending', 'processing')"));
      expect(lower, contains("li.vin_status = 'format_valid'"));

      final returnsStart = lower.indexOf('returns table (');
      expect(returnsStart, greaterThan(-1));
      final returnsEnd = lower.indexOf(')', returnsStart + 1);
      expect(returnsEnd, greaterThan(returnsStart));
      final returnsBlock = lower.substring(returnsStart, returnsEnd);
      expect(returnsBlock, isNot(contains('vin_hash')));
      expect(returnsBlock, isNot(contains('vin_normalized')));
      expect(returnsBlock, isNot(contains('source_metadata')));

      expect(lower, isNot(contains('r.vin_hash')));
      expect(lower, isNot(contains('r.vin_normalized')));
      expect(lower, isNot(contains('s.vin_hash')));

      final unionStart = lower.indexOf('union all');
      final vinFnEnd = lower.indexOf(
        'create or replace function public.get_listing_model_data_for_buyer',
      );
      final pendingBlock = lower.substring(unionStart, vinFnEnd);
      expect(pendingBlock, contains("'{}'::jsonb as normalized_summary"));
      expect(pendingBlock, isNot(contains('source_metadata->')));
    });

    test('model pending signal uses pending/processing cache status only', () {
      expect(lower, contains('vehicle_model_source_cache'));
      expect(
        lower,
        contains("c.status in ('pending', 'processing')"),
      );

      final modelStart = lower.indexOf(
        'create or replace function public.get_listing_model_data_for_buyer',
      );
      final modelEnd = lower.indexOf(
        'comment on function public.get_listing_model_data_for_buyer',
      );
      final modelBlock = lower.substring(modelStart, modelEnd);
      final modelReturnsStart = modelBlock.indexOf('returns table (');
      final modelReturnsEnd = modelBlock.indexOf(')', modelReturnsStart + 1);
      final modelReturns = modelBlock.substring(
        modelReturnsStart,
        modelReturnsEnd,
      );
      expect(modelReturns, isNot(contains('cache_key')));
      expect(modelReturns, isNot(contains('source_metadata')));
    });

    test('recall pending signal uses pending/processing cache status only', () {
      expect(lower, contains('vehicle_recall_source_cache'));
      expect(
        lower,
        contains("c.status in ('pending', 'processing')"),
      );
    });

    test('pending rows use empty normalized_summary object', () {
      expect(lower, contains("'{}'::jsonb as normalized_summary"));
    });

    test('preserves succeeded/partial buyer return paths', () {
      expect(lower, contains("c.status in ('succeeded', 'partial')"));
      expect(lower, contains("r.visibility = 'public_summary'"));
    });

    test('grants execute to anon and authenticated only', () {
      expect(lower, contains('grant execute on function public.get_listing_vin_report_for_buyer'));
      expect(lower, contains('grant execute on function public.get_listing_model_data_for_buyer'));
      expect(lower, contains('grant execute on function public.get_listing_recalls_for_buyer'));
      expect(lower, contains('to anon, authenticated'));
    });
  });
}
