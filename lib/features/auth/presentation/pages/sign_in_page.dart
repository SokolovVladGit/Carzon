import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.listings),
        title: Text(l10n.signInTitle),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(AppRoutes.listings);
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_authErrorMessage(l10n, state.errorKind))),
            );
          }
        },
        builder: (context, state) {
          final loading = state.status == AuthStatus.authenticating;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(labelText: l10n.authFieldEmail),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationEmailRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.authFieldPassword),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? l10n.validationPasswordMin
                        : null,
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
                        : Text(l10n.signInSubmit),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => context.go(AppRoutes.forgotPassword),
                    child: Text(l10n.signInForgotPassword),
                  ),
                  TextButton(
                    onPressed:
                        loading ? null : () => context.go(AppRoutes.signUp),
                    child: Text(l10n.signInCreateAccount),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed:
                        loading ? null : () => context.go(AppRoutes.legal),
                    child: Text(l10n.legalLink),
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

/// Maps an [AuthErrorKind] to a localized snackbar message. Exposed at
/// library level so shared auth flows can reuse it.
String _authErrorMessage(AppLocalizations l10n, AuthErrorKind? kind) {
  return switch (kind) {
    AuthErrorKind.signInInvalidCredentials => l10n.signInInvalidCredentials,
    AuthErrorKind.signInFailed || null => l10n.signInFailedRetry,
    AuthErrorKind.signUpFailed => l10n.signUpFailedRetry,
    AuthErrorKind.signOutFailed => l10n.signOutFailedRetry,
  };
}
