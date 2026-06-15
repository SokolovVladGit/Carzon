/**
 * Model Passport provider factory.
 *
 * Modes:
 * - fake (default): non-production no_data
 * - fake_sample: deterministic sample row for Toyota Camry 2020
 * - epa: real FuelEconomy.gov REST (opt-in only)
 */

import type { ModelDataProvider } from "./types.ts";
import { EpaFuelEconomyProvider } from "./epa_provider.ts";
import { FakeModelDataProvider } from "./fake_provider.ts";

export type ModelDataProviderMode = "fake" | "fake_sample" | "epa";

export function normalizeProviderMode(
  raw: string | undefined | null,
): ModelDataProviderMode | null {
  const v = (raw ?? "fake").trim().toLowerCase();
  if (v === "fake" || v === "") return "fake";
  if (v === "fake_sample") return "fake_sample";
  if (v === "epa") return "epa";
  return null;
}

export function createModelDataProvider(
  mode: ModelDataProviderMode,
): ModelDataProvider {
  if (mode === "epa") {
    return new EpaFuelEconomyProvider();
  }
  return new FakeModelDataProvider(mode);
}
