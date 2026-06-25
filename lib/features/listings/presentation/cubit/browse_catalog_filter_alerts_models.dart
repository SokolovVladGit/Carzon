/// Result of a browse sheet filter-alert bell gesture (localized by caller).
enum BrowseCatalogBellOutcome {
  /// Caller should navigate to auth (user not signed in).
  signedOut,

  /// Inline filter fields failed validation ([peekValidatedApplyOutcome] null).
  filterSheetValidationFailed,

  /// Baseline feed / sort-only / otherwise too broad for alert subscription.
  criteriaTooBroad,

  /// PUSH_NOTIFICATIONS_ENABLED is false when the catalog bell or Saved
  /// Searches page tries to enable delivery.
  pushBuildDisabled,

  /// @deprecated Catalog bell no longer toggles delivery. Kept for migration.
  criteriaSavedDeliveryUnavailable,

  /// @deprecated Catalog bell no longer toggles delivery. Kept for migration.
  deliveriesDisabled,

  /// @deprecated Catalog bell no longer toggles delivery. Kept for migration.
  deliveriesEnabled,

  /// @deprecated Use [savedSearchRemoved]. Kept for test migration only.
  savedAlertCleared,

  /// @deprecated Use [savedSearchDeleteFailed]. Kept for test migration only.
  savedAlertClearFailed,

  /// User denied OS notification permission during enable flow.
  osPermissionDenied,

  /// Updating notification_preferences or a saved-search row failed unexpectedly.
  prefsOrRowFailed,

  /// Saving saved-search criteria failed.
  criteriaSaveFailed,

  /// Deleting a matched saved search from the catalog bell failed.
  savedSearchDeleteFailed,

  /// Matched saved search was removed via the catalog bell.
  savedSearchRemoved,

  /// New saved search persisted with `alerts_enabled=false`.
  savedSearchCreated,

  /// User already has the maximum number of saved searches (5).
  maxSavedSearchesReached,

  /// No UX surface needed (silent).
  noop,
}
