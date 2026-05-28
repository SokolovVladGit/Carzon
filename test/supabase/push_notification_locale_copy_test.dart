import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for shared push notification locale copy (Edge workers).
void main() {
  group('supabase/functions/_shared/push_notification_copy.ts', () {
    late String shared;

    setUpAll(() {
      shared = File(
        'supabase/functions/_shared/push_notification_copy.ts',
      ).readAsStringSync();
    });

    test('defines normalizePushLocale with ru fallback', () {
      expect(shared, contains('normalizePushLocale'));
      expect(shared, contains('tag.startsWith("ro-")'));
      expect(shared, contains('return "ru"'));
    });

    test('message notification RU and RO copy', () {
      expect(shared, contains('Новое сообщение'));
      expect(shared, contains('Вам написали по объявлению в Carzon.'));
      expect(shared, contains('Mesaj nou'));
      expect(
        shared,
        contains('Ați primit un mesaj pentru anunțul din Carzon.'),
      );
    });

    test('filter alert RU and RO copy', () {
      expect(shared, contains('Новое объявление'));
      expect(shared, contains('Anunț nou'));
      expect(
        shared,
        contains(
          'Există un anunț pentru filtrul salvat. Deschideți pentru a-l vedea.',
        ),
      );
    });
  });

  group('Edge workers use per-token locale', () {
    test('process-message-notifications selects copy by token locale', () {
      final ts = File(
        'supabase/functions/process-message-notifications/index.ts',
      ).readAsStringSync();
      expect(ts, contains('messageNotificationCopyForLocale'));
      expect(ts, contains('.select("id, token, locale")'));
      expect(ts, contains('title: copy.title'));
      expect(ts, contains('body: copy.body'));
      expect(ts, isNot(contains('message_body')));
    });

    test('process-filter-alert-notifications selects copy by token locale', () {
      final ts = File(
        'supabase/functions/process-filter-alert-notifications/index.ts',
      ).readAsStringSync();
      expect(ts, contains('filterAlertNotificationCopyForLocale'));
      expect(ts, contains('.select("id, token, locale")'));
      expect(ts, isNot(contains('listing_title')));
    });
  });
}
