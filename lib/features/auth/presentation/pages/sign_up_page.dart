import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

/// Minimal email + password sign-up.
///
/// The page is intentionally a thin shell over [AuthCubit]: it does not
/// own any auth state of its own, does not talk to Supabase, and does
/// not duplicate session bookkeeping already handled by
/// [AuthCubit.bootstrap]. It reacts to [AuthState] transitions:
///
///   * [AuthStatus.authenticated] → navigate to the listings feed.
///   * [AuthStatus.needsEmailConfirmation] → show a localized message
///     and leave the user on this page; the confirmation link will
///     establish the session and `onAuthStateChange` will handle the
///     transition.
///   * [AuthStatus.error] → surface a localized message via SnackBar.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
  }

  String? _validateEmail(AppLocalizations l10n, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.validationEmailRequired;
    if (!v.contains('@')) return l10n.validationEmailInvalid;
    return null;
  }

  String? _validatePassword(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
    if (value.length < 6) return l10n.validationPasswordMin;
    return null;
  }

  String? _validateConfirm(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.validationConfirmPassword;
    if (value != _passwordCtrl.text) return l10n.validationPasswordsDoNotMatch;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.signIn),
        title: Text(l10n.signUpTitle),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          switch (state.status) {
            case AuthStatus.authenticated:
              context.go(AppRoutes.listings);
            case AuthStatus.needsEmailConfirmation:
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(_authInfoMessage(l10n, state.infoKind)),
                  ),
                );
            case AuthStatus.error:
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(_signUpErrorMessage(l10n, state.errorKind)),
                  ),
                );
            case AuthStatus.unknown:
            case AuthStatus.authenticating:
            case AuthStatus.unauthenticated:
            case AuthStatus.passwordRecovery:
              break;
          }
        },
        builder: (context, state) {
          final loading = state.status == AuthStatus.authenticating;
          return SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.authFieldEmail,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      enabled: !loading,
                      validator: (v) => _validateEmail(l10n, v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.authFieldPassword,
                      ),
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      enabled: !loading,
                      validator: (v) => _validatePassword(l10n, v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.authFieldConfirmPassword,
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
                          : Text(l10n.signUpSubmit),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => context.go(AppRoutes.signIn),
                      child: Text(l10n.signUpHaveAccount),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => context.go(AppRoutes.legal),
                      child: Text(l10n.legalLink),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _authInfoMessage(AppLocalizations l10n, AuthInfoKind? kind) {
  return switch (kind) {
    AuthInfoKind.signUpConfirmEmail || null => l10n.signUpConfirmEmail,
  };
}

String _signUpErrorMessage(AppLocalizations l10n, AuthErrorKind? kind) {
  return switch (kind) {
    null => l10n.signUpFailedRetry,
    AuthErrorKind.signUpEmailTaken => l10n.userErrorEmailAlreadyRegistered,
    AuthErrorKind.signUpWeakPassword => l10n.userErrorWeakPassword,
    AuthErrorKind.networkConnectivity => l10n.userErrorNetworkCheckConnection,
    AuthErrorKind.signUpFailed => l10n.signUpFailedRetry,
    AuthErrorKind.signInInvalidCredentials => l10n.signInInvalidCredentials,
    AuthErrorKind.signInFailed => l10n.signInFailedRetry,
    AuthErrorKind.signOutFailed => l10n.signOutFailedRetry,
  };
}
