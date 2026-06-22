import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { parseAnrePlafonPayload } from "./anre_plafon_mapping.ts";

Deno.test("parseAnrePlafonPayload maps b_pc and m_pc", () => {
  const parsed = parseAnrePlafonPayload({
    date: "2026-06-22",
    b_pc: 27.99,
    m_pc: 25.86,
  });

  assertExists(parsed);
  assertEquals(parsed.effectiveDate, "2026-06-22");
  assertEquals(parsed.summary.currency, "MDL");
  assertEquals(parsed.summary.items.length, 2);
  assertEquals(parsed.summary.items[0]?.fuel_code, "gasoline_95");
  assertEquals(parsed.summary.items[0]?.price, 27.99);
  assertEquals(parsed.summary.items[1]?.fuel_code, "diesel");
  assertEquals(parsed.summary.items[1]?.price, 25.86);
});

Deno.test("parseAnrePlafonPayload rejects empty payload", () => {
  assertEquals(parseAnrePlafonPayload({}), null);
});
