import 'dart:async';

import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/notifications/services/firebase_messaging_open_events.dart';
import 'package:carzon/features/notifications/services/filter_alert_listing_navigation_coordinator.dart';
import 'package:carzon/features/notifications/services/message_conversation_navigation_coordinator.dart';
import 'package:carzon/features/notifications/services/message_notification_tap_payload.dart';
import 'package:carzon/features/notifications/services/message_push_tap_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOpenEvents implements FirebaseMessagingOpenEvents {
  _FakeOpenEvents();

  RemoteMessage? initialMessageReply;
  int getInitialMessageCalls = 0;
  final StreamController<RemoteMessage> openedApp =
      StreamController<RemoteMessage>.broadcast();

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    getInitialMessageCalls++;
    return initialMessageReply;
  }

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => openedApp.stream;

  Future<void> close() async {
    await openedApp.close();
  }
}

void main() {
  group('parseMessageNotificationTapPayload', () {
    const okId = 'aaaaaaaa-bbbb-4ccc-a123-aaaaaaaaaaaa';

    test('accepts type message with conversation_id', () {
      final p = parseMessageNotificationTapPayload({
        'type': 'message',
        'conversation_id': okId,
      });
      expect(p, isNotNull);
      expect(p!.conversationId, okId);
    });

    test('accepts type message_created', () {
      final p = parseMessageNotificationTapPayload({
        'type': 'message_created',
        'conversation_id': okId,
      });
      expect(p, isNotNull);
    });

    test('accepts omitted type when conversation_id is valid', () {
      final p = parseMessageNotificationTapPayload({'conversation_id': okId});
      expect(p, isNotNull);
    });

    test('rejects unknown type', () {
      expect(
        parseMessageNotificationTapPayload({
          'type': 'filter_alert',
          'conversation_id': okId,
        }),
        isNull,
      );
    });

    test('rejects malformed conversation_id', () {
      expect(
        parseMessageNotificationTapPayload({
          'type': 'message',
          'conversation_id': 'not-a-uuid',
        }),
        isNull,
      );
    });
  });

  group('MessagePushTapHandler', () {
    const okId = 'bbbbbbbb-bbbb-4ccc-b456-bbbbbbbbbbbb';
    const filterListingId = 'ffffffff-ffff-4fff-a123-ffffffffffff';
    final user = AuthUser(id: 'u1', email: 'a@b.c');

    tearDown(() async {
      dotenv.testLoad(fileInput: '');
    });

    test('push disabled: start does not touch open events', () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
      );
      final fake = _FakeOpenEvents();
      var auth = const AuthState.unauthenticated();
      final authEmitter = StreamController<AuthState>.broadcast();
      final navigated = <String>[];

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: navigated.add,
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: (_) {},
      );

      final handler = MessagePushTapHandler(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        openEvents: fake,
        firebaseAppReady: () => true,
      );

      await handler.start();
      expect(fake.getInitialMessageCalls, 0);
      expect(navigated, isEmpty);
      await handler.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await fake.close();
      await authEmitter.close();
    });

    test('valid initial message navigates when authenticated', () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
      var auth = AuthState.authenticated(user);
      final fake = _FakeOpenEvents()
        ..initialMessageReply = RemoteMessage(
          data: {'type': 'message', 'conversation_id': okId},
        );
      final authEmitter = StreamController<AuthState>.broadcast();
      final navigated = <String>[];

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: navigated.add,
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: (_) {},
      );

      final handler = MessagePushTapHandler(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        openEvents: fake,
        firebaseAppReady: () => true,
      );

      await handler.start();
      expect(fake.getInitialMessageCalls, 1);
      expect(navigated, [okId]);

      await handler.start();
      expect(fake.getInitialMessageCalls, 1);

      await handler.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await fake.close();
      await authEmitter.close();
    });

    test(
      'valid filter_alert initial opens listing when authenticated',
      () async {
        dotenv.testLoad(
          fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
        );
        var auth = AuthState.authenticated(user);
        final fake = _FakeOpenEvents()
          ..initialMessageReply = RemoteMessage(
            data: {'type': 'filter_alert', 'listing_id': filterListingId},
          );
        final authEmitter = StreamController<AuthState>.broadcast();
        final navigated = <String>[];
        final navigatedListings = <String>[];

        final coordinator = MessageConversationNavigationCoordinator(
          authStateStream: authEmitter.stream,
          authStateSnapshot: () => auth,
          navigateToConversation: navigated.add,
        );
        final listingCoordinator = FilterAlertListingNavigationCoordinator(
          authStateStream: authEmitter.stream,
          authStateSnapshot: () => auth,
          navigateToListingDetail: navigatedListings.add,
        );

        final handler = MessagePushTapHandler(
          navigationCoordinator: coordinator,
          listingNavigationCoordinator: listingCoordinator,
          openEvents: fake,
          firebaseAppReady: () => true,
        );

        await handler.start();
        expect(navigatedListings, [filterListingId]);
        expect(navigated, isEmpty);

        await handler.dispose();
        await coordinator.dispose();
        await listingCoordinator.dispose();
        await fake.close();
        await authEmitter.close();
      },
    );

    test('malformed filter_alert listing_id does not navigate', () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
      var auth = AuthState.authenticated(user);
      final fake = _FakeOpenEvents()
        ..initialMessageReply = RemoteMessage(
          data: {'type': 'filter_alert', 'listing_id': 'x'},
        );
      final authEmitter = StreamController<AuthState>.broadcast();
      final navigated = <String>[];
      final navigatedListings = <String>[];

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: navigated.add,
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: navigatedListings.add,
      );

      final handler = MessagePushTapHandler(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        openEvents: fake,
        firebaseAppReady: () => true,
      );

      await handler.start();
      expect(navigatedListings, isEmpty);
      expect(navigated, isEmpty);

      await handler.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await fake.close();
      await authEmitter.close();
    });

    test('defers navigation until authenticated', () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
      var auth = const AuthState.unauthenticated();
      final fake = _FakeOpenEvents()
        ..initialMessageReply = RemoteMessage(
          data: {'type': 'message', 'conversation_id': okId},
        );
      final authEmitter = StreamController<AuthState>.broadcast();
      final navigated = <String>[];

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: navigated.add,
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: (_) {},
      );

      final handler = MessagePushTapHandler(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        openEvents: fake,
        firebaseAppReady: () => true,
      );

      await handler.start();
      expect(navigated, isEmpty);

      auth = AuthState.authenticated(user);
      authEmitter.add(auth);
      await Future<void>.delayed(Duration.zero);
      expect(navigated, [okId]);

      await handler.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await fake.close();
      await authEmitter.close();
    });

    test('malformed initial message does not navigate', () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
      var auth = AuthState.authenticated(user);
      final fake = _FakeOpenEvents()
        ..initialMessageReply = RemoteMessage(
          data: {'type': 'message', 'conversation_id': 'x'},
        );

      final authEmitter = StreamController<AuthState>.broadcast();
      final navigated = <String>[];

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: navigated.add,
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: (_) {},
      );

      final handler = MessagePushTapHandler(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        openEvents: fake,
        firebaseAppReady: () => true,
      );

      await handler.start();
      expect(navigated, isEmpty);

      await handler.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await fake.close();
      await authEmitter.close();
    });

    test('dedupes duplicate opened-app taps within 1s', () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
      var auth = AuthState.authenticated(user);
      final fake = _FakeOpenEvents();
      final authEmitter = StreamController<AuthState>.broadcast();
      final navigated = <String>[];

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: navigated.add,
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: (_) {},
      );

      final handler = MessagePushTapHandler(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        openEvents: fake,
        firebaseAppReady: () => true,
      );

      await handler.start();
      final msg = RemoteMessage(
        data: {'type': 'message', 'conversation_id': okId},
      );
      fake.openedApp.add(msg);
      fake.openedApp.add(msg);
      await Future<void>.delayed(Duration.zero);
      expect(navigated.length, 1);

      await handler.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await fake.close();
      await authEmitter.close();
    });
  });
}
