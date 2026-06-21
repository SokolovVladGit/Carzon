import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/entities/blocked_user.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../bloc/blocked_users_cubit.dart';
import '../bloc/blocked_users_state.dart';

/// Settings surface listing users blocked by the current account.
class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BlockedUsersCubit(repository: sl<MessagingRepository>())..load(),
      child: const _BlockedUsersView(),
    );
  }
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

  Future<void> _confirmUnblock(BuildContext context, BlockedUser user) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.messagingSafetyUnblockConfirmTitle),
        content: Text(l10n.messagingSafetyUnblockConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.messagingSafetyBlockConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.messagingSafetyUnblockUser),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<BlockedUsersCubit>().unblock(
      user.blockedUserId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.messagingSafetyUnblockSuccess
              : l10n.messagingSafetyUnblockError,
        ),
      ),
    );
  }

  String _displayName(AppLocalizations l10n, BlockedUser user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.messagingSafetyBlockedUserFallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.settings),
        title: Text(l10n.messagingSafetyBlockedUsersTitle),
      ),
      body: BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
        builder: (context, state) {
          switch (state.status) {
            case BlockedUsersStatus.initial:
            case BlockedUsersStatus.loading:
              return const LoadingView();
            case BlockedUsersStatus.failure:
              return ErrorView(
                message: l10n.messagingSafetyBlockedUsersLoadError,
                onRetry: () => context.read<BlockedUsersCubit>().load(),
              );
            case BlockedUsersStatus.success:
              if (state.users.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CarzonIcons.userBlock,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.messagingSafetyBlockedUsersEmptyTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.messagingSafetyBlockedUsersEmptyBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  final unblocking =
                      state.unblockingUserId == user.blockedUserId;
                  return ListTile(
                    key: ValueKey<String>('blocked_user_${user.blockedUserId}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    tileColor: cs.surfaceContainerLow,
                    leading: CircleAvatar(
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Icon(CarzonIcons.user, color: cs.onSurfaceVariant)
                          : null,
                    ),
                    title: Text(_displayName(l10n, user)),
                    trailing: unblocking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: () => _confirmUnblock(context, user),
                            child: Text(l10n.messagingSafetyUnblockUser),
                          ),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
