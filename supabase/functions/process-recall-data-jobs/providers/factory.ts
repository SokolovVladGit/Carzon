/**
 * Recall provider factory.
 *
 * Modes:
 * - fake (default): non-production no_data
 * - fake_sample: deterministic Toyota Camry 2020 sample campaigns
 * - nhtsa: real NHTSA recallsByVehicle API (opt-in only)
 */

import type { RecallProvider } from "./types.ts";
import { FakeRecallProvider } from "./fake_provider.ts";
import { NhtsaRecallsProvider } from "./nhtsa_provider.ts";

export type RecallProviderMode = "fake" | "fake_sample" | "nhtsa";

export function normalizeProviderMode(
  raw: string | undefined | null,
): RecallProviderMode | null {
  const value = (raw ?? "fake").trim().toLowerCase();
  if (value === "fake" || value === "") return "fake";
  if (value === "fake_sample") return "fake_sample";
  if (value === "nhtsa") return "nhtsa";
  return null;
}

export function createRecallProvider(mode: RecallProviderMode): RecallProvider {
  if (mode === "nhtsa") {
    return new NhtsaRecallsProvider();
  }
  return new FakeRecallProvider(mode);
}
