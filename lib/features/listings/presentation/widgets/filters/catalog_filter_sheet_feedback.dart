import 'dart:async';

import 'package:flutter/material.dart';

import 'catalog_filter_alert_ui_constants.dart';

/// Sheet-local feedback surfaced inside the browse filter modal.
///
/// Replaces root [ScaffoldMessenger] snackbars for bell outcomes: the modal
/// has no own messenger, so root snackbars only become visible after the
/// sheet closes.
enum CatalogFilterSheetFeedbackKind { success, error, info }

/// Auto-dismiss durations for sheet-local filter feedback toasts.
abstract final class CatalogFilterSheetFeedbackDismissTiming {
  /// Success feedback (e.g. alert enabled).
  static const success = Duration(milliseconds: 3000);

  /// Transient error/info without a required action (e.g. max saved filters).
  static const transient = Duration(milliseconds: 4500);

  /// Auth-required feedback with a visible action (e.g. sign-in).
  static const withAction = Duration(milliseconds: 7000);
}

/// Readable auto-dismiss duration for [feedback].
Duration catalogFilterSheetFeedbackAutoDismissDuration(
  CatalogFilterSheetFeedback feedback,
) {
  if (feedback.actionLabel != null && feedback.onAction != null) {
    return CatalogFilterSheetFeedbackDismissTiming.withAction;
  }
  return switch (feedback.kind) {
    CatalogFilterSheetFeedbackKind.success =>
      CatalogFilterSheetFeedbackDismissTiming.success,
    CatalogFilterSheetFeedbackKind.error ||
    CatalogFilterSheetFeedbackKind.info =>
      CatalogFilterSheetFeedbackDismissTiming.transient,
  };
}

class CatalogFilterSheetFeedback {
  const CatalogFilterSheetFeedback({
    required this.message,
    required this.kind,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final CatalogFilterSheetFeedbackKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// Floating, theme-aware toast rendered above the filter sheet footer.
class CatalogFilterSheetFeedbackToast extends StatelessWidget {
  const CatalogFilterSheetFeedbackToast({super.key, required this.feedback});

  final CatalogFilterSheetFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final (IconData icon, Color accent) = switch (feedback.kind) {
      CatalogFilterSheetFeedbackKind.success => (
        Icons.check_circle_outline_rounded,
        CatalogFilterAlertAccent.amber,
      ),
      CatalogFilterSheetFeedbackKind.error => (
        Icons.error_outline_rounded,
        scheme.error.withValues(alpha: isDark ? 0.88 : 0.82),
      ),
      CatalogFilterSheetFeedbackKind.info => (
        Icons.info_outline_rounded,
        scheme.primary.withValues(alpha: isDark ? 0.92 : 0.88),
      ),
    };

    final surface = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final borderColor = switch (feedback.kind) {
      CatalogFilterSheetFeedbackKind.success => accent.withValues(
        alpha: isDark ? 0.42 : 0.34,
      ),
      CatalogFilterSheetFeedbackKind.error => scheme.error.withValues(
        alpha: isDark ? 0.38 : 0.28,
      ),
      CatalogFilterSheetFeedbackKind.info =>
        scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.22),
    };
    final iconBg = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.22 : 0.14),
      surface,
    );
    final messageColor = scheme.onSurface.withValues(alpha: 0.94);

    return Semantics(
      liveRegion: true,
      container: true,
      label: feedback.message,
      child: Material(
        key: CatalogFilterAlertAccent.sheetFeedbackToastKey,
        color: surface,
        elevation: isDark ? 6 : 4,
        shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.32 : 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(icon, size: 20, color: accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      feedback.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: messageColor,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    if (feedback.actionLabel != null &&
                        feedback.onAction != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: feedback.onAction,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            feedback.actionLabel!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hosts [CatalogFilterSheetFeedbackToast] and schedules a one-shot auto-dismiss.
///
/// The sheet builder owns feedback state and passes [onDismissed] to clear it.
/// Timers are cancelled on dispose or when [feedback] changes.
class CatalogFilterSheetFeedbackOverlay extends StatefulWidget {
  const CatalogFilterSheetFeedbackOverlay({
    super.key,
    required this.feedback,
    required this.onDismissed,
  });

  final CatalogFilterSheetFeedback feedback;
  final VoidCallback onDismissed;

  @override
  State<CatalogFilterSheetFeedbackOverlay> createState() =>
      _CatalogFilterSheetFeedbackOverlayState();
}

class _CatalogFilterSheetFeedbackOverlayState
    extends State<CatalogFilterSheetFeedbackOverlay> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _scheduleDismiss();
  }

  @override
  void didUpdateWidget(covariant CatalogFilterSheetFeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedback != oldWidget.feedback) {
      _scheduleDismiss();
    }
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(
      catalogFilterSheetFeedbackAutoDismissDuration(widget.feedback),
      () {
        if (!mounted) return;
        widget.onDismissed();
      },
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CatalogFilterSheetFeedbackToast(feedback: widget.feedback);
  }
}
