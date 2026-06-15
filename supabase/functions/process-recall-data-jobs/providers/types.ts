/**
 * Shared types for Recall / Safety Campaigns fetch providers.
 */

export type RecallFetchInput = {
  lookupMake: string;
  lookupModel: string;
  lookupYear: number;
  sourceId: string;
  jobId: string;
  cacheKey: string;
};

export type RecallCampaignSummary = {
  campaign_number?: string | null;
  manufacturer?: string | null;
  component?: string | null;
  summary?: string | null;
  consequence?: string | null;
  remedy?: string | null;
  notes?: string | null;
  report_received_date?: string | null;
  nhtsa_action_number?: string | null;
  park_it?: boolean | null;
  park_outside?: boolean | null;
  over_the_air_update?: boolean | null;
  model_year?: number | null;
  make?: string | null;
  model?: string | null;
};

export type RecallNormalizedSummary = {
  campaigns?: RecallCampaignSummary[];
  campaign_count?: number;
  market?: string | null;
  match_quality?: string | null;
};

export type RecallProviderSuccess = {
  ok: true;
  status: "succeeded" | "partial" | "no_data";
  normalizedSummary: RecallNormalizedSummary;
  limitationCodes: string[];
  matchQuality: string | null;
  sourceLabel: string;
  sourceUpdatedAt: string | null;
  sourceMetadata: Record<string, unknown>;
};

export type RecallProviderFailure = {
  ok: false;
  error: {
    code: string;
    safeMessage: string;
    retryable: boolean;
  };
};

export type RecallProviderResult = RecallProviderSuccess | RecallProviderFailure;

export interface RecallProvider {
  readonly id: string;
  fetch(input: RecallFetchInput): Promise<RecallProviderResult>;
}

export const ALLOWLISTED_CAMPAIGN_KEYS = [
  "campaign_number",
  "manufacturer",
  "component",
  "summary",
  "consequence",
  "remedy",
  "notes",
  "report_received_date",
  "nhtsa_action_number",
  "park_it",
  "park_outside",
  "over_the_air_update",
  "model_year",
  "make",
  "model",
] as const;

export const DEFAULT_RECALL_LIMITATION_CODES = [
  "us_market_data_only",
  "model_level_not_exact_vehicle",
  "not_vin_verified_recall_status",
  "may_differ_by_trim_engine_market",
  "verify_with_official_dealer_or_nhtsa",
] as const;

export const NHTSA_RECALLS_PROVIDER_VERSION = "recallsByVehicle-v1";
export const NHTSA_RECALLS_SOURCE_LABEL = "NHTSA";
