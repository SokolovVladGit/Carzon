import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/app_locale_cubit.dart';
import '../../../core/config/env.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/presentation/bloc/auth_cubit.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../data/datasources/notifications_remote_datasource.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/repositories/notifications_repository.dart';
import '../presentation/cubit/notification_settings_cubit.dart';
import '../services/carzon_message_local_notifications_display.dart';
import '../services/filter_alert_listing_navigation_coordinator.dart';
import '../services/firebase_push_messaging_client.dart';
import '../services/message_conversation_navigation_coordinator.dart';
import '../services/message_foreground_notification_display.dart';
import '../services/message_foreground_notification_presenter.dart';
import '../services/message_push_tap_handler.dart';
import '../services/noop_message_foreground_notification_display.dart';
import '../services/noop_push_messaging_client.dart';
import '../services/push_auth_gate.dart';
import '../services/push_messaging_client.dart';
import '../services/push_notification_registration_service.dart';

void registerNotificationsFeature(GetIt sl) {
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => SupabaseNotificationsRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl<NotificationsRemoteDataSource>()),
  );
  sl.registerLazySingleton<PushAuthGate>(
    () => SupabasePushAuthGate(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<PushMessagingClient>(
    () => Env.pushNotificationsEnabled
        ? FirebasePushMessagingClient()
        : NoopPushMessagingClient(),
  );
  sl.registerLazySingleton<PushNotificationRegistrationService>(
    () => PushNotificationRegistrationService(
      messagingClient: sl<PushMessagingClient>(),
      notificationsRepository: sl<NotificationsRepository>(),
      authGate: sl<PushAuthGate>(),
      readAuthenticatedUserId: () {
        final auth = sl<AuthCubit>().state;
        return auth.status == AuthStatus.authenticated ? auth.user?.id : null;
      },
      readLocalePreference: () => sl<AppLocaleCubit>().state.preference,
    ),
  );

  sl.registerLazySingleton<MessageConversationNavigationCoordinator>(() {
    final auth = sl<AuthCubit>();
    return MessageConversationNavigationCoordinator(
      authStateStream: auth.stream,
      authStateSnapshot: () => auth.state,
      navigateToConversation: (conversationId) {
        sl<GoRouter>().go(AppRoutes.messagesThreadPath(conversationId));
      },
    );
  });

  sl.registerLazySingleton<FilterAlertListingNavigationCoordinator>(() {
    final auth = sl<AuthCubit>();
    return FilterAlertListingNavigationCoordinator(
      authStateStream: auth.stream,
      authStateSnapshot: () => auth.state,
      navigateToListingDetail: (listingId) {
        sl<GoRouter>().go(AppRoutes.listingDetailsPath(listingId));
      },
    );
  });

  sl.registerLazySingleton<MessagePushTapHandler>(
    () => MessagePushTapHandler(
      navigationCoordinator: sl<MessageConversationNavigationCoordinator>(),
      listingNavigationCoordinator:
          sl<FilterAlertListingNavigationCoordinator>(),
    ),
  );

  sl.registerLazySingleton<MessageForegroundNotificationDisplay>(
    () => Env.pushNotificationsEnabled
        ? CarzonMessageLocalNotificationsDisplay(
            onConversationNotificationTap: (conversationId) {
              sl<MessageConversationNavigationCoordinator>().requestOpenThread(
                conversationId,
              );
            },
            onFilterAlertNotificationTap: (listingId) {
              sl<FilterAlertListingNavigationCoordinator>().requestOpenListing(
                listingId,
              );
            },
            onPriceDropNotificationTap: (listingId) {
              sl<FilterAlertListingNavigationCoordinator>().requestOpenListing(
                listingId,
              );
            },
            readLocalePreference: () => sl<AppLocaleCubit>().state.preference,
          )
        : const NoopMessageForegroundNotificationDisplay(),
  );

  sl.registerLazySingleton<MessageForegroundNotificationPresenter>(
    () => MessageForegroundNotificationPresenter(
      navigationCoordinator: sl<MessageConversationNavigationCoordinator>(),
      listingNavigationCoordinator:
          sl<FilterAlertListingNavigationCoordinator>(),
      display: sl<MessageForegroundNotificationDisplay>(),
      syncMessageUnread: () =>
          sl<MessagingUnreadSummaryCubit>().sync(sl<AuthCubit>().state),
    ),
  );

  sl.registerFactory<NotificationSettingsCubit>(
    () => NotificationSettingsCubit(
      notificationsRepository: sl<NotificationsRepository>(),
      pushRegistration: sl<PushNotificationRegistrationService>(),
    ),
  );
}
