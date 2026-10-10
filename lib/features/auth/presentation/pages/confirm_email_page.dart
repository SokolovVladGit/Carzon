import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../bloc/confirm_email_cubit.dart';
import '../bloc/confirm_email_state.dart';
import '../widgets/auth_editorial_header.dart';
import '../widgets/auth_page_scaffold.dart';

/// Shown after signup when Supabase did not issue a session.
///
/// The confirmation link is handled by [AuthDeepLinkService]. A resulting
/// signed-in session (not password recovery) leaves this page for Home.
class ConfirmEmailPage extends StatelessWidget {
  const ConfirmEmailPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConfirmEmailCubit>(param1: email),
      child: const _ConfirmEmailView(),
    );
  }
}

class _ConfirmEmailView extends StatelessWidget {
  const _ConfirmEmailView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = context.read<ConfirmEmailCubit>().email;

    return AuthPageScaffold(
      fallbackRoute: AppRoutes.signIn,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) =>
                prev.status != curr.status &&
                curr.status == AuthStatus.authenticated,
            listener: (context, _) => context.go(AppRoutes.listings),
          ),
          BlocListener<ConfirmEmailCubit, ConfirmEmailState>(
            listenWhen: (prev, curr) => prev != curr,
            listener: (context, state) {
              final message = switch (state.status) {
                ConfirmEmailStatus.success => l10n.confirmEmailResendSuccess,
                ConfirmEmailStatus.failure => _resendFailureMessage(
                  l10n,
                  state.failureKind,
                ),
                ConfirmEmailStatus.idle ||
                ConfirmEmailStatus.submitting => null,
              };
              if (message == null) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            },
          ),
        ],
        child: BlocBuilder<ConfirmEmailCubit, ConfirmEmailState>(
          builder: (context, state) {
            final loading = state.status == ConfirmEmailStatus.submitting;
            return AuthPageBody(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthEditorialHeader(
                    eyebrow: l10n.confirmEmailEyebrow,
                    title: l10n.confirmEmailTitle,
                  ),
                  const SizedBox(height: 28),
                  AuthFormSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.confirmEmailSentTo,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          key: const Key('confirm-email-address'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.confirmEmailInstructions,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: loading
                              ? null
                              : () =>
                                    context.read<ConfirmEmailCubit>().resend(),
                          style: AuthFormStyles.primaryButtonStyle(context),
                          child: loading
                              ? const SizedBox(
                                  key: Key('confirm-email-resend-loading'),
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.confirmEmailResend),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AuthLinkButton(
                    label: l10n.backToSignIn,
                    onPressed: () => context.go(AppRoutes.signIn),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _resendFailureMessage(
  AppLocalizations l10n,
  ConfirmEmailFailureKind? kind,
) {
  return switch (kind) {
    ConfirmEmailFailureKind.rateLimited => l10n.confirmEmailResendRateLimited,
    ConfirmEmailFailureKind.failed || null => l10n.confirmEmailResendFailed,
  };
}
