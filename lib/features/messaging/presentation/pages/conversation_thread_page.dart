import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../domain/repositories/messaging_repository.dart';
import '../bloc/conversation_thread_cubit.dart';
import '../bloc/conversation_thread_state.dart';
import '../bloc/messaging_unread_summary_cubit.dart';
import '../utils/messaging_user_messages.dart';
import '../utils/thread_app_bar_title.dart';
import '../utils/thread_date_label.dart';
import '../utils/thread_list_entries.dart';
import '../widgets/chat_attachment_fullscreen_viewer.dart';
import '../widgets/chat_image_message_bubble.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/thread_composer_bar.dart';
import '../widgets/thread_date_separator.dart';
import '../widgets/thread_listing_context_card.dart';
import '../widgets/thread_messaging_safety_ui.dart';
import '../widgets/thread_safety_overflow_menu.dart';
import '../widgets/thread_support_context_card.dart';
import '../widgets/thread_quick_reply_chips.dart';

String _shortListingLabel(String listingId) {
  final compact = listingId.replaceAll('-', '');
  if (compact.length >= 8) return compact.substring(0, 8);
  return listingId;
}

/// Chat thread backdrop (must match [pubspec.yaml] asset entry).
const String _kChatBackgroundAsset = 'assets/bg/bg_chat.jpg';

PreferredSize _threadAppBarBottomEdge(ColorScheme cs) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Divider(
      height: 1,
      thickness: 1,
      color: cs.outlineVariant.withValues(alpha: 0.38),
    ),
  );
}

/// Pixels from max scroll within which we treat the user as "at bottom" for
/// auto-scroll on silent poll updates.
const double _kThreadNearBottomThreshold = 120;

/// Single conversation thread with composer.
class ConversationThreadPage extends StatefulWidget {
  const ConversationThreadPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ConversationThreadPage> createState() => _ConversationThreadPageState();
}

class _ConversationThreadPageState extends State<ConversationThreadPage> {
  final _scroll = ScrollController();
  final _text = TextEditingController();

  ConversationThreadState? _scrollBlocPrev;
  ConversationThreadState? _scrollBlocCurr;

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  bool _scrollViewNearBottom() {
    if (!_scroll.hasClients) return false;
    final pos = _scroll.position;
    if (!pos.hasContentDimensions) return false;
    final max = pos.maxScrollExtent;
    if (!max.isFinite || max <= 0) return true;
    return pos.pixels >= max - _kThreadNearBottomThreshold;
  }

