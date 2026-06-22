/**
 * ANRE e-Carburanți plafon JSON mapping.
 */

import type {
  FuelPriceItem,
  FuelPriceNormalizedSummary,
  FuelPriceTerritory,
} from "./types.ts";

export type AnrePlafonPayload = {
  date?: string;
  b_pc?: number;
  m_pc?: number;
};

export function parseAnrePlafonPayload(
  payload: AnrePlafonPayload,
): { summary: FuelPriceNormalizedSummary; effectiveDate: string | null } | null {
  const items: FuelPriceItem[] = [];

  if (typeof payload.b_pc === "number" && Number.isFinite(payload.b_pc)) {
    items.push({ fuel_code: "gasoline_95", price: roundPrice(payload.b_pc) });
  }
  if (typeof payload.m_pc === "number" && Number.isFinite(payload.m_pc)) {
    items.push({ fuel_code: "diesel", price: roundPrice(payload.m_pc) });
  }

  if (items.length === 0) return null;

  const effectiveDate = normalizeIsoDate(payload.date);

  return {
    effectiveDate,
    summary: {
      territory: "moldova" satisfies FuelPriceTerritory,
      currency: "MDL",
      unit: "liter",
      items,
      effective_date: effectiveDate,
    },
  };
}

function roundPrice(value: number): number {
  return Math.round(value * 100) / 100;
}

function normalizeIsoDate(raw: string | undefined): string | null {
  if (typeof raw !== "string") return null;
  const trimmed = raw.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return null;
  return trimmed;
}
