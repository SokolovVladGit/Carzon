/**
 * ANRE e-Carburanți plafon provider.
 */

import {
  type AnrePlafonPayload,
  parseAnrePlafonPayload,
} from "./anre_plafon_mapping.ts";
import type {
  FuelPriceFetchInput,
  FuelPriceProvider,
  FuelPriceProviderResult,
} from "./types.ts";
import {
  ANRE_PLAFON_URL,
  FUEL_PRICE_FETCH_TIMEOUT_MS,
  MOLDOVA_LIMITATION_CODES,
} from "./types.ts";

export class AnrePlafonProvider implements FuelPriceProvider {
  readonly id = "anre_ecarburanti_plafon";

  async fetch(input: FuelPriceFetchInput): Promise<FuelPriceProviderResult> {
    if (input.sourceId !== "anre_ecarburanti_plafon") {
      return unsupportedSource();
    }

    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      FUEL_PRICE_FETCH_TIMEOUT_MS,
    );

    try {
      const response = await fetch(ANRE_PLAFON_URL, {
        method: "GET",
        headers: {
          Accept: "application/json",
          "User-Agent": "CarzonFuelPricesWorker/1.0",
        },
        signal: controller.signal,
      });

      if (!response.ok) {
        return {
          ok: false,
          error: {
            code: "anre_http_error",
            safeMessage: "anre_http_error",
            retryable: response.status >= 500 || response.status === 429,
          },
        };
      }

      const payload = await response.json() as AnrePlafonPayload;
      const parsed = parseAnrePlafonPayload(payload);
      if (parsed == null) {
        return {
          ok: false,
          error: {
            code: "anre_parse_failed",
            safeMessage: "anre_parse_failed",
            retryable: false,
          },
        };
      }

      const status = parsed.summary.items.length >= 2 ? "succeeded" : "partial";

      return {
        ok: true,
        status,
        normalizedSummary: parsed.summary,
        limitationCodes: [...MOLDOVA_LIMITATION_CODES],
        sourceLabel: "ANRE · e-Carburanți",
        effectiveDate: parsed.effectiveDate,
        providerVersion: "anre-plafon-v1",
        sourceMetadata: {
          providerId: this.id,
          providerVersion: "anre-plafon-v1",
          effectiveDate: parsed.effectiveDate,
        },
      };
    } catch (error) {
      const aborted = error instanceof DOMException && error.name === "AbortError";
      return {
        ok: false,
        error: {
          code: aborted ? "anre_timeout" : "anre_fetch_failed",
          safeMessage: aborted ? "anre_timeout" : "anre_fetch_failed",
          retryable: true,
        },
      };
    } finally {
      clearTimeout(timeout);
    }
  }
}

function unsupportedSource(): FuelPriceProviderResult {
  return {
    ok: false,
    error: {
      code: "unsupported_source",
      safeMessage: "unsupported_source",
      retryable: false,
    },
  };
}
