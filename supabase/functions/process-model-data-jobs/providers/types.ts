/**
 * Shared types for Model Passport fetch providers (Phase 1: fake only).
 */

export type ModelDataFetchInput = {
  lookupMake: string;
  lookupModel: string;
  lookupYear: number;
  sourceId: string;
  jobId: string;
  cacheKey: string;
};

export type EpaCompatibleSummary = {
  provider_vehicle_id?: string | null;
  fuel_type?: string | null;
  city_mpg?: number | null;
  highway_mpg?: number | null;
  combined_mpg?: number | null;
  city_l_per_100km?: number | null;
  highway_l_per_100km?: number | null;
  combined_l_per_100km?: number | null;
  co2_g_per_mile?: number | null;
  co2_g_per_km?: number | null;
  vehicle_class?: string | null;
  drive?: string | null;
  transmission?: string | null;
  engine_descriptor?: string | null;
  market?: string | null;
  match_quality?: string | null;
};

export type ModelDataProviderSuccess = {
  ok: true;
  status: "succeeded" | "partial" | "no_data";
  confidence: string;
  normalizedSummary: EpaCompatibleSummary;
  limitationCodes: string[];
  matchQuality: string | null;
  sourceLabel: string;
  providerVersion: string;
  sourceMetadata: Record<string, unknown>;
};

export type ModelDataProviderFailure = {
  ok: false;
  error: {
    code: string;
    safeMessage: string;
    retryable: boolean;
  };
};

export type ModelDataProviderResult =
  | ModelDataProviderSuccess
  | ModelDataProviderFailure;

export interface ModelDataProvider {
  readonly id: string;
  fetch(input: ModelDataFetchInput): Promise<ModelDataProviderResult>;
}

export const DEFAULT_EPA_LIMITATION_CODES = [
  "us_market_data_only",
  "may_differ_by_trim_engine_market",
  "model_level_not_exact_vehicle",
  "not_vehicle_history",
  "not_recall_data",
] as const;
