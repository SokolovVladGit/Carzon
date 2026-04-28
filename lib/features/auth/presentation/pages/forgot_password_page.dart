import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../bloc/forgot_password_cubit.dart';
import '../bloc/forgot_password_state.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.signIn),
        title: Text(l10n.forgotPasswordTitle),
      ),
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == ForgotPasswordStatus.failure,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(_forgotPasswordFailureMessage(l10n, state.failureKind)),
            ));
        },
        builder: (context, state) {
          final loading = state.status == ForgotPasswordStatus.submitting;

          if (state.status == ForgotPasswordStatus.success) {
            return _SuccessView(onBack: () => context.go(AppRoutes.signIn));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.forgotPasswordIntro),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.authFieldEmail),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    enabled: !loading,
                    validator: (v) => _validateEmail(l10n, v),
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
                        : Text(l10n.forgotPasswordSubmit),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        loading ? null : () => context.go(AppRoutes.signIn),
                    child: Text(l10n.backToSignIn),
                  ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Icon(CarzonIcons.mailCheck, size: 48),
          const SizedBox(height: 16),
          Text(
            l10n.forgotPasswordSuccess,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBack,
            child: Text(l10n.backToSignIn),
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
    ForgotPasswordFailureKind.requestFailed || null =>
      l10n.forgotPasswordFailedRetry,
  };
}