  void _scrollThreadToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (!pos.hasContentDimensions) return;
      final maxExtent = pos.maxScrollExtent;
      if (!maxExtent.isFinite || maxExtent < 0) return;
      _scroll.jumpTo(maxExtent.clamp(0.0, maxExtent));
    });
  }

  void _applyThreadScrollDecision(
    ConversationThreadState? p,
    ConversationThreadState c,
  ) {
    if (c.status != ConversationThreadStatus.success) return;

    if (c.messages.isEmpty) {
      if (p == null || p.status != ConversationThreadStatus.success) {
        _scrollThreadToBottom();
      }
      return;
    }

    if (p == null || p.status != ConversationThreadStatus.success) {
      _scrollThreadToBottom();
      return;
    }

    final sendFinishedOk =
        p.sending && !c.sending && c.lastSendFailureKind == null;
    if (sendFinishedOk) {
      _scrollThreadToBottom();
      return;
    }

    final tailChanged =
        p.messages.isEmpty ||
        p.messages.length != c.messages.length ||
        p.messages.last.id != c.messages.last.id;
    if (tailChanged && _scrollViewNearBottom()) {
      _scrollThreadToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          final csGuest = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.messagingThreadTitle),
              leading: const AppBackButton(fallback: AppRoutes.messages),
              backgroundColor: csGuest.surfaceContainerLow,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              bottom: _threadAppBarBottomEdge(csGuest),
            ),
            body: AuthRequiredPrompt(
              icon: const Icon(CarzonIcons.chat, size: 48),
              message: l10n.messagingSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: () => context.go(AppRoutes.signIn),
            ),
          );
        }

        final uid = auth.user!.id;
        return BlocProvider(
          key: ValueKey('${widget.conversationId}_$uid'),
          create: (_) => ConversationThreadCubit(
            repository: sl<MessagingRepository>(),
            conversationId: widget.conversationId,
            currentUserId: uid,
            onReadReceiptSynced: () async {
              await sl<MessagingUnreadSummaryCubit>().sync(
                sl<AuthCubit>().state,
              );
            },
          )..load(),
          child: Builder(
            builder: (nestedContext) {
              return _ThreadPollingHost(
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<
                      ConversationThreadCubit,
                      ConversationThreadState
                    >(
                      listenWhen: (p, c) {
                        final need = _conversationThreadNeedsScrollDecision(
                          p,
                          c,
                        );
                        if (!need) return false;
                        _scrollBlocPrev = p;
                        _scrollBlocCurr = c;
                        return true;
                      },
                      listener: (_, _) {
                        final p = _scrollBlocPrev;
                        final c = _scrollBlocCurr;
                        if (c == null) return;
                        _applyThreadScrollDecision(p, c);
                      },
                    ),
                    BlocListener<
                      ConversationThreadCubit,
                      ConversationThreadState
                    >(
                      listenWhen: (p, c) =>
                          p.refreshFailureKind != c.refreshFailureKind &&
                          c.refreshFailureKind != null,
                      listener: (context, state) {
                        final k = state.refreshFailureKind;
                        if (k == null) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              messagingFailureMessage(
                                context.l10n,
                                k,
                                isSendAction: false,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    BlocListener<
                      ConversationThreadCubit,
                      ConversationThreadState
                    >(
                      listenWhen: (p, c) =>
                          p.lastSendFailureKind != c.lastSendFailureKind &&
                          c.lastSendFailureKind != null,
                      listener: (context, state) {
                        final k = state.lastSendFailureKind;
                        if (k == null) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              messagingFailureMessage(
                                l10n,
                                k,
                                isSendAction: true,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  child: _ThreadScaffold(
                    conversationId: widget.conversationId,
                    scrollController: _scroll,
                    textController: _text,
                    currentUserId: uid,
                    onSuccessfulPullRefreshScroll: () {
                      if (!nestedContext.mounted) return;
                      final s = nestedContext
                          .read<ConversationThreadCubit>()
                          .state;
                      if (s.refreshFailureKind != null) return;
                      _scrollThreadToBottom();
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

bool _conversationThreadNeedsScrollDecision(
  ConversationThreadState p,
  ConversationThreadState c,
) {
  if (c.status != ConversationThreadStatus.success) return false;
  if (p.status != ConversationThreadStatus.success) return true;

  if (p.sending && !c.sending && c.lastSendFailureKind == null) {
    return true;
  }

  if (c.messages.isEmpty) return false;

  if (p.messages.isEmpty) return true;
  if (p.messages.length != c.messages.length) return true;
  if (p.messages.last.id != c.messages.last.id) return true;
  return false;
}

/// Starts [ConversationThreadCubit.silentRefresh] on a timer while mounted and
/// the app lifecycle is resumed.
class _ThreadPollingHost extends StatefulWidget {
  const _ThreadPollingHost({required this.child});

  final Widget child;

  @override
  State<_ThreadPollingHost> createState() => _ThreadPollingHostState();
}

class _ThreadPollingHostState extends State<_ThreadPollingHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  AppLifecycleState? _lifecycleState = WidgetsBinding.instance.lifecycleState;

  static const _pollInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartTimer());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.resumed:
        _restartTimer();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _timer?.cancel();
        _timer = null;
    }
  }

  bool get _shouldPoll {
    final s = _lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (!mounted || !_shouldPoll) return;

    _timer = Timer.periodic(_pollInterval, (_) {
      if (!_shouldPoll || !mounted) return;
      context.read<ConversationThreadCubit>().silentRefresh();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ThreadScaffold extends StatefulWidget {
  const _ThreadScaffold({
    required this.conversationId,
    required this.scrollController,
    required this.textController,
    required this.currentUserId,
    required this.onSuccessfulPullRefreshScroll,
  });

  final String conversationId;
  final ScrollController scrollController;
  final TextEditingController textController;
  final String currentUserId;

  /// After [ConversationThreadCubit.refresh] completes without
  /// [ConversationThreadState.refreshFailureKind], matches pre-polling pull UX
  /// (scroll to latest) even when the user was not near the bottom.
  final VoidCallback onSuccessfulPullRefreshScroll;

  @override
  State<_ThreadScaffold> createState() => _ThreadScaffoldState();
}

class _ThreadScaffoldState extends State<_ThreadScaffold> {
  final Map<String, Future<Uint8List?>> _attachmentByteFutures = {};

  Future<Uint8List?> _loadAttachmentBytes(String storagePath) {
    return _attachmentByteFutures.putIfAbsent(storagePath, () {
      return context.read<ConversationThreadCubit>().downloadAttachmentBytes(
        storagePath,
      );
    });
  }

  void _invalidateAttachmentBytes(String storagePath) {
    _attachmentByteFutures.remove(storagePath);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final threadHostContext = context;
    final l10n = context.l10n;
    final intlTag = context.watch<AppLocaleCubit>().state.intlLanguageTag;
    final timeFormat = DateFormat.Hm(intlTag);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final overlayTop = cs.surface.withValues(alpha: isDark ? 0.72 : 0.74);
    final overlayBottom = cs.surface.withValues(alpha: isDark ? 0.88 : 0.82);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: BlocBuilder<ConversationThreadCubit, ConversationThreadState>(
          builder: (context, state) {
            final conv = state.conversation;
            final title = conv == null
                ? l10n.messagingThreadTitle
                : threadAppBarTitle(
                    conv,
                    _shortListingLabel(conv.listingId ?? ''),
                    l10n,
                  );
            return Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            );
          },
        ),
        leading: const AppBackButton(fallback: AppRoutes.messages),
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        bottom: _threadAppBarBottomEdge(cs),
        actions: const [ThreadSafetyOverflowMenu()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isDark)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: AppTheme.editorialDarkFilterCanvasGradient(
                            cs,
                          ),
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    )
                  else ...[
                    const RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_kChatBackgroundAsset),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [overlayTop, overlayBottom],
                        ),
                      ),
                    ),
                  ],
                  BlocBuilder<ConversationThreadCubit, ConversationThreadState>(
                    builder: (context, state) {
                      switch (state.status) {
                        case ConversationThreadStatus.initial:
                        case ConversationThreadStatus.loading:
                          return const Center(child: LoadingView());
                        case ConversationThreadStatus.failure:
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: ErrorView(
                              message: l10n.messagingLoadFailed,
                              onRetry: () => context
                                  .read<ConversationThreadCubit>()
                                  .load(),
                            ),
                          );
                        case ConversationThreadStatus.success:
                          final conv = state.conversation;
                          if (conv == null) {
                            return Center(
                              child: Text(l10n.messagingThreadTitle),
                            );
                          }
                          final card = conv.isSupportConversation
                              ? const ThreadSupportContextCard()
                              : ThreadListingContextCard(
                                  conversation: conv,
                                  listingIdShortFallback: l10n
                                      .messagingListingFallback(
                                        _shortListingLabel(conv.listingId!),
                                      ),
                                );
                          if (state.messages.isEmpty) {
                            final isSupport = conv.isSupportConversation;
                            final emptyPrompt = _ThreadEmptyPrompt(
                              title: isSupport
                                  ? l10n.messagingSupportThreadEmptyTitle
                                  : null,
                              body: isSupport
                                  ? l10n.messagingSupportThreadEmptyBody
                                  : l10n.messagingThreadEmptyBody,
                              theme: theme,
                              cs: cs,
                              isDark: isDark,
                            );
                            return RefreshIndicator(
                              onRefresh: () async {
                                await context
                                    .read<ConversationThreadCubit>()
                                    .refresh();
                                widget.onSuccessfulPullRefreshScroll();
                              },
                              child: ListView(
                                controller: widget.scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                children: [
                                  card,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 24),
                                        _ThreadEmptyPromptCard(
                                          cs: cs,
                                          isDark: isDark,
                                          child: emptyPrompt,
                                        ),
                                        if (!isSupport)
                                          ThreadQuickReplyChips(
                                            textController:
                                                widget.textController,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final entries = buildThreadListEntries(
                            state.messages,
                          );
                          return RefreshIndicator(
                            onRefresh: () async {
                              await context
                                  .read<ConversationThreadCubit>()
                                  .refresh();
                              widget.onSuccessfulPullRefreshScroll();
                            },
                            child: ListView.builder(
                              controller: widget.scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 12),
                              itemCount: 1 + entries.length,
                              itemBuilder: (context, index) {
                                if (index == 0) return card;
                                final e = entries[index - 1];
                                if (e is ThreadDateHeaderEntry) {
                                  return ThreadDateSeparator(
                                    label: threadDateSeparatorLabel(
                                      e.dayStart,
                                      l10n,
                                    ),
                                  );
                                }
                                if (e is ThreadMessageEntry) {
                                  final m = e.message;
                                  final outgoing =
                                      m.senderId == widget.currentUserId;
                                  final label = timeFormat.format(
                                    m.createdAt.toLocal(),
                                  );
                                  if (m.hasAttachments) {
                                    final attachment = m.attachments.first;
                                    return ChatImageMessageBubble(
                                      message: m,
                                      attachment: attachment,
                                      isOutgoing: outgoing,
                                      timeLabel: label,
                                      groupPosition: e.groupPosition,
                                      showTimestamp: e.showTimestamp,
                                      loadFailedLabel:
                                          l10n.messagingAttachmentLoadFailed,
                                      loadBytes: _loadAttachmentBytes,
                                      onOpenFullscreen: (bytes) {
                                        ChatAttachmentFullscreenViewer.open(
                                          threadHostContext,
                                          bytes: bytes,
                                        );
                                      },
                                      onRetryLoad: () =>
                                          _invalidateAttachmentBytes(
                                            attachment.storagePath,
                                          ),
                                      onLongPress: () {
                                        final caption = m.body.trim();
                                        if (caption.isEmpty) return;
                                        final messenger = ScaffoldMessenger.of(
                                          threadHostContext,
                                        );
                                        Clipboard.setData(
                                          ClipboardData(text: caption),
                                        );
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.messagingMessageCopied,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  return ChatMessageBubble(
                                    message: m,
                                    isOutgoing: outgoing,
                                    timeLabel: label,
                                    groupPosition: e.groupPosition,
                                    showTimestamp: e.showTimestamp,
                                    onLongPress: () {
                                      final body = m.body.trim();
                                      if (body.isEmpty) return;
                                      final messenger = ScaffoldMessenger.of(
                                        threadHostContext,
                                      );
                                      Clipboard.setData(
                                        ClipboardData(text: body),
                                      );
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.messagingMessageCopied,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<ConversationThreadCubit, ConversationThreadState>(
            builder: (context, state) {
              return ThreadBlockedBanner(
                blockedByMe: state.peerBlockedByMe,
                messagingUnavailable: state.messagingUnavailable,
              );
            },
          ),
          BlocBuilder<ConversationThreadCubit, ConversationThreadState>(
            builder: (context, state) {
              return ThreadComposerBar(
                conversationId: widget.conversationId,
                textController: widget.textController,
                composerDisabled: state.composerDisabled,
                onSendSucceeded: () => widget.textController.clear(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThreadEmptyPromptCard extends StatelessWidget {
  const _ThreadEmptyPromptCard({
    required this.cs,
    required this.isDark,
    required this.child,
  });

  final ColorScheme cs;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decoration = isDark
        ? AppTheme.editorialDarkSectionCard(cs, borderRadius: 18)!
        : BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          );

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: child,
      ),
    );
  }
}

class _ThreadEmptyPrompt extends StatelessWidget {
  const _ThreadEmptyPrompt({
    this.title,
    required this.body,
    required this.theme,
    required this.cs,
    required this.isDark,
  });

  final String? title;
  final String body;
  final ThemeData theme;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CarzonIcons.chat,
          size: 44,
          color: isDark
              ? AppTheme.editorialAccentColor(cs)
              : cs.primary.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 16),
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: cs.onSurface.withValues(alpha: isDark ? 0.96 : 0.92),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: cs.onSurface.withValues(alpha: isDark ? 0.94 : 0.9),
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: cs.surface.withValues(alpha: 0.55),
                      blurRadius: 14,
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}
