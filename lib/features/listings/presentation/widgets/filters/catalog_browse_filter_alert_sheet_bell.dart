import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/l10n/app_localizations_x.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/listings/domain/browse_state_for_alert_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/listings/presentation/utils/listing_filter_apply_to_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/utils/saved_search_auto_name.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_alert_ui_constants.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_models.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';

/// Inline notice surfaces the catalog filter-sheet bell can publish back
/// to the sheet host. Used to keep validation/feedback that originated
/// *inside* the open sheet from leaking onto the listings page after the
/// modal closes (previous bug: root-snackbar bleed for too-broad
/// criteria).
enum CatalogBellInlineNotice {
  /// Cubit rejected the bell tap because the current draft was too
  /// broad to save (no search, make, model, year, mileage, price, city
  /// or region — see `BrowseCatalogBellOutcome.criteriaTooBroad`).
  criteriaTooBroad,
}

/// Header bell inside the browse filter sheet ([ListingsFilterHost] trailing slot).
///
/// Stateful so we can schedule a one-shot post-frame rebuild: in the first
/// frame after the sheet opens, the [ListingsFilterForm] has not finished
/// `initState` yet so [GlobalKey.currentState] is null, which used to leave
/// the bell stuck in the inactive glyph even when the applied catalog
/// criteria already matched a saved alert. The post-frame callback forces a
/// second build so the form-derived draft takes over immediately.
///
/// The [appliedState] fallback provides the same canonical criteria the
/// main catalog FAB uses ([listingDiscoveryCriteriaFromBrowseStateForAlert])
/// for the *initial* build, eliminating any inactive flash before the
/// post-frame callback lands.
class CatalogBrowseFilterAlertSheetBell extends StatefulWidget {
  const CatalogBrowseFilterAlertSheetBell({
    super.key,
    required this.sheetFormKey,
    required this.sheetContext,
    required this.searchSnippet,
    required this.appliedState,
    this.onInlineNoticeRequested,
  });

  static const bellKey = Key('catalog_browse_filter_alert_sheet_bell');

  final GlobalKey<ListingsFilterFormState> sheetFormKey;
  final BuildContext sheetContext;
  final String Function() searchSnippet;

  /// Canonical catalog [ListingsState] in effect when the sheet opened.
  ///
  /// Used as the *initial* draft criteria so the bell matches the main
  /// catalog FAB indicator from the very first frame, before the form's
  /// [GlobalKey.currentState] becomes available. After the user mutates
  /// a field (`onBrowseDraftMutated` → `setSheetState`), the form-derived
  /// outcome takes over so the bell tracks the live draft instead.
  final ListingsState appliedState;

  /// Optional hook used by the sheet builder to render a sheet-local
  /// notice (e.g. "Refine the filter to save an alert") inside the
  /// modal instead of relying on the root [ScaffoldMessenger], which
  /// would bleed snackbars onto the catalog page after the sheet
  /// closes. The bell calls this with a payload after a rejected tap
  /// and clears it (`null`) after any successful or non-blocking
  /// outcome, so stale notices never linger.
  final ValueChanged<CatalogBellInlineNotice?>? onInlineNoticeRequested;

  @override
  State<CatalogBrowseFilterAlertSheetBell> createState() =>
      _CatalogBrowseFilterAlertSheetBellState();
}

