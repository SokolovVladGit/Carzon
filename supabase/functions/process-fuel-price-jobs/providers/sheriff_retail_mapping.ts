/**
 * Sheriff retail HTML mapping (Tiraspol / default RUB board).
 */

import type { FuelPriceItem, FuelPriceNormalizedSummary } from "./types.ts";

const FUEL_CLASS_TO_CODE: Record<string, string> = {
  "f-98": "ai_98",
  "f-95p": "ai_95_premium",
  "f-95": "ai_95",
  "f-dte": "diesel_euro",
  "f-dt": "diesel",
};

export function parseSheriffRetailHtml(
  html: string,
): FuelPriceNormalizedSummary | null {
  const block = extractTiraspolRubBlock(html);
  if (block == null) return null;

  const items: FuelPriceItem[] = [];
  for (const [cssClass, fuelCode] of Object.entries(FUEL_CLASS_TO_CODE)) {
    const price = parseFuelItemPrice(block, cssClass);
    if (price != null) {
      items.push({ fuel_code: fuelCode, price });
    }
  }

  if (items.length === 0) return null;

  return {
    territory: "pmr",
    currency: "PMR_RUB",
    unit: "liter",
    items,
    effective_date: null,
  };
}

function extractTiraspolRubBlock(html: string): string | null {
  const cityMatch = html.match(
    /city-01-view[\s\S]*?p-inner ru([\s\S]*?)p-inner en/i,
  );
  return cityMatch?.[1] ?? null;
}

function parseFuelItemPrice(block: string, cssClass: string): number | null {
  const itemMatch = block.match(
    new RegExp(
      `class="item ${cssClass}"[\\s\\S]*?class="first">\\s*([0-9]+)\\s*</span>[\\s\\S]*?class="last">\\s*([0-9]+)\\s*</span>`,
      "i",
    ),
  );
  if (!itemMatch) return null;

  const whole = itemMatch[1]?.trim();
  const fraction = itemMatch[2]?.trim();
  if (!whole || !fraction) return null;

  const value = Number(`${whole}.${fraction}`);
  if (!Number.isFinite(value)) return null;
  return Math.round(value * 100) / 100;
}
