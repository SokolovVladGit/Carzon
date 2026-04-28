import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/widgets/listing_card.dart';

/// Actions an owner can trigger from the My Listings tile menu.
///
/// The enum intentionally unifies "Edit" (a navigation action) with
/// the four status transitions so the existing `PopupMenuButton` can
/// stay a single typed widget. The tile emits a [MyListingAction]
/// upwards; the page decides whether to navigate or call the cubit.
enum MyListingAction {
  edit,
  markSold,
  hide,
  reactivate,
  archive,
  deletePermanently,
}

/// Owner-facing tile: same content as the public tile but with a
/// status badge surfaced in the card's badges row and an owner action
/// menu in place of the favorite toggle (a seller doesn't favorite
/// their own listings). Rendered as a [ListingCard] so the card layout
/// stays consistent across public and owner contexts.
class MyListingTile extends StatelessWidget {
  const MyListingTile({
    super.key,
    required this.listing,
    this.onTap,
    this.isPending = false,
    this.onAction,
  });

  final Listing listing;
  final VoidCallback? onTap;

  /// True while a status change for this listing is in flight. The
  /// tile swaps the actions menu for a spinner and stays read-only
  /// until the change resolves.
  final bool isPending;

  /// Invoked when the owner picks an action (edit or a status
  /// transition) from the overflow menu. Null ⇒ no menu is shown
  /// (e.g. a hypothetical read-only context).
  final ValueChanged<MyListingAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListingCard(
      listing: listing,
      onTap: onTap,
      statusBadge: statusListingBadge(context, l10n, listing.status),
      trailing: _OwnerActionSlot(
        listing: listing,
        isPending: isPending,
        onAction: onAction,
      ),
    );
  }
}

/// Overlay slot that is either a progress spinner (while a status
/// change is running) or an overflow menu offering the Edit action
/// plus the valid next statuses for the listing's current state.
class _OwnerActionSlot extends StatelessWidget {
  const _OwnerActionSlot({
    required this.listing,
    required this.isPending,
    required this.onAction,
  });

  final Listing listing;
  final bool isPending;
  final ValueChanged<MyListingAction>? onAction;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final cb = onAction;
    if (cb == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final statusActions = allowedStatusActions(listing.status);
    final errorColor = Theme.of(context).colorScheme.error;

    return PopupMenuButton<MyListingAction>(
      tooltip: l10n.myListingActionsTooltip,
      icon: const Icon(CarzonIcons.moreActions),
      onSelected: cb,
      itemBuilder: (context) => [
        PopupMenuItem<MyListingAction>(
          value: MyListingAction.edit,
          child: Text(l10n.actionEdit),
        ),
        if (statusActions.isNotEmpty) const PopupMenuDivider(),
        for (final a in statusActions)
          PopupMenuItem<MyListingAction>(
            value: a,
            child: Text(statusActionLabel(l10n, a)),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<MyListingAction>(
          value: MyListingAction.deletePermanently,
          // Destructive action, tinted with the theme's error color so
          // it reads clearly against the reversible status entries
          // above. Wording matches the spec ("Delete permanently").
          child: Text(
            statusActionLabel(l10n, MyListingAction.deletePermanently),
            style: TextStyle(color: errorColor),
          ),
        ),
      ],
    );
  }
}

/// Status transition matrix. Archive is reversible (the owner can
/// reactivate from any state), so no destructive wording is needed.
///
/// Exposed at library level so the page can map a picked
/// [MyListingAction] back to a [ListingStatus] for the cubit call
/// without duplicating the transition rules.
List<MyListingAction> allowedStatusActions(ListingStatus current) {
  switch (current) {
    case ListingStatus.active:
      return const [
        MyListingAction.markSold,
        MyListingAction.hide,
        MyListingAction.archive,
      ];
    case ListingStatus.hidden:
      return const [
        MyListingAction.reactivate,
        MyListingAction.markSold,
        MyListingAction.archive,
      ];
    case ListingStatus.sold:
      return const [
        MyListingAction.reactivate,
        MyListingAction.archive,
      ];
    case ListingStatus.archived:
      return const [MyListingAction.reactivate];
  }
}

String statusActionLabel(AppLocalizations l10n, MyListingAction action) {
  switch (action) {
    case MyListingAction.edit:
      return l10n.actionEdit;
    case MyListingAction.reactivate:
      return l10n.actionReactivate;
    case MyListingAction.markSold:
      return l10n.actionMarkSold;
    case MyListingAction.hide:
      return l10n.actionHide;
    case MyListingAction.archive:
      return l10n.actionArchive;
    case MyListingAction.deletePermanently:
      return l10n.actionDeletePermanently;
  }
}

/// Maps the status-transition subset of [MyListingAction] back to a
/// target [ListingStatus]. Returns null for [MyListingAction.edit]
/// (which is a navigation action, not a status change).
ListingStatus? statusTargetFor(MyListingAction action) {
  switch (action) {
    case MyListingAction.edit:
    case MyListingAction.deletePermanently:
      return null;
    case MyListingAction.reactivate:
      return ListingStatus.active;
    case MyListingAction.markSold:
      return ListingStatus.sold;
    case MyListingAction.hide:
      return ListingStatus.hidden;
    case MyListingAction.archive:
      return ListingStatus.archived;
  }
}
