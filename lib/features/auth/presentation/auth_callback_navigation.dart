import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'bloc/auth_state.dart';
import 'pages/forgot_password_page.dart';

/// Routes a latched password-recovery session to [AppRoutes.resetPassword].
///
/// Safe to call before the first frame: [GoRouter.go] updates the route
/// information provider even when no navigator is mounted yet. Signup
/// confirmation stays off this path because it does not set
/// [AuthStatus.passwordRecovery].
void openPasswordResetIfRecovery(GoRouter router, AuthState state) {
  if (state.status != AuthStatus.passwordRecovery) return;
  final path = router.routeInformationProvider.value.uri.path;
  if (path == AppRoutes.resetPassword) return;
  router.go(AppRoutes.resetPassword);
}

/// Opens the request-new-email screen after a rejected recovery callback.
///
/// Returns false when that screen is already showing, so the caller can
/// surface the same message without a second navigation.
bool presentInvalidRecoveryLink(GoRouter router) {
  final path = router.routeInformationProvider.value.uri.path;
  if (path == AppRoutes.forgotPassword) return false;
  router.go(
    AppRoutes.forgotPassword,
    extra: const ForgotPasswordLaunch(invalidRecoveryLink: true),
  );
  return true;
}
