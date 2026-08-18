/**
 * Filter alert delivery validation helpers (P1 M1.4 Phase B).
 *
 * Edge validates enabled saved searches at send time. Criteria matching is
 * enforced at enqueue by SQL (`listing_matches_saved_discovery_criteria`);
 * this module does not inspect or expose criteria JSON.
 */

/** `notification_delivery_events.last_error` when no enabled saved search exists. */
export const SAVED_SEARCH_DISABLED_OR_MISSING_SKIP_REASON =
  "saved_search_disabled_or_missing";

/** Requeue/fail when saved-search or listing validation queries fail. */
export const SAVED_SEARCH_VALIDATION_FAILED = "saved_search_validation_failed";

/** Skip when the listing is gone, inactive, or no longer owned by the actor. */
export const LISTING_INACTIVE_OR_MISSING_SKIP_REASON =
  "listing_inactive_or_missing";

export type SavedSearchValidationRow = {
  alerts_enabled: boolean;
  criteria: unknown;
};

export type ListingDeliveryRow = {
  status: string | null;
  seller_id: string | null;
};

/**
 * True when at least one saved search has alerts enabled and non-null criteria.
 */
export function recipientHasEnabledSavedSearchWithCriteria(
  rows: SavedSearchValidationRow[] | null | undefined,
): boolean {
  if (!rows || rows.length === 0) return false;
  return rows.some(rowHasEnabledSavedSearchWithCriteria);
}

export function rowHasEnabledSavedSearchWithCriteria(
  row: SavedSearchValidationRow,
): boolean {
  return (
    row.alerts_enabled === true &&
    row.criteria !== null &&
    row.criteria !== undefined &&
    typeof row.criteria === "object" &&
    !Array.isArray(row.criteria)
  );
}

/**
 * Listing must still be active and owned by the event actor (seller).
 */
export function isListingEligibleForFilterAlertDelivery(
  listing: ListingDeliveryRow | null | undefined,
  actorUserId: string | null | undefined,
): boolean {
  if (!listing || !actorUserId) return false;
  if (listing.status !== "active") return false;
  if (!listing.seller_id) return false;
  return listing.seller_id === actorUserId;
}

/** Minimal FCM data keys for filter-alert tap routing (no criteria or PII). */
export function filterAlertNotificationDataPayload(event: {
  listing_id: string | null;
}): Record<string, string> {
  const d: Record<string, string> = { type: "filter_alert" };
  if (event.listing_id) d.listing_id = event.listing_id;
  return d;
}
