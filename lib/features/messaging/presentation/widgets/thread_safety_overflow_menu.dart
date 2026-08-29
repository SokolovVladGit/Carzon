import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/entities/user_report_reason.dart';
import '../utils/user_report_note_validation.dart';
import '../bloc/conversation_thread_cubit.dart';
import '../bloc/conversation_thread_state.dart';
import 'thread_messaging_safety_ui.dart';

enum _ThreadSafetyMenuAction { report, block }

/// Overflow menu for listing-thread safety actions (report / block).
class ThreadSafetyOverflowMenu extends StatelessWidget {
  const ThreadSafetyOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationThreadCubit, ConversationThreadState>(
      builder: (context, state) {
        final conv = state.conversation;
        if (conv == null || conv.isSupportConversation) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final blocked = state.peerBlockedByMe;

        return PopupMenuButton<_ThreadSafetyMenuAction>(
          key: const ValueKey<String>('thread_safety_overflow_menu'),
          icon: const Icon(CarzonIcons.moreActions),
          onSelected: (action) async {
            switch (action) {
              case _ThreadSafetyMenuAction.report:
                await _onReport(context);
              case _ThreadSafetyMenuAction.block:
                await _onBlock(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _ThreadSafetyMenuAction.report,
              child: Text(l10n.messagingSafetyReportUser),
            ),
            if (!blocked)
              PopupMenuItem(
                value: _ThreadSafetyMenuAction.block,
                child: Text(l10n.messagingSafetyBlockUser),
              )
            else
              PopupMenuItem(
                enabled: false,
                child: Text(l10n.messagingSafetyBlockedLabel),
              ),
          ],
        );
      },
    );
  }

  Future<void> _onBlock(BuildContext context) async {
    final confirmed = await showThreadBlockConfirmationDialog(context);
    if (!confirmed || !context.mounted) return;

    final ok = await context.read<ConversationThreadCubit>().blockPeer();
    if (!context.mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.messagingSafetyBlockSuccess
              : l10n.messagingSafetyBlockError,
        ),
      ),
    );
  }

  Future<void> _onReport(BuildContext context) async {
    final submitted = await showThreadReportUserSheet(context);
    if (!context.mounted || submitted == null) return;

    final ok = await context.read<ConversationThreadCubit>().reportPeer(
      reason: submitted.reason,
      note: submitted.note,
    );
    if (!context.mounted) return;
    final rejected = context
        .read<ConversationThreadCubit>()
        .state
        .lastReportContentRejected;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.messagingSafetyReportSuccess
              : rejected
              ? l10n.contentModerationRejected
              : l10n.messagingSafetyReportError,
        ),
      ),
    );
  }
}

class ThreadReportSubmission {
  const ThreadReportSubmission({required this.reason, this.note});

  final UserReportReason reason;
  final String? note;
}

Future<ThreadReportSubmission?> showThreadReportUserSheet(
  BuildContext context,
) {
  return showModalBottomSheet<ThreadReportSubmission>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => const _ThreadReportUserSheet(),
  );
}

class _ThreadReportUserSheet extends StatefulWidget {
  const _ThreadReportUserSheet();

  @override
  State<_ThreadReportUserSheet> createState() => _ThreadReportUserSheetState();
}

class _ThreadReportUserSheetState extends State<_ThreadReportUserSheet> {
  UserReportReason _reason = UserReportReason.harassment;
  final _noteController = TextEditingController();
  String? _noteError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, UserReportReason reason) {
    return switch (reason) {
      UserReportReason.harassment => l10n.messagingSafetyReportReasonHarassment,
      UserReportReason.spam => l10n.messagingSafetyReportReasonSpam,
      UserReportReason.scam => l10n.messagingSafetyReportReasonScam,
      UserReportReason.inappropriate =>
        l10n.messagingSafetyReportReasonInappropriate,
      UserReportReason.other => l10n.messagingSafetyReportReasonOther,
    };
  }

  void _submit() {
    final l10n = context.l10n;
    final note = _noteController.text;
    if (isUserReportNoteTooLong(note)) {
      setState(() => _noteError = l10n.messagingSafetyReportNoteTooLong);
      return;
    }
    Navigator.pop(
      context,
      ThreadReportSubmission(
        reason: _reason,
        note: normalizeUserReportNote(note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.messagingSafetyReportUser,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...UserReportReason.values.map(
            (reason) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _reason == reason
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(_reasonLabel(l10n, reason)),
              onTap: () => setState(() => _reason = reason),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 4,
            maxLength: kUserReportNoteMaxLength,
            decoration: InputDecoration(
              labelText: l10n.messagingSafetyReportNoteLabel,
              hintText: l10n.messagingSafetyReportNotePlaceholder,
              errorText: _noteError,
            ),
            onChanged: (_) {
              if (_noteError != null) setState(() => _noteError = null);
            },
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: Text(l10n.messagingSafetyReportSubmit),
          ),
        ],
      ),
    );
  }
}
