/**
 * Fuel Prices provider types.
 */

export type FuelPriceTerritory = "moldova" | "pmr";

export type FuelPriceSourceId =
  | "anre_ecarburanti_plafon"
  | "sheriff_retail_html";

export type FuelPriceItem = {
  fuel_code: string;
  price: number;
};

export type FuelPriceNormalizedSummary = {
  territory: FuelPriceTerritory;
  currency: "MDL" | "PMR_RUB";
  unit: "liter";
  items: FuelPriceItem[];
  effective_date?: string | null;
};

export type FuelPriceFetchInput = {
  cacheKey: string;
  territory: FuelPriceTerritory;
  sourceId: FuelPriceSourceId;
  jobId: string;
};

export type FuelPriceProviderSuccess = {
  ok: true;
  status: "succeeded" | "partial";
  normalizedSummary: FuelPriceNormalizedSummary;
  limitationCodes: string[];
  sourceLabel: string;
  effectiveDate?: string | null;
  providerVersion: string;
  sourceMetadata: Record<string, unknown>;
};

export type FuelPriceProviderFailure = {
  ok: false;
  error: {
    code: string;
    safeMessage: string;
    retryable: boolean;
  };
};

export type FuelPriceProviderResult =
  | FuelPriceProviderSuccess
  | FuelPriceProviderFailure;

export interface FuelPriceProvider {
  readonly id: string;
  fetch(input: FuelPriceFetchInput): Promise<FuelPriceProviderResult>;
}

export const MOLDOVA_LIMITATION_CODES = [
  "national_ceiling",
  "verify_at_station",
] as const;

export const PMR_LIMITATION_CODES = [
  "sheriff_network",
  "verify_at_station",
  "no_source_effective_date",
] as const;

export const ANRE_PLAFON_URL =
  "https://api.ecarburanti.anre.md/public/plafon/";

export const SHERIFF_RETAIL_URL =
  "https://www.sheriff.md/activities/nefteprodukty/ceny_po_regionam/";

export const FUEL_PRICE_FETCH_TIMEOUT_MS = 20_000;
