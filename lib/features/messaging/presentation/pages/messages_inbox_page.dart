import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../bloc/messages_inbox_cubit.dart';
import '../bloc/messages_inbox_state.dart';

String _shortListingLabel(String listingId) {
  final compact = listingId.replaceAll('-', '');
  if (compact.length >= 8) return compact.substring(0, 8);
  return listingId;
}

/// Full-screen inbox; entry from Menu. Auth-required.
class MessagesInboxPage extends StatelessWidget {
  const MessagesInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.messagingTitle),
              leading: const AppBackButton(fallback: AppRoutes.menu),
            ),
            body: _SignInBody(
              message: l10n.messagingSignInRequired,
              onSignIn: () => context.go(AppRoutes.signIn),
            ),
          );
        }

        return BlocProvider(
          create: (_) =>
              MessagesInboxCubit(sl<MessagingRepository>())..refresh(),
          child: const _MessagesInboxView(),
        );
      },
    );
  }
}

class _SignInBody extends StatelessWidget {
  const _SignInBody({required this.message, required this.onSignIn});

  final String message;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CarzonIcons.chat, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSignIn, child: Text(l10n.commonSignIn)),
          ],
        ),
      ),
    );
  }
}

class _MessagesInboxView extends StatelessWidget {
  const _MessagesInboxView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messagingTitle),
        leading: const AppBackButton(fallback: AppRoutes.menu),
      ),
      body: BlocBuilder<MessagesInboxCubit, MessagesInboxState>(
        builder: (context, state) {
          switch (state.status) {
            case MessagesInboxStatus.initial:
            case MessagesInboxStatus.loading:
              return const Center(child: LoadingView());
            case MessagesInboxStatus.failure:
              return Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorView(
                  message: l10n.messagingLoadFailed,
                  onRetry: () => context.read<MessagesInboxCubit>().refresh(),
                ),
              );
            case MessagesInboxStatus.success:
              Future<void> onPullRefresh() =>
                  context.read<MessagesInboxCubit>().silentRefresh();

              if (state.conversations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: onPullRefresh,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    size: 56,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.messagingEmptyTitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.messagingEmptyBody,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
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
              }
              final timeFormat = DateFormat('d MMM, HH:mm', 'ru');
              return RefreshIndicator(
                onRefresh: onPullRefresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.conversations.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = state.conversations[i];
                    final title =
                        (c.listingTitle != null &&
                            c.listingTitle!.trim().isNotEmpty)
                        ? c.listingTitle!.trim()
                        : l10n.messagingListingFallback(
                            _shortListingLabel(c.listingId),
                          );
                    final preview =
                        (c.lastMessagePreview != null &&
                            c.lastMessagePreview!.trim().isNotEmpty)
                        ? c.lastMessagePreview!.trim()
                        : l10n.messagingNoPreview;
                    final time = c.lastMessageAt != null
                        ? timeFormat.format(c.lastMessageAt!.toLocal())
                        : null;
                    final theme = Theme.of(context);
                    final onVar = theme.colorScheme.onSurfaceVariant;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      title: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onVar,
                            height: 1.3,
                          ),
                        ),
                      ),
                      trailing: time != null
                          ? Text(
                              time,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: onVar.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            )
                          : null,
                      onTap: () =>
                          context.push(AppRoutes.messagesThreadPath(c.id)),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
