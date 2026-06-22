import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { normalizeProviderMode } from "./factory.ts";

Deno.test("normalizeProviderMode accepts live and fake", () => {
  assertEquals(normalizeProviderMode("live"), "live");
  assertEquals(normalizeProviderMode("LIVE"), "live");
  assertEquals(normalizeProviderMode("fake"), "fake");
  assertEquals(normalizeProviderMode(" fake "), "fake");
});

Deno.test("normalizeProviderMode rejects missing and invalid values", () => {
  assertEquals(normalizeProviderMode(undefined), null);
  assertEquals(normalizeProviderMode(null), null);
  assertEquals(normalizeProviderMode(""), null);
  assertEquals(normalizeProviderMode("   "), null);
  assertEquals(normalizeProviderMode("production"), null);
});
