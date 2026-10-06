import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/manual_smart_fill_refinement.dart';
import '../../domain/entities/manual_smart_fill_result.dart';
import '../bloc/manual_smart_fill_cubit.dart';
import '../bloc/manual_smart_fill_state.dart';
import 'create_listing_manual_smart_fill_panel.dart';

const String kCreateListingSmartFillSheetRoute =
    'create_listing_smart_fill_sheet';

/// Opens the single Smart Fill clarification sheet.
///
/// Returns `true` when clarification itself reached a terminal state.
/// Dismissal, a changed identity, and failure return `false` or `null`.
/// Neither path is treated as «Не знаю».
Future<bool?> showCreateListingSmartFillSheet({
  required BuildContext context,
  required ManualSmartFillCubit cubit,
  required ManualSmartFillQuery? query,
  VoidCallback? onRestart,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF3F3832).withValues(alpha: 0.28),
    routeSettings: const RouteSettings(name: kCreateListingSmartFillSheetRoute),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: CreateListingSmartFillSheet(
          query: query,
          onRestart: onRestart,
        ),
      );
    },
  );
}

class CreateListingSmartFillSheet extends StatefulWidget {
  const CreateListingSmartFillSheet({
    super.key,
    required this.query,
    this.onRestart,
  });

  final ManualSmartFillQuery? query;
  final VoidCallback? onRestart;

  @override
  State<CreateListingSmartFillSheet> createState() =>
      _CreateListingSmartFillSheetState();
}

