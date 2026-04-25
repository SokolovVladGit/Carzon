import 'package:flutter/material.dart';

/// Reusable "nothing here yet" surface shown when a list, feed, or
/// collection page has no content to render.
///
/// Visual structure (top→bottom):
///   1. a calm circular icon container tinted with the theme's primary
///      container role,
///   2. the [title] as the primary statement,
///   3. an optional [body] paragraph giving context or next steps,
///   4. optional primary/secondary action buttons.
///
/// The widget itself is localization-agnostic — callers pass already
/// localized strings — so it can be reused from any feature without
/// reaching back into `AppLocalizations` itself.
///
/// The widget scrolls when the caller wraps it in a scrollable (used
/// from pull-to-refresh hosts so the `RefreshIndicator` gesture still
/// works on an empty list). By default it centers itself inside the
/// available viewport; set [expand] to `false` to use its intrinsic
/// height (useful inside an already-sized column).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.primaryAction,
    this.secondaryAction,
    this.expand = true,
  });

  final IconData icon;
  final String title;
  final String? body;

  /// Filled primary action (e.g. "Подать объявление" on empty My
  /// Listings). Rendered with `FilledButton`. Null ⇒ no primary action.
  final EmptyStateAction? primaryAction;

  /// Outlined secondary action (e.g. "Сбросить фильтры"). Rendered
  /// with `OutlinedButton`. Null ⇒ no secondary action.
  final EmptyStateAction? secondaryAction;

  /// When true (default), the empty state fills the available height
  /// using a min-height constraint so it reads as a centered page
  /// surface. When false, the widget only consumes its intrinsic
  /// height — useful when composed inside a sized parent.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (primaryAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: primaryAction!.onPressed,
              child: Text(primaryAction!.label),
            ),
          ],
          if (secondaryAction != null) ...[
            SizedBox(height: primaryAction != null ? 8 : 20),
            OutlinedButton(
              onPressed: secondaryAction!.onPressed,
              child: Text(secondaryAction!.label),
            ),
          ],
        ],
      ),
    );

    if (!expand) return content;
    // `LayoutBuilder` lets the empty state fill the hosting viewport
    // height so it reads as a full centered page. Wrapping the result
    // as a `SingleChildScrollView` from the caller (pull-to-refresh
    // hosts) keeps the refresh gesture working.
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 320.0;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Center(child: content),
        );
      },
    );
  }
}

/// Describes a button shown inside an [EmptyStateView].
///
/// Kept as a tiny record-like class (not a `typedef`) so callers get
/// self-documenting call sites and so the widget can distinguish a
/// "no action" state from an "action with null callback" state.
class EmptyStateAction {
  const EmptyStateAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}
