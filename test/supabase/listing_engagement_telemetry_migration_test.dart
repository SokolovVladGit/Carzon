import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final file = File(
      'supabase/migrations/20260913200000_listing_engagement_telemetry.sql',
    );
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
  });

  test(
    'creates daily and dedupe tables with taxonomy and non-negative count',
    () {
      expect(
        sql,
        contains('create table if not exists public.listing_engagement_daily'),
      );
      expect(
        sql,
        contains('create table if not exists public.listing_engagement_dedupe'),
      );
      expect(sql, contains('primary key (listing_id, event_date, event_type)'));
      expect(
        sql,
        contains(
          'primary key (listing_id, event_date, event_type, viewer_hash)',
        ),
      );
      expect(sql, contains('listing_engagement_daily_count_chk'));
      expect(sql, contains('check (event_count >= 0)'));
      expect(sql, contains("'impression'"));
      expect(sql, contains("'phone'"));
      expect(sql, contains("'whatsapp'"));
      expect(sql, contains("'telegram'"));
      expect(sql, contains("'share'"));
      expect(sql, contains('on delete cascade'));
    },
  );

  test('does not add views favorites inquiries or a generic event log', () {
    expect(sql, isNot(contains("'view'")));
    expect(sql, isNot(contains("'favorite'")));
    expect(sql, isNot(contains("'inquiry'")));
    expect(sql, isNot(contains("'message'")));
    expect(sql.toLowerCase(), isNot(contains('listing_engagement_events')));
    expect(
      sql.toLowerCase(),
      isNot(contains('create table if not exists public.listing_view')),
    );
  });

  test('revokes client table access and enables RLS', () {
    expect(
      sql,
      contains(
        'alter table public.listing_engagement_daily enable row level security',
      ),
    );
    expect(
      sql,
      contains(
        'alter table public.listing_engagement_dedupe enable row level security',
      ),
    );
    expect(
      sql,
      contains('revoke all on table public.listing_engagement_daily from anon'),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.listing_engagement_daily from authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.listing_engagement_dedupe from anon',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.listing_engagement_dedupe from authenticated',
      ),
    );
  });

  test('recording RPC uses Moldova day, hashed viewer, and atomic dedupe', () {
    expect(sql, contains('function public.record_listing_engagement_event'));
    expect(sql, contains("at time zone 'Europe/Chisinau'"));
    expect(sql, contains('carzon_sha256_hex_utf8'));
    expect(sql, contains("'auth:'"));
    expect(sql, contains("'anon:'"));
    expect(sql, contains('on conflict do nothing'));
    expect(sql, contains('auth.uid() = v_listing.seller_id'));
    expect(sql, contains("status is distinct from 'active'"));
    expect(sql, contains('invalid engagement event type'));
    expect(
      sql,
      contains(
        'grant execute on function public.record_listing_engagement_event(uuid, text, text)',
      ),
    );
    expect(sql, contains('to anon, authenticated'));
    expect(sql, isNot(contains('return query select v_viewer_hash')));
  });

  test(
    'seller engagement RPCs are authenticated-only and leave Phase 1 intact',
    () {
      expect(sql, contains('function public.get_my_seller_engagement_summary'));
      expect(
        sql,
        contains('function public.get_my_seller_engagement_listings'),
      );
      expect(sql, contains('invalid analytics period'));
      expect(sql, contains('order by l.id'));
      expect(
        sql,
        contains(
          'revoke all on function public.get_my_seller_engagement_summary(integer)',
        ),
      );
      expect(sql, contains('from anon'));
      expect(
        sql,
        contains(
          'grant execute on function public.get_my_seller_engagement_summary(integer)',
        ),
      );
      expect(
        sql,
        isNot(
          contains(
            'create or replace function public.get_my_seller_analytics_summary',
          ),
        ),
      );
      expect(
        sql,
        isNot(
          contains('create or replace function public.record_listing_view'),
        ),
      );
      expect(sql.toLowerCase(), isNot(contains('create index')));
    },
  );
}
