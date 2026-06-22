import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { parseSheriffRetailHtml } from "./sheriff_retail_mapping.ts";

const FIXTURE = `
<div class="city-viev city-01-view">
  <div class="price">
    <div class="p-inner ru">
      <div class="item f-98">
        <span class="first">29</span>
        <span class="last">40</span>
      </div>
      <div class="item f-95p">
        <span class="first">26</span>
        <span class="last">30</span>
      </div>
      <div class="item f-95">
        <span class="first">26</span>
        <span class="last">00</span>
      </div>
      <div class="item f-dte">
        <span class="first">24</span>
        <span class="last">20</span>
      </div>
      <div class="item f-dt">
        <span class="first">24</span>
        <span class="last">00</span>
      </div>
    </div>
    <div class="p-inner en" style="display: none;">
      <div class="item f-95">
        <span class="first">1</span>
        <span class="last">59</span>
      </div>
    </div>
  </div>
</div>
`;

Deno.test("parseSheriffRetailHtml maps Tiraspol RUB board", () => {
  const parsed = parseSheriffRetailHtml(FIXTURE);
  assertExists(parsed);
  assertEquals(parsed.currency, "PMR_RUB");
  assertEquals(parsed.items.length, 5);
  assertEquals(parsed.items[0]?.fuel_code, "ai_98");
  assertEquals(parsed.items[0]?.price, 29.4);
  assertEquals(parsed.items[4]?.fuel_code, "diesel");
  assertEquals(parsed.items[4]?.price, 24.0);
});

Deno.test("parseSheriffRetailHtml ignores USD block", () => {
  const parsed = parseSheriffRetailHtml(FIXTURE);
  assertExists(parsed);
  assertEquals(
    parsed.items.some((item) => item.price === 1.59),
    false,
  );
});

Deno.test("parseSheriffRetailHtml rejects missing board", () => {
  assertEquals(parseSheriffRetailHtml("<html></html>"), null);
});
