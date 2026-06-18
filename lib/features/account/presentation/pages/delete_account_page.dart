import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../messaging/domain/usecases/get_or_create_support_conversation.dart';
import '../../../messaging/presentation/utils/support_conversation_user_messages.dart';
import '../../../profile/presentation/widgets/profile_grouped_card.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';

/// Destructive account deletion screen with typed confirmation.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  String _failureMessage(BuildContext context, DeleteAccountFailureKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      DeleteAccountFailureKind.network => l10n.deleteAccountErrorNetwork,
      DeleteAccountFailureKind.sessionExpired => l10n.deleteAccountErrorSession,
      DeleteAccountFailureKind.generic => l10n.deleteAccountErrorGeneric,
    };
  }

  Future<void> _openSupport(BuildContext context) async {
    final result = await sl<GetOrCreateSupportConversation>().call();
    if (!context.mounted) return;
    switch (result) {
      case Success(:final value):
        await context.push(AppRoutes.messagesThreadPath(value));
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              supportConversationOpenFailureMessage(context.l10n, failure),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyword = l10n.deleteAccountConfirmationKeyword.trim();

    return BlocProvider(
      create: (_) => sl<DeleteAccountCubit>(),
      child: BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == DeleteAccountStatus.success) {
            context
                .read<AuthCubit>()
                .markUnauthenticatedAfterAccountDeletion();
            context.go(AppRoutes.listings);
            return;
          }
          if (state.status == DeleteAccountStatus.failure &&
              state.failureKind != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    _failureMessage(context, state.failureKind!),
                  ),
                  action: SnackBarAction(
                    label: l10n.contactSupport,
                    onPressed: () => _openSupport(context),
                  ),
                ),
              );
          }
        },
        builder: (context, deleteState) {
          final processing =
              deleteState.status == DeleteAccountStatus.loading;
          final typed = _confirmationMatches(
            _confirmationController.text,
            keyword,
          );
          final canSubmit = typed && !processing;

          return Scaffold(
            backgroundColor: _deletePageBackground(context),
            appBar: AppBar(
              leading: const AppBackButton(fallback: AppRoutes.settings),
              title: Text(l10n.deleteAccountTitle),
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              foregroundColor: scheme.onSurface,
              systemOverlayStyle: isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
            ),
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _deleteCanvasGradient(context),
                  stops: const [0, 0.42, 1],
                ),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileGroupedCard(
                      childPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: scheme.error.withValues(alpha: 0.92),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.deleteAccountWarningTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.96,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.deleteAccountWarningBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: isDark ? 0.82 : 0.88,
                              ),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.deleteAccountConfirmationPrompt(keyword),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: isDark ? 0.78 : 0.84,
                        ),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('delete_account_confirmation_field'),
                      controller: _confirmationController,
                      enabled: !processing,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: keyword,
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withValues(
                          alpha: isDark ? 0.55 : 0.72,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      key: const ValueKey('delete_account_submit_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        disabledBackgroundColor: scheme.error.withValues(
                          alpha: 0.38,
                        ),
                        disabledForegroundColor: scheme.onError.withValues(
                          alpha: 0.72,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: canSubmit
                          ? () => context.read<DeleteAccountCubit>().submit()
                          : null,
                      child: processing
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: scheme.onError.withValues(alpha: 0.92),
                              ),
                            )
                          : Text(l10n.deleteAccountSubmit),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: processing ? null : () => context.pop(),
                      child: Text(l10n.commonCancel),
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

bool _confirmationMatches(String input, String keyword) {
  return input.trim().toUpperCase() == keyword.trim().toUpperCase();
}

Color _deletePageBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    return Color.alphaBlend(
      scheme.error.withValues(alpha: 0.035),
      scheme.surface,
    );
  }
  return Color.alphaBlend(
    scheme.error.withValues(alpha: 0.012),
    scheme.surface,
  );
}

List<Color> _deleteCanvasGradient(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    return [
      Color.alphaBlend(
        scheme.error.withValues(alpha: 0.06),
        scheme.surfaceContainerLow,
      ),
      Color.alphaBlend(
        scheme.error.withValues(alpha: 0.025),
        scheme.surface,
      ),
      scheme.surface,
    ];
  }
  return [
    scheme.surface,
    Color.alphaBlend(
      scheme.error.withValues(alpha: 0.028),
      scheme.surfaceContainerLowest,
    ),
    scheme.surface,
  ];
}
