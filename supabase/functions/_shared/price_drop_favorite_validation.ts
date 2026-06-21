/**
 * Price drop favorite delivery validation helpers (P2 V1).
 *
 * Favorite match is enforced at enqueue in SQL; Edge revalidates at send time.
 * Does not expose price amounts or other private fields in FCM data.
 */

/** Skip when the favorite row no longer exists for this recipient/listing. */
export const FAVORITE_MISSING_SKIP_REASON = "favorite_missing";

/** Skip when the listing is gone or no longer active. */
export const LISTING_INACTIVE_OR_MISSING_SKIP_REASON =
  "listing_inactive_or_missing";

/** Requeue/fail when favorite or listing validation queries fail. */
export const PRICE_DROP_VALIDATION_FAILED = "price_drop_validation_failed";

export type ListingDeliveryRow = {
  status: string | null;
  seller_id: string | null;
};

/**
 * Listing must still be active and owned by the event actor (seller).
 */
export function isListingEligibleForPriceDropDelivery(
  listing: ListingDeliveryRow | null | undefined,
  actorUserId: string | null | undefined,
): boolean {
  if (!listing || !actorUserId) return false;
  if (listing.status !== "active") return false;
  if (!listing.seller_id) return false;
  return listing.seller_id === actorUserId;
}

/** Minimal FCM data keys for price-drop tap routing (no price or PII). */
export function priceDropNotificationDataPayload(event: {
  id: string;
  listing_id: string | null;
}): Record<string, string> {
  const d: Record<string, string> = { type: "price_drop" };
  if (event.listing_id) d.listing_id = event.listing_id;
  d.event_id = event.id;
  return d;
}
