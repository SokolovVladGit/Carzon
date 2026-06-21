import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guard: hosted maintenance SQL scripts stay aligned with
/// `supabase/migrations/*.sql` and cover post-June release-critical objects.
///
/// Does not execute Postgres or connect to hosted Supabase.
void main() {
  late Directory migrationsDir;
  late File parityScript;
  late File runtimeScript;
  late List<MapEntry<String, String>> repoMigrations;
  late String paritySql;
  late String runtimeSql;

  setUpAll(() {
    migrationsDir = Directory('supabase/migrations');
    parityScript = File(
      'supabase/maintenance/check_hosted_migration_parity.sql',
    );
    runtimeScript = File(
      'supabase/maintenance/check_hosted_runtime_contracts.sql',
    );

    expect(migrationsDir.existsSync(), isTrue);
    expect(parityScript.existsSync(), isTrue);
    expect(runtimeScript.existsSync(), isTrue);

    repoMigrations =
        migrationsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .map((f) {
              final base = f.uri.pathSegments.last.replaceAll('.sql', '');
              final underscore = base.indexOf('_');
              expect(
                underscore,
                greaterThan(0),
                reason: 'bad migration name: $base',
              );
              final version = base.substring(0, underscore);
              final name = base.substring(underscore + 1);
              expect(
                version.length,
                14,
                reason: 'bad migration version: $version',
              );
              return MapEntry(version, name);
            })
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    paritySql = parityScript.readAsStringSync();
    runtimeSql = runtimeScript.readAsStringSync();
  });

  group('check_hosted_migration_parity.sql', () {
    late Set<String> expectedVersions;
    late Map<String, String> expectedNames;

    setUp(() {
      expectedVersions = {};
      expectedNames = {};
      final rowPattern = RegExp(r"\('(\d{14})',\s*'([^']+)'");
      for (final match in rowPattern.allMatches(paritySql)) {
        final version = match.group(1)!;
        final name = match.group(2)!;
        if (version == 'info' || version == 'overall') continue;
        expectedVersions.add(version);
        expectedNames[version] = name;
      }
    });

    test('info scope mentions current repo migration count', () {
      expect(
        paritySql,
        contains(
          'Read-only parity check for ${repoMigrations.length} repo migrations',
        ),
      );
    });

    test('expected list matches every supabase/migrations/*.sql file', () {
      final repoVersions = repoMigrations.map((e) => e.key).toSet();
      expect(
        expectedVersions.length,
        repoMigrations.length,
        reason: 'parity script migration row count',
      );
      expect(expectedVersions, repoVersions);
    });

    test('migration names match repo filenames', () {
      for (final entry in repoMigrations) {
        expect(
          expectedNames[entry.key],
          entry.value,
          reason: 'name mismatch for ${entry.key}',
        );
      }
    });

    test(
      'includes post-June migrations through discovery_drivetrain_filter_alert',
      () {
        const postJune = [
          '20260701120000',
          '20260702120000',
          '20260713120000',
          '20260714120000',
          '20260801120000',
          '20260802120000',
          '20260803120000',
        ];
        for (final version in postJune) {
          expect(expectedVersions, contains(version));
        }
      },
    );

    test('reports orphan hosted migrations (hosted_only_migrations row)', () {
      expect(paritySql, contains('orphan_hosted'));
      expect(paritySql, contains('hosted_only_migrations'));
    });
  });

  group('check_hosted_runtime_contracts.sql', () {
    void expectReferenced(String needle, {String? reason}) {
      expect(
        runtimeSql.contains(needle),
        isTrue,
        reason: reason ?? 'missing runtime check reference: $needle',
      );
    }

    test('covers post-June tables', () {
      for (final table in [
        'saved_searches',
        'user_blocks',
        'user_reports',
        'message_attachments',
        'vehicle_model_fetch_jobs',
        'vehicle_model_source_cache',
        'vehicle_recall_source_cache',
      ]) {
        expectReferenced("'$table'");
      }
    });

    test('covers post-June client RPCs', () {
      for (final rpc in [
        'delete_own_account',
        'block_user',
        'unblock_user',
        'list_blocked_users',
        'report_user',
        'get_or_create_support_conversation',
        'send_message_with_attachment',
        'list_my_saved_searches',
        'create_saved_search',
        'update_saved_search',
        'delete_saved_search',
        'set_saved_search_alerts_enabled',
        'find_saved_search_by_criteria',
        'claim_filter_alert_notification_events_for_processing',
        'claim_price_drop_notification_events_for_processing',
        'enqueue_price_drop_favorite_notification_events',
        'carzon_invoke_process_price_drop_notifications_worker',
        'get_listing_model_data_for_buyer',
        'get_listing_recalls_for_buyer',
        'record_listing_view',
      ]) {
        expectReferenced(rpc);
      }
    });

    test('covers internal safety helpers', () {
      for (final fn in [
        'carzon_users_are_blocked',
        'carzon_messaging_peer_from_conversation',
        'enqueue_message_notification_event',
        'carzon_enqueue_vin_decode_from_identity',
        'get_listing_vin_model_fetch_hints',
      ]) {
        expectReferenced(fn);
      }
    });

    test('documents saved_searches v2 as active UX model', () {
      expectReferenced('meta_saved_searches_v2_active_model');
      expect(
        runtimeSql.toLowerCase(),
        contains('filter_alert_settings is legacy'),
      );
    });

    test('checks vehicle_model_fetch_jobs.listing_id column', () {
      expectReferenced('column_vehicle_model_fetch_jobs_listing_id');
      expectReferenced("'listing_id'");
    });

    test('checks chat-attachments storage bucket', () {
      expectReferenced('chat-attachments');
    });

    test('checks conversations.conversation_kind column', () {
      expectReferenced('conversation_kind');
    });

    test('covers price drop favorite notification runtime contract', () {
      for (final needle in [
        'price_drops_enabled',
        'price_drop_favorite',
        'notification_delivery_events_price_drop_dedup_idx',
        'enqueue_price_drop_favorite_notification_events',
        'claim_price_drop_notification_events_for_processing',
        'carzon_invoke_process_price_drop_notifications_worker',
        'carzon_process_price_drop_notifications_1m',
        'grants_claim_price_drop_not_client',
        'grants_enqueue_price_drop_not_client',
        'edge_process_price_drop_notifications_contract',
        'process-price-drop-notifications',
        'verify_jwt=false',
      ]) {
        expectReferenced(needle);
      }
    });

    test('covers drivetrain discovery filter runtime contract', () {
      for (final needle in [
        'column_listings_drivetrain',
        'index_listings_feed_active_region_drivetrain_created',
        'fn_listing_matches_saved_discovery_criteria_drivetrain',
      ]) {
        expectReferenced(needle);
      }
    });
  });
}
