import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../bloc/forgot_password_cubit.dart';
import '../bloc/forgot_password_state.dart';
import '../widgets/auth_editorial_header.dart';
import '../widgets/auth_page_scaffold.dart';

/// Request-reset-email screen.
///
/// The page always shows a neutral, non-enumerating success
/// confirmation after the backend accepts the request, regardless of
/// whether an account exists for the submitted email. Only transport
/// / server failures surface as a snackbar.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForgotPasswordCubit>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(AppLocalizations l10n, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.validationEmailRequired;
    if (!v.contains('@')) return l10n.validationEmailInvalid;
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordCubit>().submit(_emailCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthPageScaffold(
      fallbackRoute: AppRoutes.signIn,
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == ForgotPasswordStatus.failure,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  _forgotPasswordFailureMessage(l10n, state.failureKind),
                ),
              ),
            );
        },
        builder: (context, state) {
          final loading = state.status == ForgotPasswordStatus.submitting;

          if (state.status == ForgotPasswordStatus.success) {
            return _SuccessView(
              onBack: () => context.go(AppRoutes.signIn),
            );
          }

          return AuthPageBody(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthEditorialHeader(
                  eyebrow: l10n.signInForgotPassword,
                  title: l10n.forgotPasswordTitle,
                  subtitle: l10n.forgotPasswordIntro,
                ),
                const SizedBox(height: 28),
                AuthFormSection(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: AuthFormStyles.fieldDecoration(
                            context,
                            l10n.authFieldEmail,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          enabled: !loading,
                          validator: (v) => _validateEmail(l10n, v),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          style: AuthFormStyles.primaryButtonStyle(context),
                          child: loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.forgotPasswordSubmit),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AuthFormSection.formMaxWidth,
                  ),
                  child: AuthLinkButton(
                    label: l10n.backToSignIn,
                    loading: loading,
                    onPressed: () => context.go(AppRoutes.signIn),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthPageBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthEditorialHeader(
            eyebrow: l10n.signInForgotPassword,
            title: l10n.forgotPasswordTitle,
          ),
          const SizedBox(height: 28),
          AuthFormSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  CarzonIcons.mailCheck,
                  size: 48,
                  color: scheme.onSurface.withValues(alpha: 0.88),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.forgotPasswordSuccess,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: onBack,
                  style: AuthFormStyles.primaryButtonStyle(context),
                  child: Text(l10n.backToSignIn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _forgotPasswordFailureMessage(
  AppLocalizations l10n,
  ForgotPasswordFailureKind? kind,
) {
  return switch (kind) {
    ForgotPasswordFailureKind.emptyEmail => l10n.forgotPasswordEmailEmpty,
    ForgotPasswordFailureKind.requestFailed ||
    null => l10n.forgotPasswordFailedRetry,
  };
}
