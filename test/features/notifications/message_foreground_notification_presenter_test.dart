import 'dart:async';

import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/notifications/services/filter_alert_listing_navigation_coordinator.dart';
import 'package:carzon/features/notifications/services/filter_alert_notification_public_copy.dart';
import 'package:carzon/features/notifications/services/message_conversation_navigation_coordinator.dart';
import 'package:carzon/features/notifications/services/message_foreground_notification_display.dart';
import 'package:carzon/features/notifications/services/message_foreground_notification_presenter.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/features/notifications/services/message_notification_public_copy.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingDisplay implements MessageForegroundNotificationDisplay {
  int initCount = 0;
  final List<String> shownConversationIds = [];
  final List<String> shownListingIds = [];
  final List<String> titles = [];
  final List<String> bodies = [];

  @override
  Future<void> initialize() async {
    initCount++;
  }

  @override
  Future<void> showMessageForegroundNotification(String conversationId) async {
    shownConversationIds.add(conversationId);
    titles.add(MessageNotificationPublicCopy.title(AppLocalePreference.ru));
    bodies.add(MessageNotificationPublicCopy.body(AppLocalePreference.ru));
  }

  @override
  Future<void> showFilterAlertForegroundNotification(String listingId) async {
    shownListingIds.add(listingId);
    titles.add(FilterAlertNotificationPublicCopy.title(AppLocalePreference.ru));
    bodies.add(FilterAlertNotificationPublicCopy.body(AppLocalePreference.ru));
  }
}

void main() {
  const okId = 'cccccccc-cccc-4ccc-a789-cccccccccccc';
  const listingOkId = 'ffffffff-ffff-4fff-a123-ffffffffffff';
  final user = AuthUser(id: 'u1', email: 'a@b.c');

  tearDown(() async {
    dotenv.testLoad(fileInput: '');
  });

  test('push disabled: no init and no show', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(data: {'type': 'message', 'conversation_id': okId}),
    );
    await Future<void>.delayed(Duration.zero);

    expect(display.initCount, 0);
    expect(display.shownConversationIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('valid foreground message shows generic copy only', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    expect(display.initCount, 1);

    opened.add(
      RemoteMessage(
        data: {
          'type': 'message',
          'conversation_id': okId,
          'message_id': 'dddddddd-dddd-4ddd-a123-dddddddddddd',
          'listing_id': 'eeeeeeee-eeee-4eee-b123-eeeeeeeeeeee',
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(display.shownConversationIds, [okId]);
    expect(
      display.titles,
      everyElement(MessageNotificationPublicCopy.title(AppLocalePreference.ru)),
    );
    expect(
      display.bodies,
      everyElement(MessageNotificationPublicCopy.body(AppLocalePreference.ru)),
    );
    expect(
      display.titles.join(),
      isNot(contains('@')),
      reason: 'must not surface email-like content in title',
    );
    expect(display.bodies.join(), isNot(contains('secret body')));

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('unknown type ignored', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(RemoteMessage(data: {'type': 'other', 'conversation_id': okId}));
    await Future<void>.delayed(Duration.zero);
    expect(display.shownConversationIds, isEmpty);
    expect(display.shownListingIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('malformed conversation_id ignored', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(data: {'type': 'message', 'conversation_id': 'bad'}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(display.shownConversationIds, isEmpty);
    expect(display.shownListingIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test(
    'valid foreground filter_alert shows generic Russian copy only',
    () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
      var auth = AuthState.authenticated(user);
      final authEmitter = StreamController<AuthState>.broadcast();
      final display = _RecordingDisplay();

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: (_) {},
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: (_) {},
      );

      final opened = StreamController<RemoteMessage>.broadcast();
      final presenter = MessageForegroundNotificationPresenter(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        display: display,
        foregroundMessageStream: opened.stream,
        firebaseAppReady: () => true,
      );

      await presenter.start();
      opened.add(
        RemoteMessage(
          data: {
            'type': 'filter_alert',
            'listing_id': listingOkId,
            'title': 'Secret title',
            'price': '999999',
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(display.shownListingIds, [listingOkId]);
      expect(display.shownConversationIds, isEmpty);
      expect(display.titles, [
        FilterAlertNotificationPublicCopy.title(AppLocalePreference.ru),
      ]);
      expect(display.bodies, [
        FilterAlertNotificationPublicCopy.body(AppLocalePreference.ru),
      ]);
      expect(display.bodies.join(), isNot(contains('Secret')));

      await presenter.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await opened.close();
      await authEmitter.close();
    },
  );

  test('malformed filter_alert listing_id ignored', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(data: {'type': 'filter_alert', 'listing_id': 'bad'}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(display.shownListingIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });
}
