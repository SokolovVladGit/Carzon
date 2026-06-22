/**
 * Sheriff retail HTML provider.
 */

import { parseSheriffRetailHtml } from "./sheriff_retail_mapping.ts";
import type {
  FuelPriceFetchInput,
  FuelPriceProvider,
  FuelPriceProviderResult,
} from "./types.ts";
import {
  FUEL_PRICE_FETCH_TIMEOUT_MS,
  PMR_LIMITATION_CODES,
  SHERIFF_RETAIL_URL,
} from "./types.ts";

export class SheriffRetailProvider implements FuelPriceProvider {
  readonly id = "sheriff_retail_html";

  async fetch(input: FuelPriceFetchInput): Promise<FuelPriceProviderResult> {
    if (input.sourceId !== "sheriff_retail_html") {
      return unsupportedSource();
    }

    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      FUEL_PRICE_FETCH_TIMEOUT_MS,
    );

    try {
      const response = await fetch(SHERIFF_RETAIL_URL, {
        method: "GET",
        headers: {
          Accept: "text/html",
          "User-Agent": "CarzonFuelPricesWorker/1.0",
        },
        signal: controller.signal,
      });

      if (!response.ok) {
        return {
          ok: false,
          error: {
            code: "sheriff_http_error",
            safeMessage: "sheriff_http_error",
            retryable: response.status >= 500 || response.status === 429,
          },
        };
      }

      const html = await response.text();
      const parsed = parseSheriffRetailHtml(html);
      if (parsed == null) {
        return {
          ok: false,
          error: {
            code: "sheriff_parse_failed",
            safeMessage: "sheriff_parse_failed",
            retryable: false,
          },
        };
      }

      const status = parsed.items.length >= 5 ? "succeeded" : "partial";

      return {
        ok: true,
        status,
        normalizedSummary: parsed,
        limitationCodes: [...PMR_LIMITATION_CODES],
        sourceLabel: "Sheriff",
        effectiveDate: null,
        providerVersion: "sheriff-retail-v1",
        sourceMetadata: {
          providerId: this.id,
          providerVersion: "sheriff-retail-v1",
          board: "tiraspol_rub",
        },
      };
    } catch (error) {
      const aborted = error instanceof DOMException && error.name === "AbortError";
      return {
        ok: false,
        error: {
          code: aborted ? "sheriff_timeout" : "sheriff_fetch_failed",
          safeMessage: aborted ? "sheriff_timeout" : "sheriff_fetch_failed",
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
