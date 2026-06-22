/**
 * Fuel Prices provider factory.
 *
 * Modes (CARZON_FUEL_PRICE_PROVIDER_MODE must be set explicitly):
 * - live: real ANRE JSON + Sheriff HTML providers
 * - fake: deterministic fixtures, no HTTP (tests/local only)
 */

import type { FuelPriceProvider, FuelPriceSourceId } from "./types.ts";
import { AnrePlafonProvider } from "./anre_plafon_provider.ts";
import { FakeFuelPriceProvider } from "./fake_provider.ts";
import { SheriffRetailProvider } from "./sheriff_retail_provider.ts";

export type FuelPriceProviderMode = "fake" | "live";

export function normalizeProviderMode(
  raw: string | undefined | null,
): FuelPriceProviderMode | null {
  if (raw == null || raw.trim() === "") {
    return null;
  }
  const v = raw.trim().toLowerCase();
  if (v === "fake") return "fake";
  if (v === "live") return "live";
  return null;
}

export function createFuelPriceProvider(
  mode: FuelPriceProviderMode,
  sourceId: FuelPriceSourceId,
): FuelPriceProvider {
  if (mode === "live") {
    if (sourceId === "anre_ecarburanti_plafon") {
      return new AnrePlafonProvider();
    }
    return new SheriffRetailProvider();
  }
  return new FakeFuelPriceProvider();
}