class _CreateListingSmartFillSheetState
    extends State<CreateListingSmartFillSheet> {
  bool _closing = false;

  bool _invalidated(ManualSmartFillState state) {
    if (state.status == ManualSmartFillStatus.idle) return true;
    final opened = widget.query;
    final current = state.query;
    if (opened != null && current != null && current != opened) return true;
    return false;
  }

  void _close(bool finished) {
    if (_closing || !mounted) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      Navigator.of(context).pop(finished);
    });
  }

  void _onState(ManualSmartFillState state) {
    if (_closing) return;
    if (_invalidated(state)) {
      _close(false);
      return;
    }
    if (state.status == ManualSmartFillStatus.loading) return;
    if (state.showClarification) return;
    final finished =
        state.status == ManualSmartFillStatus.filled ||
        state.status == ManualSmartFillStatus.noData;
    _close(finished);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final fraction = media.size.height < 640 ? 0.88 : 0.74;
    final height = media.size.height * fraction;

    return BlocListener<ManualSmartFillCubit, ManualSmartFillState>(
      listener: (context, state) => _onState(state),
      child: Padding(
        padding: EdgeInsets.only(top: media.padding.top + 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            key: const ValueKey('create_listing_smart_fill_sheet'),
            color: const Color(0xFFFFFCF8),
            elevation: 0,
            shadowColor: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: height,
              child: BlocBuilder<ManualSmartFillCubit, ManualSmartFillState>(
                builder: (context, state) {
                  return _SheetBody(
                    l10n: l10n,
                    state: state,
                    enabled: state.status != ManualSmartFillStatus.loading,
                    onSelectOption: (option) {
                      context.read<ManualSmartFillCubit>().selectOption(
                        option,
                      );
                    },
                    onDontKnow: () {
                      context.read<ManualSmartFillCubit>().skipCurrent();
                    },
                    onClose: () => _close(false),
                    onRestart: widget.onRestart,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.l10n,
    required this.state,
    required this.enabled,
    required this.onSelectOption,
    required this.onDontKnow,
    required this.onClose,
    this.onRestart,
  });

  final AppLocalizations l10n;
  final ManualSmartFillState state;
  final bool enabled;
  final ValueChanged<ManualSmartFillRefinementOption> onSelectOption;
  final VoidCallback onDontKnow;
  final VoidCallback onClose;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final question = smartFillClarificationQuestion(l10n, state);
    final questionKey = question == null
        ? 'empty'
        : '${question.kind.wireValue}:${question.rows.map((row) => row.option.id).join('|')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE6D9CC),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  l10n.createListingSmartFillSheetEyebrow,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8F7D6A),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('create_listing_smart_fill_sheet_close'),
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 22),
                color: const Color(0xFF8F7D6A),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 20),
            children: [
              Text(
                l10n.createListingSmartFillSheetTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF3F3832),
                  fontWeight: FontWeight.w600,
                  fontSize: 26,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.createListingSmartFillSheetHelper,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF3F3832).withValues(alpha: 0.62),
                  height: 1.35,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                layoutBuilder: (current, previous) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  );
                },
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0.06, 0.04),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: question == null
                    ? const SizedBox(
                        key: ValueKey(
                          'create_listing_smart_fill_question_empty',
                        ),
                      )
                    : _QuestionBlock(
                        key: ValueKey(
                          'create_listing_smart_fill_clarification_$questionKey',
                        ),
                        l10n: l10n,
                        prompt: manualSmartFillClarificationPrompt(
                          l10n,
                          question.kind.wireValue,
                        ),
                        rows: question.rows,
                        enabled: enabled,
                        showRestart:
                            state.canRestart && onRestart != null && enabled,
                        onSelectOption: onSelectOption,
                        onDontKnow: onDontKnow,
                        onRestart: onRestart,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SmartFillClarificationQuestion {
  const SmartFillClarificationQuestion({
    required this.kind,
    required this.rows,
  });

  final ManualSmartFillRefinementKind kind;
  final List<({ManualSmartFillRefinementOption option, String label})> rows;
}

SmartFillClarificationQuestion? smartFillClarificationQuestion(
  AppLocalizations l10n,
  ManualSmartFillState state,
) {
  if (!state.showClarification) return null;
  final next = state.result?.nextRefinement;
  final clarification = state.result?.clarification;
  final kind =
      next?.kind ??
      parseManualSmartFillRefinementKind(clarification?.attribute);
  if (kind == null) return null;
  final raw = next != null
      ? next.options
      : [
          for (final option in clarification?.options ?? const [])
            ManualSmartFillRefinementOption(
              id: option.value,
              kind: kind,
              candidateCount: option.candidateCount ?? 0,
              bodyType: kind == ManualSmartFillRefinementKind.body
                  ? option.value
                  : null,
              fuelType: kind == ManualSmartFillRefinementKind.fuel
                  ? option.value
                  : null,
              transmissionType:
                  kind == ManualSmartFillRefinementKind.transmission
                  ? option.value
                  : null,
            ),
        ];
  final rows = <({ManualSmartFillRefinementOption option, String label})>[
    for (final option in raw)
      if (manualSmartFillRefinementOptionLabel(l10n, option) != null)
        (
          option: option,
          label: manualSmartFillRefinementOptionLabel(l10n, option)!,
        ),
  ];
  if (rows.isEmpty) return null;
  return SmartFillClarificationQuestion(kind: kind, rows: rows);
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    super.key,
    required this.l10n,
    required this.prompt,
    required this.rows,
    required this.enabled,
    required this.showRestart,
    required this.onSelectOption,
    required this.onDontKnow,
    this.onRestart,
  });

  final AppLocalizations l10n;
  final String prompt;
  final List<({ManualSmartFillRefinementOption option, String label})> rows;
  final bool enabled;
  final bool showRestart;
  final ValueChanged<ManualSmartFillRefinementOption> onSelectOption;
  final VoidCallback onDontKnow;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('create_listing_smart_fill_clarification'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF3F3832),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        for (final row in rows) ...[
          _AnswerRow(
            optionId: row.option.canonicalValue ?? row.option.id,
            label: row.label,
            enabled: enabled,
            onPressed: () => onSelectOption(row.option),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('create_listing_smart_fill_dont_know'),
            onPressed: enabled ? onDontKnow : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8C5E52),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              minimumSize: const Size(48, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.createListingSmartFillDontKnow,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
        if (showRestart)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('create_listing_smart_fill_restart'),
              onPressed: onRestart,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8F7D6A),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: const Size(48, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.createListingSmartFillRestart),
            ),
          ),
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.optionId,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String optionId;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));
    return Material(
      key: ValueKey('create_listing_smart_fill_option_$optionId'),
      color: const Color(0xFFFFFCF8),
      shape: const RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Color(0xFFE6D9CC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        splashColor: const Color(0xFFC9B59E).withValues(alpha: 0.28),
        highlightColor: const Color(0xFFC9B59E).withValues(alpha: 0.18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? const Color(0xFF3F3832)
                      : const Color(0xFF3F3832).withValues(alpha: 0.38),
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                  height: 1.25,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
