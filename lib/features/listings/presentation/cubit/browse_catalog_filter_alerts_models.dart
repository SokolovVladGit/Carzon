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

  /// The catalog bell was tapped while the current draft already
  /// matched the saved alert criteria, so the bell acted as a toggle
  /// and cleared the saved alert (criteria + `notifications_enabled`
  /// flip to null/false in one server upsert). Use this when callers
  /// want to differentiate a tap-to-remove success from a save success.
  savedAlertCleared,

  /// Clearing the saved alert via the catalog bell failed (RPC/network
  /// error). Distinct from [prefsOrRowFailed] so the UI can surface a
  /// clear-specific message in a future iteration.
  savedAlertClearFailed,

  /// User denied OS notification permission during enable flow.
  osPermissionDenied,

  /// Updating notification_preferences or filter-alert row failed unexpectedly.
  prefsOrRowFailed,

  /// Saving filter-alert criteria failed.
  criteriaSaveFailed,

  /// Filter-alert delivery toggled **off**.
  deliveriesDisabled,

  /// Filter-alert delivery toggled **on**.
  deliveriesEnabled,

  /// No UX surface needed (silent).
  noop,
}
