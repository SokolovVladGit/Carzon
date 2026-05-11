import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260524120000_listings_updated_at.sql`.
///
/// No live Postgres — mirrors other migration fingerprint tests under
/// `test/supabase/`.
void main() {
  group('20260524120000_listings_updated_at.sql', () {
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260524120000_listings_updated_at.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'listings.updated_at migration must exist',
      );
      lower = f.readAsStringSync().toLowerCase();
    });

    test('targets public.listings and adds updated_at when missing', () {
      expect(lower, contains('alter table public.listings'));
      expect(lower, contains('add column if not exists updated_at'));
      expect(lower, contains('timestamptz'));
    });

    test('backfills null updated_at from created_at before not null', () {
      expect(lower, contains('update public.listings'));
      expect(lower, contains('set updated_at'));
      expect(lower, contains('coalesce(created_at'));
      expect(lower, contains('where updated_at is null'));
    });

    test('sets default now() and NOT NULL on listings.updated_at', () {
      expect(lower, contains('alter column updated_at set default now()'));
      expect(lower, contains('alter column updated_at set not null'));
    });

    test(
      'defines set_listings_updated_at trigger function with now() stamp',
      () {
        expect(
          lower,
          contains(
            'create or replace function public.set_listings_updated_at()',
          ),
        );
        expect(lower, contains('returns trigger'));
        expect(lower, contains('new.updated_at := now()'));
      },
    );

    test(
      'installs listings_set_updated_at before update on public.listings',
      () {
        expect(
          lower,
          contains('drop trigger if exists listings_set_updated_at'),
        );
        expect(lower, contains('create trigger listings_set_updated_at'));
        expect(lower, contains('before update on public.listings'));
        expect(
          lower.contains('execute function public.set_listings_updated_at()') ||
              lower.contains(
                'execute procedure public.set_listings_updated_at()',
              ),
          isTrue,
        );
      },
    );
  });
}
