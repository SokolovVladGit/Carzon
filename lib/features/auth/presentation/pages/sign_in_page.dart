import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_editorial_header.dart';
import '../widgets/auth_page_scaffold.dart';

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

    return AuthPageScaffold(
      fallbackRoute: AppRoutes.listings,
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
          return AuthPageBody(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthEditorialHeader(
                  eyebrow: l10n.signInEyebrow,
                  title: l10n.signInTitle,
                  subtitle: l10n.signInSubtitle,
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.validationEmailRequired
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: AuthFormStyles.fieldDecoration(
                            context,
                            l10n.authFieldPassword,
                          ),
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          enabled: !loading,
                          validator: (v) => (v == null || v.length < 6)
                              ? l10n.validationPasswordMin
                              : null,
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
                              : Text(l10n.signInSubmit),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthLinkButton(
                        label: l10n.signInForgotPassword,
                        loading: loading,
                        onPressed: () => context.go(AppRoutes.forgotPassword),
                      ),
                      const SizedBox(height: 4),
                      AuthLinkButton(
                        label: l10n.signInCreateAccount,
                        loading: loading,
                        accent: true,
                        onPressed: () => context.go(AppRoutes.signUp),
                      ),
                      const SizedBox(height: 18),
                      AuthLinkButton(
                        label: l10n.legalLink,
                        loading: loading,
                        muted: true,
                        onPressed: () => context.go(AppRoutes.terms),
                      ),
                    ],
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

/// Maps an [AuthErrorKind] to a localized snackbar message. Exposed at
/// library level so shared auth flows can reuse it.
String _authErrorMessage(AppLocalizations l10n, AuthErrorKind? kind) {
  return switch (kind) {
    null => l10n.signInFailedRetry,
    AuthErrorKind.signInInvalidCredentials => l10n.signInInvalidCredentials,
    AuthErrorKind.networkConnectivity => l10n.userErrorNetworkCheckConnection,
    AuthErrorKind.signInFailed => l10n.signInFailedRetry,
    AuthErrorKind.signUpFailed => l10n.signUpFailedRetry,
    AuthErrorKind.signUpEmailTaken => l10n.userErrorEmailAlreadyRegistered,
    AuthErrorKind.signUpWeakPassword => l10n.userErrorWeakPassword,
    AuthErrorKind.signOutFailed => l10n.signOutFailedRetry,
  };
}
