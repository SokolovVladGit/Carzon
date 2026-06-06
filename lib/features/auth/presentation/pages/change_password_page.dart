import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../bloc/change_password_cubit.dart';
import '../bloc/change_password_state.dart';
import '../bloc/reset_password_cubit.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.profile),
        title: Text(l10n.changePasswordTitle),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, auth) {
          if (auth.status != AuthStatus.authenticated || auth.user == null) {
            return AuthRequiredPrompt(
              icon: const Icon(CarzonIcons.lock, size: 48),
              message: l10n.profileSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: () => context.go(AppRoutes.signIn),
            );
          }
          return BlocProvider(
            create: (_) => sl<ChangePasswordCubit>(),
            child: _ChangePasswordForm(email: auth.user!.email),
          );
        },
      ),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.email});

  final String email;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _showCurrentPassword = false;
  var _showNewPassword = false;
  var _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validateCurrent(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
    return null;
  }

  String? _validateNew(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
    if (value.length < kMinPasswordLength) return l10n.validationPasswordMin;
    return null;
  }

  String? _validateConfirm(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.validationConfirmPassword;
    if (value != _newPassword.text) return l10n.validationPasswordsDoNotMatch;
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ChangePasswordCubit>().submit(
      email: widget.email,
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
      confirmPassword: _confirmPassword.text,
    );
  }

  void _clearFields() {
    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fieldDecoration = _PasswordFieldDecoration(scheme);
    return BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ChangePasswordStatus.success:
            _clearFields();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.changePasswordSuccess)),
              );
            context.read<ChangePasswordCubit>().reset();
            break;
          case ChangePasswordStatus.failure:
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    _changePasswordFailureMessage(l10n, state.failureKind),
                  ),
                ),
              );
            break;
          case ChangePasswordStatus.idle:
          case ChangePasswordStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final loading = state.status == ChangePasswordStatus.submitting;
        return SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ChangePasswordHeaderCard(
                  title: l10n.changePasswordTitle,
                  subtitle: l10n.changePasswordIntro,
                ),
                const SizedBox(height: 14),
                _ChangePasswordFormCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _currentPassword,
                          decoration: fieldDecoration.copyWith(
                            labelText: l10n.changePasswordCurrentPassword,
                            suffixIcon: _PasswordVisibilityButton(
                              key: const ValueKey(
                                'change_password_current_visibility_toggle',
                              ),
                              visible: _showCurrentPassword,
                              onPressed: loading
                                  ? null
                                  : () => setState(() {
                                      _showCurrentPassword =
                                          !_showCurrentPassword;
                                    }),
                            ),
                          ),
                          obscureText: !_showCurrentPassword,
                          autofillHints: const [AutofillHints.password],
                          enabled: !loading,
                          validator: (value) => _validateCurrent(l10n, value),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _newPassword,
                          decoration: fieldDecoration.copyWith(
                            labelText: l10n.changePasswordNewPassword,
                            suffixIcon: _PasswordVisibilityButton(
                              key: const ValueKey(
                                'change_password_new_visibility_toggle',
                              ),
                              visible: _showNewPassword,
                              onPressed: loading
                                  ? null
                                  : () => setState(() {
                                      _showNewPassword = !_showNewPassword;
                                    }),
                            ),
                          ),
                          obscureText: !_showNewPassword,
                          autofillHints: const [AutofillHints.newPassword],
                          enabled: !loading,
                          validator: (value) => _validateNew(l10n, value),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPassword,
                          decoration: fieldDecoration.copyWith(
                            labelText: l10n.changePasswordConfirmPassword,
                            suffixIcon: _PasswordVisibilityButton(
                              key: const ValueKey(
                                'change_password_confirm_visibility_toggle',
                              ),
                              visible: _showConfirmPassword,
                              onPressed: loading
                                  ? null
                                  : () => setState(() {
                                      _showConfirmPassword =
                                          !_showConfirmPassword;
                                    }),
                            ),
                          ),
                          obscureText: !_showConfirmPassword,
                          autofillHints: const [AutofillHints.newPassword],
                          enabled: !loading,
                          validator: (value) => _validateConfirm(l10n, value),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.changePasswordSubmit),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.changePasswordSecurityNote,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.76,
                                ),
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChangePasswordHeaderCard extends StatelessWidget {
  const _ChangePasswordHeaderCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return _ChangePasswordCardShell(
      child: Padding(
        key: const ValueKey('change_password_header_card'),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: isDark ? 0.24 : 0.16),
                    scheme.tertiary.withValues(alpha: isDark ? 0.13 : 0.08),
                  ],
                ),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.16),
                ),
              ),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(CarzonIcons.lock, color: scheme.primary, size: 21),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordFormCard extends StatelessWidget {
  const _ChangePasswordFormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ChangePasswordCardShell(
      child: Padding(
        key: const ValueKey('change_password_form_card'),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ChangePasswordCardShell extends StatelessWidget {
  const _ChangePasswordCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.07),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ];
    final fill = isDark
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            scheme.surfaceTint.withValues(alpha: 0.035),
            scheme.surfaceContainerLowest,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: shadow,
      ),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.13),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
      color: scheme.onSurfaceVariant.withValues(alpha: 0.66),
    );
  }
}

class _PasswordFieldDecoration extends InputDecoration {
  _PasswordFieldDecoration(ColorScheme scheme)
    : super(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.65)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
      );
}

String _changePasswordFailureMessage(
  AppLocalizations l10n,
  ChangePasswordFailureKind? kind,
) {
  return switch (kind) {
    ChangePasswordFailureKind.emptyCurrentPassword =>
      l10n.validationPasswordRequired,
    ChangePasswordFailureKind.emptyNewPassword =>
      l10n.validationPasswordRequired,
    ChangePasswordFailureKind.passwordTooShort => l10n.validationPasswordMin,
    ChangePasswordFailureKind.mismatch => l10n.validationPasswordsDoNotMatch,
    ChangePasswordFailureKind.currentPasswordInvalid =>
      l10n.changePasswordCurrentInvalid,
    ChangePasswordFailureKind.updateFailed ||
    null => l10n.changePasswordFailedRetry,
  };
}
