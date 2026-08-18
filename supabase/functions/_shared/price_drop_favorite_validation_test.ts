import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  FAVORITE_MISSING_SKIP_REASON,
  isListingEligibleForPriceDropDelivery,
  LISTING_INACTIVE_OR_MISSING_SKIP_REASON,
  priceDropNotificationDataPayload,
} from "./price_drop_favorite_validation.ts";

Deno.test("priceDropNotificationDataPayload is minimal and safe", () => {
  const payload = priceDropNotificationDataPayload({
    listing_id: "aaaaaaaa-bbbb-4ccc-a123-aaaaaaaaaaaa",
  });
  assertEquals(payload.type, "price_drop");
  assertEquals(payload.listing_id, "aaaaaaaa-bbbb-4ccc-a123-aaaaaaaaaaaa");
  assertEquals(Object.keys(payload).sort(), ["listing_id", "type"]);
});

Deno.test("isListingEligibleForPriceDropDelivery requires active listing and actor seller", () => {
  assertEquals(
    isListingEligibleForPriceDropDelivery(
      { status: "active", seller_id: "seller-1" },
      "seller-1",
    ),
    true,
  );
  assertEquals(
    isListingEligibleForPriceDropDelivery(
      { status: "hidden", seller_id: "seller-1" },
      "seller-1",
    ),
    false,
  );
  assertEquals(
    isListingEligibleForPriceDropDelivery(
      { status: "active", seller_id: "other" },
      "seller-1",
    ),
    false,
  );
});

Deno.test("skip reason codes are stable", () => {
  assertEquals(FAVORITE_MISSING_SKIP_REASON, "favorite_missing");
  assertEquals(LISTING_INACTIVE_OR_MISSING_SKIP_REASON, "listing_inactive_or_missing");
});
