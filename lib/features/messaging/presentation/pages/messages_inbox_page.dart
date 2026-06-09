import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/l10n/app_locale_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/messaging_unread_summary_cubit.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../bloc/messages_inbox_cubit.dart';
import '../bloc/messages_inbox_state.dart';
import '../utils/conversation_display_copy.dart';
import '../widgets/messages_inbox_conversation_tile.dart';

String _shortListingLabel(String listingId) {
  final compact = listingId.replaceAll('-', '');
  if (compact.length >= 8) return compact.substring(0, 8);
  return listingId;
}

PreferredSizeWidget _inboxAppBarBottomEdge(ColorScheme cs) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Divider(
      height: 1,
      thickness: 1,
      color: cs.outlineVariant.withValues(alpha: 0.38),
    ),
  );
}

AppBar _inboxAppBar(BuildContext context, String title) {
  final cs = Theme.of(context).colorScheme;
  final theme = Theme.of(context);
  return AppBar(
    title: Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
      ),
    ),
    leading: const AppBackButton(fallback: AppRoutes.menu),
    backgroundColor: cs.surfaceContainerLow,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    bottom: _inboxAppBarBottomEdge(cs),
  );
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
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: _inboxAppBar(context, l10n.messagingTitle),
            body: _InboxCanvas(
              child: AuthRequiredPrompt(
                icon: Icon(
                  CarzonIcons.chat,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
                message: l10n.messagingSignInRequired,
                messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.92),
                ),
                primaryButtonLabel: l10n.commonSignIn,
                onPrimaryPressed: () => context.go(AppRoutes.signIn),
                contentWrapper: (_, child) =>
                    _InboxEditorialPanel(child: child),
              ),
            ),
          );
        }

        return BlocProvider(
          create: (_) =>
              MessagesInboxCubit(sl<MessagingRepository>())..refresh(),
          child: PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) {
                unawaited(
                  sl<MessagingUnreadSummaryCubit>().sync(sl<AuthCubit>().state),
                );
              }
            },
            child: const _MessagesInboxView(),
          ),
        );
      },
    );
  }
}

/// Page backdrop: editorial gradient in dark, calm surface in light.
class _InboxCanvas extends StatelessWidget {
  const _InboxCanvas({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isDark)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppTheme.editorialDarkFilterCanvasGradient(cs),
                stops: const [0, 0.45, 1],
              ),
            ),
          )
        else
          ColoredBox(
            color: Color.alphaBlend(
              cs.primary.withValues(alpha: 0.02),
              cs.surface,
            ),
          ),
        child,
      ],
    );
  }
}

class _InboxEditorialPanel extends StatelessWidget {
  const _InboxEditorialPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    final decoration = light
        ? BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          )
        : AppTheme.editorialDarkSectionCard(cs, borderRadius: 18)!;

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: child,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _inboxAppBar(context, l10n.messagingTitle),
      body: _InboxCanvas(
        child: BlocBuilder<MessagesInboxCubit, MessagesInboxState>(
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
                                child: _InboxEditorialPanel(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CarzonIcons.chat,
                                        size: 56,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.messagingEmptyTitle,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
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
                          ),
                        );
                      },
                    ),
                  );
                }
                final intlTag = context
                    .watch<AppLocaleCubit>()
                    .state
                    .intlLanguageTag;
                final timeFormat = DateFormat('d MMM, HH:mm', intlTag);
                final dividerColor = Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.32);
                const dividerIndent =
                    18 + MessagesInboxConversationTile.avatarSize + 14;
                return RefreshIndicator(
                  onRefresh: onPullRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    itemCount: state.conversations.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: dividerIndent,
                      endIndent: 16,
                      color: dividerColor,
                    ),
                    itemBuilder: (context, i) {
                      final c = state.conversations[i];
                      final listingFallback = c.listingId == null
                          ? ''
                          : l10n.messagingListingFallback(
                              _shortListingLabel(c.listingId!),
                            );
                      final headline = conversationPrimaryLine(
                        c,
                        listingFallback,
                        l10n,
                      );
                      final preview =
                          (c.lastMessagePreview != null &&
                              c.lastMessagePreview!.trim().isNotEmpty)
                          ? c.lastMessagePreview!.trim()
                          : conversationEmptyPreviewLine(c, l10n);
                      final time = c.lastMessageAt != null
                          ? timeFormat.format(c.lastMessageAt!.toLocal())
                          : null;

                      return MessagesInboxConversationTile(
                        conversation: c,
                        listingHeadlineFallback: listingFallback,
                        headline: headline,
                        messagePreview: preview,
                        timeText: time,
                        onTap: () async {
                          await context.push<void>(
                            AppRoutes.messagesThreadPath(c.id),
                          );
                          if (!context.mounted) return;
                          await context
                              .read<MessagesInboxCubit>()
                              .silentRefresh();
                        },
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
