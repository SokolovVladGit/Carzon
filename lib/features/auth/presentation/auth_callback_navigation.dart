import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'bloc/auth_state.dart';

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
