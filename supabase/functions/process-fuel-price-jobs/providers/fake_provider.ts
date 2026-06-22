/**
 * Fake fuel-price provider — deterministic fixtures, no HTTP.
 */

import type {
  FuelPriceFetchInput,
  FuelPriceProvider,
  FuelPriceProviderResult,
} from "./types.ts";
import {
  MOLDOVA_LIMITATION_CODES,
  PMR_LIMITATION_CODES,
} from "./types.ts";

const FAKE_MOLDOVA = {
  territory: "moldova" as const,
  currency: "MDL" as const,
  unit: "liter" as const,
  effective_date: "2026-06-22",
  items: [
    { fuel_code: "gasoline_95", price: 27.99 },
    { fuel_code: "diesel", price: 25.86 },
  ],
};

const FAKE_PMR = {
  territory: "pmr" as const,
  currency: "PMR_RUB" as const,
  unit: "liter" as const,
  effective_date: null,
  items: [
    { fuel_code: "ai_98", price: 29.4 },
    { fuel_code: "ai_95_premium", price: 26.3 },
    { fuel_code: "ai_95", price: 26.0 },
    { fuel_code: "diesel_euro", price: 24.2 },
    { fuel_code: "diesel", price: 24.0 },
  ],
};

export class FakeFuelPriceProvider implements FuelPriceProvider {
  readonly id = "carzon_fake_fuel_prices";

  async fetch(input: FuelPriceFetchInput): Promise<FuelPriceProviderResult> {
    if (input.sourceId === "anre_ecarburanti_plafon") {
      return {
        ok: true,
        status: "succeeded",
        normalizedSummary: FAKE_MOLDOVA,
        limitationCodes: [...MOLDOVA_LIMITATION_CODES],
        sourceLabel: "ANRE · e-Carburanți (fake)",
        effectiveDate: FAKE_MOLDOVA.effective_date,
        providerVersion: "fake-v1",
        sourceMetadata: {
          providerId: this.id,
          providerVersion: "fake-v1",
          fake: true,
        },
      };
    }

    if (input.sourceId === "sheriff_retail_html") {
      return {
        ok: true,
        status: "succeeded",
        normalizedSummary: FAKE_PMR,
        limitationCodes: [...PMR_LIMITATION_CODES],
        sourceLabel: "Sheriff (fake)",
        effectiveDate: null,
        providerVersion: "fake-v1",
        sourceMetadata: {
          providerId: this.id,
          providerVersion: "fake-v1",
          fake: true,
        },
      };
    }

    return {
      ok: false,
      error: {
        code: "unsupported_source",
        safeMessage: "unsupported_source",
        retryable: false,
      },
    };
  }
}
