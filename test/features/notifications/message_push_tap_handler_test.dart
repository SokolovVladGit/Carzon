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
  _FakeOpenEvents() {
    openedApp = StreamController<RemoteMessage>.broadcast(
      onListen: () => openedAppListenerCount++,
      onCancel: () => openedAppCancellationCount++,
    );
  }

  RemoteMessage? initialMessageReply;
  Future<RemoteMessage?> Function()? getInitialMessageOverride;
  bool throwOnOpenedAppAccess = false;
  int getInitialMessageCalls = 0;
  int openedAppListenerCount = 0;
  int openedAppCancellationCount = 0;
  late final StreamController<RemoteMessage> openedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    getInitialMessageCalls++;
    final override = getInitialMessageOverride;
    if (override != null) {
      return override();
    }
    return initialMessageReply;
  }

  @override
  Stream<RemoteMessage> get onMessageOpenedApp {
    if (throwOnOpenedAppAccess) {
      throwOnOpenedAppAccess = false;
      throw StateError('temporary opened-app listener failure');
    }
    return openedApp.stream;
  }

  Future<void> close() async {
    await openedApp.close();
  }
}

final class _TapRetryHarness {
  _TapRetryHarness({
    required this.openEvents,
    required bool Function() firebaseAppReady,
  }) {
    conversationCoordinator = MessageConversationNavigationCoordinator(
      authStateStream: authStates.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: navigatedConversations.add,
    );
    listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authStates.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: navigatedListings.add,
    );
    handler = MessagePushTapHandler(
      navigationCoordinator: conversationCoordinator,
      listingNavigationCoordinator: listingCoordinator,
      openEvents: openEvents,
      firebaseAppReady: firebaseAppReady,
    );
  }

  final _FakeOpenEvents openEvents;
  final auth = const AuthState.authenticated(
    AuthUser(id: 'retry-user', email: 'retry@example.com'),
  );
  final authStates = StreamController<AuthState>.broadcast();
  final navigatedConversations = <String>[];
  final navigatedListings = <String>[];
  late final MessageConversationNavigationCoordinator conversationCoordinator;
  late final FilterAlertListingNavigationCoordinator listingCoordinator;
  late final MessagePushTapHandler handler;

  Future<void> dispose() async {
    await handler.dispose();
    await conversationCoordinator.dispose();
    await listingCoordinator.dispose();
    await openEvents.close();
    await authStates.close();
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

    test('discards account-bound navigation across auth boundary', () async {
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
      expect(navigated, isEmpty);

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

    test('valid price_drop initial opens listing when authenticated', () async {
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
          data: {'type': 'price_drop', 'listing_id': filterListingId},
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
    });

    test('malformed price_drop listing_id does not navigate', () async {
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
          data: {'type': 'price_drop', 'listing_id': 'x'},
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

    group('retryable startup', () {
      setUp(() {
        dotenv.testLoad(
          fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
        );
      });

      test(
        'Firebase unavailable remains idle and later handles initial message',
        () async {
          var firebaseReady = false;
          final fake = _FakeOpenEvents()
            ..initialMessageReply = RemoteMessage(
              data: {'type': 'message', 'conversation_id': okId},
            );
          final harness = _TapRetryHarness(
            openEvents: fake,
            firebaseAppReady: () => firebaseReady,
          );

          await harness.handler.start();
          expect(harness.handler.isStarted, isFalse);
          expect(fake.getInitialMessageCalls, 0);
          expect(fake.openedAppListenerCount, 0);

          firebaseReady = true;
          await harness.handler.start();
          expect(harness.handler.isStarted, isTrue);
          expect(fake.getInitialMessageCalls, 1);
          expect(fake.openedAppListenerCount, 1);
          expect(harness.navigatedConversations, [okId]);

          await harness.dispose();
        },
      );

      test(
        'listener setup failure remains retryable without initial replay',
        () async {
          final fake = _FakeOpenEvents()
            ..initialMessageReply = RemoteMessage(
              data: {'type': 'message', 'conversation_id': okId},
            )
            ..throwOnOpenedAppAccess = true;
          final harness = _TapRetryHarness(
            openEvents: fake,
            firebaseAppReady: () => true,
          );

          await harness.handler.start();
          expect(harness.handler.isStarted, isFalse);
          expect(fake.getInitialMessageCalls, 1);
          expect(harness.navigatedConversations, [okId]);
          expect(fake.openedAppListenerCount, 0);

          await harness.handler.start();
          expect(harness.handler.isStarted, isTrue);
          expect(fake.getInitialMessageCalls, 1);
          expect(harness.navigatedConversations, [okId]);
          expect(fake.openedAppListenerCount, 1);

          await harness.dispose();
        },
      );

      test(
        'concurrent starts share initial lookup and listener setup',
        () async {
          final initialGate = Completer<RemoteMessage?>();
          final fake = _FakeOpenEvents()
            ..getInitialMessageOverride = () => initialGate.future;
          final harness = _TapRetryHarness(
            openEvents: fake,
            firebaseAppReady: () => true,
          );

          final first = harness.handler.start();
          final second = harness.handler.start();
          expect(fake.getInitialMessageCalls, 1);
          expect(fake.openedAppListenerCount, 0);

          initialGate.complete();
          await Future.wait([first, second]);
          expect(harness.handler.isStarted, isTrue);
          expect(fake.getInitialMessageCalls, 1);
          expect(fake.openedAppListenerCount, 1);

          await harness.dispose();
        },
      );

      test('initial-message lookup failure retries and routes once', () async {
        var lookupAttempts = 0;
        final fake = _FakeOpenEvents()
          ..getInitialMessageOverride = () async {
            lookupAttempts++;
            if (lookupAttempts == 1) {
              throw StateError('temporary initial-message failure');
            }
            return RemoteMessage(
              data: {'type': 'message', 'conversation_id': okId},
            );
          };
        final harness = _TapRetryHarness(
          openEvents: fake,
          firebaseAppReady: () => true,
        );

        await harness.handler.start();
        expect(harness.handler.isStarted, isFalse);
        expect(fake.openedAppListenerCount, 0);
        expect(harness.navigatedConversations, isEmpty);

        await harness.handler.start();
        expect(harness.handler.isStarted, isTrue);
        expect(fake.getInitialMessageCalls, 2);
        expect(fake.openedAppListenerCount, 1);
        expect(harness.navigatedConversations, [okId]);

        await harness.dispose();
      });

      test(
        'repeated start does not replay initial or duplicate opened listener',
        () async {
          const openedId = 'cccccccc-cccc-4ccc-a789-cccccccccccc';
          final fake = _FakeOpenEvents()
            ..initialMessageReply = RemoteMessage(
              data: {'type': 'message', 'conversation_id': okId},
            );
          final harness = _TapRetryHarness(
            openEvents: fake,
            firebaseAppReady: () => true,
          );

          await harness.handler.start();
          await harness.handler.start();
          fake.openedApp.add(
            RemoteMessage(
              data: {'type': 'message', 'conversation_id': openedId},
            ),
          );
          await Future<void>.delayed(Duration.zero);

          expect(fake.getInitialMessageCalls, 1);
          expect(fake.openedAppListenerCount, 1);
          expect(harness.navigatedConversations, [okId, openedId]);

          await harness.dispose();
          expect(fake.openedAppCancellationCount, 1);
        },
      );

      test(
        'malformed initial payload is ignored without breaking startup',
        () async {
          final fake = _FakeOpenEvents()
            ..initialMessageReply = RemoteMessage(
              data: {'type': 'message', 'conversation_id': 'malformed'},
            );
          final harness = _TapRetryHarness(
            openEvents: fake,
            firebaseAppReady: () => true,
          );

          await harness.handler.start();
          expect(harness.handler.isStarted, isTrue);
          expect(harness.navigatedConversations, isEmpty);
          expect(harness.navigatedListings, isEmpty);
          expect(fake.openedAppListenerCount, 1);

          await harness.dispose();
        },
      );
    });
  });
}
