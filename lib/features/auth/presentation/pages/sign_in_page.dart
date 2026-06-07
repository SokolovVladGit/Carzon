import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_editorial_header.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  static const double _horizontalPadding = 24;

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
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final canvasColors = light
        ? [
            Color.alphaBlend(
              scheme.surfaceContainerLow.withValues(alpha: 0.45),
              scheme.surface,
            ),
            scheme.surface,
          ]
        : AppTheme.editorialDarkFilterCanvasGradient(scheme);
    final canvasTop = canvasColors.first;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: canvasTop,
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.listings),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        iconTheme: IconThemeData(
          color: scheme.onSurface.withValues(alpha: light ? 0.88 : 0.92),
        ),
        systemOverlayStyle: light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: canvasColors,
            stops: light ? const [0, 0.55] : const [0, 0.35, 1],
          ),
        ),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              context.go(AppRoutes.listings);
            } else if (state.status == AuthStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_authErrorMessage(l10n, state.errorKind)),
                ),
              );
            }
          },
          builder: (context, state) {
            final loading = state.status == AuthStatus.authenticating;
            return SafeArea(
              minimum: EdgeInsets.only(top: kToolbarHeight),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _emailCtrl,
                                        decoration:
                                            AuthFormStyles.fieldDecoration(
                                              context,
                                              l10n.authFieldEmail,
                                            ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        enabled: !loading,
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                            ? l10n.validationEmailRequired
                                            : null,
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _passwordCtrl,
                                        decoration:
                                            AuthFormStyles.fieldDecoration(
                                              context,
                                              l10n.authFieldPassword,
                                            ),
                                        obscureText: true,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        enabled: !loading,
                                        validator: (v) =>
                                            (v == null || v.length < 6)
                                            ? l10n.validationPasswordMin
                                            : null,
                                      ),
                                      const SizedBox(height: 22),
                                      FilledButton(
                                        onPressed: loading ? null : _submit,
                                        style:
                                            AuthFormStyles.primaryButtonStyle(
                                              context,
                                            ),
                                        child: loading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
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
                              _SignInSecondaryActions(
                                loading: loading,
                                onForgotPassword: () =>
                                    context.go(AppRoutes.forgotPassword),
                                onCreateAccount: () =>
                                    context.go(AppRoutes.signUp),
                                onLegal: () => context.go(AppRoutes.legal),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignInSecondaryActions extends StatelessWidget {
  const _SignInSecondaryActions({
    required this.loading,
    required this.onForgotPassword,
    required this.onCreateAccount,
    required this.onLegal,
  });

  final bool loading;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;
  final VoidCallback onLegal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    final accent = light
        ? scheme.primary
        : AppTheme.editorialAccentColor(scheme);
    final compactLinkPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AuthFormSection.formMaxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: loading ? null : onForgotPassword,
            style: TextButton.styleFrom(
              padding: compactLinkPadding,
              foregroundColor: scheme.onSurfaceVariant.withValues(
                alpha: light ? 0.82 : 0.88,
              ),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n.signInForgotPassword),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: loading ? null : onCreateAccount,
            style: TextButton.styleFrom(
              padding: compactLinkPadding,
              foregroundColor: accent.withValues(alpha: light ? 0.9 : 0.96),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.signInCreateAccount),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: loading ? null : onLegal,
            style: TextButton.styleFrom(
              padding: compactLinkPadding,
              foregroundColor: scheme.onSurfaceVariant.withValues(
                alpha: light ? 0.62 : 0.68,
              ),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.02,
              ),
            ),
            child: Text(l10n.legalLink),
          ),
        ],
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