class _CatalogBrowseFilterAlertSheetBellState
    extends State<CatalogBrowseFilterAlertSheetBell> {
  @override
  void initState() {
    super.initState();
    // The ListingsFilterForm is built in the same frame as this widget
    // (both live under ListingsFilterHost). Its GlobalKey.currentState
    // is therefore null during our first build, which would leave the
    // bell stuck on the "no draft" path. Schedule a single rebuild
    // after the first frame so we can read form state on the second
    // pass. The post-frame rebuild is a no-op if the widget unmounted
    // in the meantime (e.g. sheet dismissed mid-frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<
      BrowseCatalogFilterAlertsCubit,
      BrowseCatalogFilterAlertsState
    >(
      builder: (context, alerts) {
        final draftCrit = _resolveDraftCriteria();

        final cubit = context.read<BrowseCatalogFilterAlertsCubit>();
        final bool deliveryOn = cubit.browseBellShowsActiveDraft(draftCrit);
        final bool savedNoDelivery =
            !deliveryOn &&
            cubit.browseBellShowsSavedDraftWithoutDelivery(draftCrit);

        final l10n = widget.sheetContext.l10n;
        late final IconData bellIcon;
        late final Color fg;
        late final double iconSize;
        late final String tooltip;
        if (deliveryOn) {
          bellIcon = Icons.notifications_active;
          fg = CatalogFilterAlertAccent.amber;
          iconSize = 22;
          tooltip = l10n.catalogBrowseFilterBellActiveTooltip;
        } else if (savedNoDelivery) {
          // Saved-but-delivery-off reads "saved" without faking active
          // delivery: a filled bell (vs the outlined inactive glyph) at
          // a slightly larger size, in muted amber. Still visibly weaker
          // than the strong amber active state above.
          bellIcon = Icons.notifications;
          fg = CatalogFilterAlertAccent.savedNoDelivery(scheme);
          iconSize = 24;
          tooltip = l10n.catalogBrowseFilterBellSavedDeliveryUnavailableTooltip;
        } else {
          bellIcon = Icons.notifications_none;
          fg = CatalogFilterAlertAccent.inactiveStroke(scheme);
          iconSize = 22;
          tooltip = l10n.catalogBrowseFilterBellInactiveTooltip;
        }

        return SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            key: CatalogBrowseFilterAlertSheetBell.bellKey,
            padding: EdgeInsets.zero,
            tooltip: tooltip,
            onPressed: alerts.bellBusy
                ? null
                : () => unawaited(_onBellTapped(context)),
            icon: Icon(
              bellIcon,
              key: savedNoDelivery
                  ? CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey
                  : null,
              size: iconSize,
              color: fg,
              semanticLabel: tooltip,
            ),
          ),
        );
      },
    );
  }

  /// Canonical "what filter does the bell currently represent?".
  ///
  /// Order of preference:
  /// 1. The form's validated apply outcome merged with the live search
  ///    snippet (`listingDiscoveryCriteriaFromFilterApply`). This wins
  ///    whenever the form is mounted so live user edits drive the bell.
  /// 2. The catalog [appliedState] mapped via the same canonical
  ///    [listingDiscoveryCriteriaFromBrowseStateForAlert] the main
  ///    catalog FAB indicator uses. This guarantees that opening the
  ///    sheet on top of an already-matching applied filter shows the
  ///    saved/active bell on the very first frame, before the form
  ///    [GlobalKey] becomes available.
  ///
  /// Both paths feed into `listingDiscoveryCriteriaFromListingsState`
  /// under the hood, so their outputs are byte-equal for the same
  /// inputs (sort included) — guaranteeing the sheet bell and the FAB
  /// indicator never disagree about whether the draft matches a saved
  /// alert.
  ListingDiscoveryCriteria _resolveDraftCriteria() {
    final formState = widget.sheetFormKey.currentState;
    if (formState != null) {
      final apply = formState.peekValidatedApplyOutcome();
      if (apply != null) {
        final rawSearch = widget.searchSnippet().trim();
        final preservedSearch = rawSearch.isEmpty ? null : rawSearch;
        return listingDiscoveryCriteriaFromFilterApply(
          apply,
          preservedSearch: preservedSearch,
        );
      }
    }
    return listingDiscoveryCriteriaFromBrowseStateForAlert(widget.appliedState);
  }

  Future<void> _onBellTapped(BuildContext modalContext) async {
    final l10n = modalContext.l10n;
    final auth = modalContext.read<AuthCubit>().state;
    final authenticated = auth.status == AuthStatus.authenticated;

    final formState = widget.sheetFormKey.currentState;
    if (formState == null) return;

    final apply = formState.peekValidatedApplyOutcome();
    if (apply == null) {
      ScaffoldMessenger.maybeOf(modalContext)?.showSnackBar(
        SnackBar(content: Text(l10n.filterAlertApplyBlockedValidation)),
      );
      return;
    }

    final rawSearch = widget.searchSnippet().trim();
    final preservedSearch = rawSearch.isEmpty ? null : rawSearch;
    final draft = listingDiscoveryCriteriaFromFilterApply(
      apply,
      preservedSearch: preservedSearch,
    );

    final messenger = ScaffoldMessenger.maybeOf(modalContext);
    if (messenger == null) return;

    final outcome = await modalContext
        .read<BrowseCatalogFilterAlertsCubit>()
        .handleCatalogFilterBell(
          draftCriteria: draft,
          authenticated: authenticated,
          autoName: buildSavedSearchAutoName(l10n, draft),
        );

    if (kDebugMode) {
      debugPrint(
        '[catalogBellTap] outcome=$outcome '
        'authenticated=$authenticated',
      );
    }

    // Default: clear any stale inline notice on the sheet so that
    // success or non-blocking outcomes never leave a "refine filter"
    // pill stuck on top of a freshly-saved alert. The `criteriaTooBroad`
    // branch below overrides this with its own notice payload.
    widget.onInlineNoticeRequested?.call(null);

    switch (outcome) {
      case BrowseCatalogBellOutcome.signedOut:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.filterAlertSignInRequired),
            action: SnackBarAction(
              label: l10n.commonSignIn,
              onPressed: () => modalContext.go(AppRoutes.signIn),
            ),
          ),
        );
      case BrowseCatalogBellOutcome.filterSheetValidationFailed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.filterAlertApplyBlockedValidation)),
        );
      case BrowseCatalogBellOutcome.criteriaTooBroad:
        // Sheet-local inline notice instead of a root snackbar. The
        // bottom-sheet's `ScaffoldMessenger.maybeOf` resolves to the
        // *root* messenger, so any snackbar shown here outlives the
        // modal and bleeds onto the listings page after the user taps
        // "Show cars" — exactly the regression this branch removes.
        widget.onInlineNoticeRequested?.call(
          CatalogBellInlineNotice.criteriaTooBroad,
        );
      case BrowseCatalogBellOutcome.pushBuildDisabled:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.filterAlertNotificationsPushDisabled)),
        );
      case BrowseCatalogBellOutcome.criteriaSavedDeliveryUnavailable:
        // Intentionally no root snackbar. The sheet renders an inline
        // status banner (driven by `browseBellShowsSavedDraftWithoutDelivery`)
        // plus the dedicated saved-no-delivery bell glyph, and the main
        // catalog FAB switches to its saved-no-delivery ornament when
        // the user applies the matching draft. Surfacing a snackbar here
        // would bleed onto the catalog page after "Show cars" dismisses
        // the modal (the bottom sheet's ScaffoldMessenger is the root one)
        // and is exactly the regression Phase-4 follow-up addresses.
        break;
      case BrowseCatalogBellOutcome.savedAlertCleared:
        // Tap-to-remove success: state already updates (inline banner
        // disappears, bell returns to inactive, FAB ornament drops on
        // refresh). No root snackbar — a "Filter cleared" toast would
        // bleed onto the listings page through the root messenger and
        // contradict the silent toggle UX we want here.
        break;
      case BrowseCatalogBellOutcome.savedAlertClearFailed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.savedSearchDeleteFailed)),
        );
      case BrowseCatalogBellOutcome.osPermissionDenied:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.notificationSettingsOsPermissionDenied)),
        );
      case BrowseCatalogBellOutcome.prefsOrRowFailed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.notificationSettingsSaveFailed)),
        );
      case BrowseCatalogBellOutcome.criteriaSaveFailed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.savedSearchSaveFailed)),
        );
      case BrowseCatalogBellOutcome.maxSavedSearchesReached:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.savedSearchesMaxReachedSnack)),
        );
      case BrowseCatalogBellOutcome.deliveriesDisabled:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.catalogBrowseFilterBellDisabledSnack)),
        );
      case BrowseCatalogBellOutcome.deliveriesEnabled:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.catalogBrowseFilterBellEnabledSnack)),
        );
      case BrowseCatalogBellOutcome.noop:
        break;
    }
  }
}
