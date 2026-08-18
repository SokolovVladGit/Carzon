import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  filterAlertNotificationDataPayload,
  isListingEligibleForFilterAlertDelivery,
  LISTING_INACTIVE_OR_MISSING_SKIP_REASON,
  recipientHasEnabledSavedSearchWithCriteria,
  rowHasEnabledSavedSearchWithCriteria,
  SAVED_SEARCH_DISABLED_OR_MISSING_SKIP_REASON,
  SAVED_SEARCH_VALIDATION_FAILED,
} from "./filter_alert_saved_search_validation.ts";

Deno.test("recipientHasEnabledSavedSearchWithCriteria accepts enabled row with criteria", () => {
  assertEquals(
    recipientHasEnabledSavedSearchWithCriteria([
      { alerts_enabled: true, criteria: { schemaVersion: 1 } },
    ]),
    true,
  );
});

Deno.test("recipientHasEnabledSavedSearchWithCriteria rejects empty list", () => {
  assertEquals(recipientHasEnabledSavedSearchWithCriteria([]), false);
  assertEquals(recipientHasEnabledSavedSearchWithCriteria(null), false);
  assertEquals(recipientHasEnabledSavedSearchWithCriteria(undefined), false);
});

Deno.test("recipientHasEnabledSavedSearchWithCriteria rejects alerts disabled", () => {
  assertEquals(
    recipientHasEnabledSavedSearchWithCriteria([
      { alerts_enabled: false, criteria: { schemaVersion: 1 } },
    ]),
    false,
  );
});

Deno.test("rowHasEnabledSavedSearchWithCriteria rejects null or array criteria", () => {
  assertEquals(
    rowHasEnabledSavedSearchWithCriteria({ alerts_enabled: true, criteria: null }),
    false,
  );
  assertEquals(
    rowHasEnabledSavedSearchWithCriteria({ alerts_enabled: true, criteria: [] }),
    false,
  );
});

Deno.test("isListingEligibleForFilterAlertDelivery requires active listing and actor seller", () => {
  assertEquals(
    isListingEligibleForFilterAlertDelivery(
      { status: "active", seller_id: "seller-1" },
      "seller-1",
    ),
    true,
  );
  assertEquals(
    isListingEligibleForFilterAlertDelivery(
      { status: "draft", seller_id: "seller-1" },
      "seller-1",
    ),
    false,
  );
  assertEquals(
    isListingEligibleForFilterAlertDelivery(
      { status: "active", seller_id: "seller-1" },
      "other-user",
    ),
    false,
  );
  assertEquals(isListingEligibleForFilterAlertDelivery(null, "seller-1"), false);
});

Deno.test("filterAlertNotificationDataPayload is minimal and safe", () => {
  const payload = filterAlertNotificationDataPayload({
    listing_id: "listing-1",
  });
  assertEquals(payload, {
    type: "filter_alert",
    listing_id: "listing-1",
  });
  assertEquals(Object.keys(payload).includes("event_id"), false);
  assertEquals(Object.keys(payload).includes("criteria"), false);
  assertEquals(Object.keys(payload).includes("saved_search_id"), false);
  assertEquals(JSON.stringify(payload).toLowerCase().includes("vin"), false);
});

Deno.test("skip and validation error codes are stable", () => {
  assertEquals(
    SAVED_SEARCH_DISABLED_OR_MISSING_SKIP_REASON,
    "saved_search_disabled_or_missing",
  );
  assertEquals(SAVED_SEARCH_VALIDATION_FAILED, "saved_search_validation_failed");
  assertEquals(
    LISTING_INACTIVE_OR_MISSING_SKIP_REASON,
    "listing_inactive_or_missing",
  );
});
