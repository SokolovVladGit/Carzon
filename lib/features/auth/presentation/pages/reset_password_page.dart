import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../bloc/reset_password_cubit.dart';
import '../bloc/reset_password_state.dart';

/// Set-new-password screen.
///
/// Gated on `AuthCubit.state.status == AuthStatus.passwordRecovery`.
/// Callers that reach this route without an active recovery session
/// see a clear instruction to open the reset-email link instead of a
/// usable form, so an arbitrary signed-in user cannot repurpose the
/// screen to bypass their current-password.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.signIn),
        title: Text(l10n.resetPasswordTitle),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, auth) {
          if (auth.status != AuthStatus.passwordRecovery) {
            return _NoRecoverySessionView(
              onBack: () => context.go(AppRoutes.signIn),
            );
          }
          return BlocProvider(
            create: (_) => sl<ResetPasswordCubit>(),
            child: const _ResetPasswordForm(),
          );
        },
      ),
    );
  }
}

class _NoRecoverySessionView extends StatelessWidget {
  const _NoRecoverySessionView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(CarzonIcons.keyReset, size: 48),
            const SizedBox(height: 16),
            Text(l10n.resetPasswordNoSession, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onBack, child: Text(l10n.backToSignIn)),
          ],
        ),
      ),
    );
  }
}

class _ResetPasswordForm extends StatefulWidget {
  const _ResetPasswordForm();

  @override
  State<_ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<_ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
    if (value.length < kMinPasswordLength) return l10n.validationPasswordMin;
    return null;
  }

  String? _validateConfirm(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.validationConfirmPassword;
    if (value != _passwordCtrl.text) return l10n.validationPasswordsDoNotMatch;
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ResetPasswordCubit>().submit(
      newPassword: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case ResetPasswordStatus.success:
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.resetPasswordSuccess)),
              );
            // Clear the latched recovery flag before navigating so the
            // rest of the app resumes normal auth routing.
            context.read<AuthCubit>().clearPasswordRecovery();
            context.go(AppRoutes.signIn);
          case ResetPasswordStatus.failure:
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    _resetPasswordFailureMessage(l10n, state.failureKind),
                  ),
                ),
              );
          case ResetPasswordStatus.idle:
          case ResetPasswordStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final loading = state.status == ResetPasswordStatus.submitting;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.resetPasswordIntro),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(labelText: l10n.resetPasswordNew),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !loading,
                  validator: (v) => _validatePassword(l10n, v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.resetPasswordConfirmNew,
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !loading,
                  validator: (v) => _validateConfirm(l10n, v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.resetPasswordSubmit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _resetPasswordFailureMessage(
  AppLocalizations l10n,
  ResetPasswordFailureKind? kind,
) {
  return switch (kind) {
    ResetPasswordFailureKind.emptyPassword => l10n.resetPasswordValidationNew,
    ResetPasswordFailureKind.passwordTooShort =>
      l10n.resetPasswordValidationMin(kMinPasswordLength),
    ResetPasswordFailureKind.mismatch => l10n.resetPasswordValidationMismatch,
    ResetPasswordFailureKind.updateFailed ||
    null => l10n.resetPasswordFailedRetry,
  };
}
