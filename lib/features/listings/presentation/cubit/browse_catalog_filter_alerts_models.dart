/// Result of a browse sheet filter-alert bell gesture (localized by caller).
enum BrowseCatalogBellOutcome {
  /// Caller should navigate to auth (user not signed in).
  signedOut,

  /// Inline filter fields failed validation ([peekValidatedApplyOutcome] null).
  filterSheetValidationFailed,

  /// Baseline feed / sort-only / otherwise too broad for alert subscription.
  criteriaTooBroad,

  /// PUSH_NOTIFICATIONS_ENABLED is false **and** the caller explicitly
  /// requested delivery to be enabled. Reserved for surfaces that try to
  /// flip delivery on (`/filter-alert`'s explicit toggle, future debug
  /// tools). The catalog bell never returns this — it uses
  /// [criteriaSavedDeliveryUnavailable] instead, since tapping the bell
  /// in a push-disabled build still successfully persists criteria.
  pushBuildDisabled,

  /// Eligible criteria were saved, but delivery cannot be enabled
  /// because `PUSH_NOTIFICATIONS_ENABLED` is false in this build.
  ///
  /// Criteria persistence and `notification_preferences` semantics are
  /// independent of push availability: the row remains with
  /// `notifications_enabled = false`. The catalog UI surfaces a
  /// success-shaped snackbar and shows a "saved, delivery pending"
  /// bell state instead of treating the action as a hard failure.
  criteriaSavedDeliveryUnavailable,

  /// Filter-alert delivery toggled **off** for the matched saved search.
  deliveriesDisabled,

  /// Filter-alert delivery toggled **on** for the current filter criteria.
  deliveriesEnabled,

  /// @deprecated Use [deliveriesDisabled]. Kept for test migration only.
  savedAlertCleared,

  /// @deprecated Use [prefsOrRowFailed]. Kept for test migration only.
  savedAlertClearFailed,

  /// User denied OS notification permission during enable flow.
  osPermissionDenied,

  /// Updating notification_preferences or a saved-search row failed unexpectedly.
  prefsOrRowFailed,

  /// Saving saved-search criteria failed.
  criteriaSaveFailed,

  /// User already has the maximum number of saved searches (5).
  maxSavedSearchesReached,

  /// No UX surface needed (silent).
  noop,
}
