import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations_x.dart';
import 'listings_filter_apply_result.dart';
import 'listings_filter_form.dart';

/// How [ListingsFilterHost] titles and primary CTA are worded.
enum ListingsFilterHostMode {
  /// Default: browse / apply to feed (`Фильтры` + `Показать авто`).
  browse,

  /// Configure the single account filter for future alerts (`Сохранить фильтр`).
  alertSetup,
}

/// Full-screen filter surface: header, scrollable [ListingsFilterForm], sticky actions.
///
/// Host-agnostic: callbacks let the feed pop a sheet, while Account wires the same
/// form for the single filter-alert row.
///
/// Top inset uses [MediaQuery.viewPaddingOf] plus extra breathing, with a
/// **minimum floor** so full-screen modal sheets that report a zero or
/// unreliable top inset (common with [showModalBottomSheet]) still clear the
/// status bar, notch, and Dynamic Island.
class ListingsFilterHost extends StatefulWidget {
  const ListingsFilterHost({
    super.key,
    required this.seed,
    required this.onDismiss,
    required this.onApply,
    this.mode = ListingsFilterHostMode.browse,
    this.onBrowseFeedReset,
    this.onApplyBlockedByValidation,
    this.onAlertResetPersist,
  });

  final ListingsFilterFormSeed seed;
  final VoidCallback onDismiss;
  final ValueChanged<ListingsFilterApplyResult> onApply;

  /// When [submit()] returns null (validation failed), invoked if non-null.
  ///
  /// Browse sheets often rely on inline field errors only; alert setup may show
  /// a short fallback so taps do not feel inert.
  final VoidCallback? onApplyBlockedByValidation;

  /// Alert setup only: after the draft is reset to vanilla, invoked to clear
  /// persisted alert criteria immediately (null `criteria` on the server).
  ///
  /// Browse mode must omit this; [onBrowseFeedReset] handles feed sync there.
  final Future<void> Function()? onAlertResetPersist;

  /// Browse copy vs alert-filter editor copy (see [ListingsFilterHostMode]).
  final ListingsFilterHostMode mode;

  /// Browse only: invoked when the user taps reset so the catalog feed (and
  /// last-applied persistence) can sync with the vanilla draft immediately.
  ///
  /// Omit in [ListingsFilterHostMode.alertSetup]; use [onAlertResetPersist]
  /// instead when the account alert editor should clear stored criteria.
  final VoidCallback? onBrowseFeedReset;

  @override
  State<ListingsFilterHost> createState() => _ListingsFilterHostState();
}

class _ListingsFilterHostState extends State<ListingsFilterHost> {
  final GlobalKey<ListingsFilterFormState> _formKey = GlobalKey();

  /// Matches trailing width so the title stays optically centered.
  static const double _headerTrailWidth = 44;

  void _onApplyTap() {
    final result = _formKey.currentState?.submit();
    if (result != null) {
      widget.onApply(result);
    } else {
      widget.onApplyBlockedByValidation?.call();
    }
  }

  void _onResetTap() {
    _formKey.currentState?.resetDraftToVanilla();
    if (widget.mode == ListingsFilterHostMode.browse) {
      widget.onBrowseFeedReset?.call();
      return;
    }
    final persist = widget.onAlertResetPersist;
    if (persist != null) {
      unawaited(persist());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isAlert = widget.mode == ListingsFilterHostMode.alertSetup;
    final headerEyebrow =
        isAlert ? l10n.filterAlertEditorEyebrow : l10n.filtersHeaderEyebrow;
    final headerTitle =
        isAlert ? l10n.filterAlertEditorTitle : l10n.filtersTitle;
    final headerSubtitle =
        isAlert ? l10n.filterAlertEditorSubtitle : l10n.filtersSubtitle;
    final applyLabel =
        isAlert ? l10n.filterAlertSaveFilterAction : l10n.filterShowCars;
    final scheme = theme.colorScheme;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    // Modal routes can under-report top inset; keep the back control clearly
    // below status / Dynamic Island — align with the editorial block, not clock.
    const breathBelowReportedInset = 42.0;
    const minTopPaddingBeforeHeader = 78.0;
    final headerTop = math.max(
      viewPadding.top + breathBelowReportedInset,
      minTopPaddingBeforeHeader,
    );

    final bottomOsInset = viewPadding.bottom;
    final footerBottomPad = 20.0 + keyboardInset + bottomOsInset;

    // Sticky footer strip: top inset + button row (~56) + inner padding — enough
    // for sort + keyboard without hiding sections behind the bar.
    const footerChromeHeight = 108.0;
    final listScrollBottomPad =
        28.0 + footerChromeHeight + bottomOsInset + keyboardInset;

    final canvasTop = Color.alphaBlend(
      scheme.surfaceContainerLow.withValues(alpha: 0.55),
      scheme.surface,
    );
    final canvasBottom = scheme.surface;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              canvasTop,
              Color.lerp(canvasTop, canvasBottom, 0.65) ?? canvasBottom,
              canvasBottom,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, headerTop, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _headerTrailWidth,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Tooltip(
                                message: l10n.filtersDismissTooltip,
                                child: Material(
                                  color: Color.alphaBlend(
                                    scheme.surfaceContainerHigh
                                        .withValues(alpha: 0.5),
                                    scheme.surface.withValues(alpha: 0.12),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: scheme.outlineVariant
                                          .withValues(alpha: 0.24),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: widget.onDismiss,
                                    customBorder:
                                        const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(14),
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                headerEyebrow,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                      letterSpacing: 2.4,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.42),
                                    ) ??
                                    theme.textTheme.bodySmall?.copyWith(
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.42),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                headerTitle,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                      height: 1.15,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.96),
                                    ) ??
                                    theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.15,
                                      height: 1.15,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: _headerTrailWidth),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        headerSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    isAlert ? 20 : 8,
                    22,
                    listScrollBottomPad,
                  ),
                  children: [
                    ListingsFilterForm(
                      key: _formKey,
                      seed: widget.seed,
                      showDraftSummaryStrip: !isAlert,
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    scheme.surfaceContainerHighest.withValues(alpha: 0.28),
                    scheme.surface,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.22),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.07),
                      blurRadius: 28,
                      offset: const Offset(0, -12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    20,
                    22,
                    footerBottomPad,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onResetTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            foregroundColor: scheme.onSurface.withValues(
                              alpha: 0.82,
                            ),
                            side: BorderSide(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Color.alphaBlend(
                              scheme.surface.withValues(alpha: 0.72),
                              scheme.surfaceContainerHighest.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.filterClear,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _onApplyTap,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shadowColor: scheme.primary.withValues(alpha: 0.28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            applyLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
