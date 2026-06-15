/**
 * NHTSA recallsByVehicle response normalization (buyer-safe campaign rows only).
 */

import type {
  RecallCampaignSummary,
  RecallNormalizedSummary,
  RecallProviderResult,
} from "./types.ts";
import {
  ALLOWLISTED_CAMPAIGN_KEYS,
  DEFAULT_RECALL_LIMITATION_CODES,
  NHTSA_RECALLS_PROVIDER_VERSION,
  NHTSA_RECALLS_SOURCE_LABEL,
} from "./types.ts";

const NHTSA_RECALLS_BASE =
  "https://api.nhtsa.gov/recalls/recallsByVehicle";

function trimOrNull(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const text = String(value).trim();
  return text.length === 0 ? null : text;
}

function parseBoolean(value: unknown): boolean | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "boolean") return value;
  const normalized = String(value).trim().toLowerCase();
  if (normalized === "true" || normalized === "yes" || normalized === "y") {
    return true;
  }
  if (normalized === "false" || normalized === "no" || normalized === "n") {
    return false;
  }
  return null;
}

function parseModelYear(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number.parseInt(String(value).trim(), 10);
  if (!Number.isFinite(parsed) || parsed < 1900 || parsed > 2100) return null;
  return parsed;
}

function isValidYmd(year: number, month: number, day: number): boolean {
  if (year < 1900 || year > 2100 || month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }
  const dt = new Date(Date.UTC(year, month - 1, day));
  return dt.getUTCFullYear() === year &&
    dt.getUTCMonth() === month - 1 &&
    dt.getUTCDate() === day;
}

function formatYmd(year: number, month: number, day: number): string {
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

/**
 * Normalizes an NHTSA date string to YYYY-MM-DD for Postgres timestamptz, or null.
 *
 * Slash dates with both parts <= 12 are treated as ambiguous and return null.
 */
export function normalizeNhtsaDateForTimestamptz(
  raw: string | null | undefined,
): string | null {
  const text = raw?.trim();
  if (!text) return null;

  const isoPrefix = /^(\d{4})-(\d{2})-(\d{2})/.exec(text);
  if (isoPrefix) {
    const year = Number(isoPrefix[1]);
    const month = Number(isoPrefix[2]);
    const day = Number(isoPrefix[3]);
    return isValidYmd(year, month, day) ? formatYmd(year, month, day) : null;
  }

  const slashMatch = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(text);
  if (slashMatch) {
    const first = Number(slashMatch[1]);
    const second = Number(slashMatch[2]);
    const year = Number(slashMatch[3]);
    let month: number;
    let day: number;

    if (first > 12 && second <= 12) {
      day = first;
      month = second;
    } else if (second > 12 && first <= 12) {
      month = first;
      day = second;
    } else {
      return null;
    }

    return isValidYmd(year, month, day) ? formatYmd(year, month, day) : null;
  }

  const parsedMs = Date.parse(text);
  if (!Number.isFinite(parsedMs)) return null;
  const parsed = new Date(parsedMs);
  const year = parsed.getUTCFullYear();
  const month = parsed.getUTCMonth() + 1;
  const day = parsed.getUTCDate();
  return isValidYmd(year, month, day) ? formatYmd(year, month, day) : null;
}

/**
 * Builds the official NHTSA recallsByVehicle URL with encoded query parameters.
 */
export function buildNhtsaRecallsByVehicleUrl(
  make: string,
  model: string,
  modelYear: number,
): string {
  const params = new URLSearchParams({
    make,
    model,
    modelYear: String(modelYear),
  });
  return `${NHTSA_RECALLS_BASE}?${params.toString()}`;
}

/**
 * Maps one NHTSA recall row to a buyer-safe campaign object (allowlisted keys only).
 */
export function mapNhtsaRecallRow(
  row: Record<string, unknown>,
): RecallCampaignSummary {
  return {
    campaign_number: trimOrNull(
      row.NHTSACampaignNumber ?? row.nhtsaCampaignNumber,
    ),
    manufacturer: trimOrNull(row.Manufacturer ?? row.manufacturer),
    component: trimOrNull(row.Component ?? row.component),
    summary: trimOrNull(row.Summary ?? row.summary),
    consequence: trimOrNull(row.Consequence ?? row.consequence),
    remedy: trimOrNull(row.Remedy ?? row.remedy),
    notes: trimOrNull(row.Notes ?? row.notes),
    report_received_date: trimOrNull(
      row.ReportReceivedDate ?? row.reportReceivedDate,
    ),
    nhtsa_action_number: trimOrNull(
      row.NHTSAActionNumber ?? row.nhtsaActionNumber,
    ),
    park_it: parseBoolean(row.parkIt ?? row.park_it),
    park_outside: parseBoolean(row.parkOutSide ?? row.park_outside),
    over_the_air_update: parseBoolean(
      row.overTheAirUpdate ?? row.over_the_air_update,
    ),
    model_year: parseModelYear(row.ModelYear ?? row.modelYear),
    make: trimOrNull(row.Make ?? row.make),
    model: trimOrNull(row.Model ?? row.model),
  };
}

/**
 * Ensures a campaign object contains only buyer-allowlisted keys.
 */
export function pickAllowlistedCampaignFields(
  campaign: RecallCampaignSummary,
): RecallCampaignSummary {
  const out: RecallCampaignSummary = {};
  for (const key of ALLOWLISTED_CAMPAIGN_KEYS) {
    const value = campaign[key];
    if (value === null || value === undefined) continue;
    if (typeof value === "string" && value.trim().length === 0) continue;
    out[key] = value;
  }
  return out;
}

function campaignHasDisplayableField(campaign: RecallCampaignSummary): boolean {
  return ALLOWLISTED_CAMPAIGN_KEYS.some((key) => {
    const value = campaign[key];
    if (value === null || value === undefined) return false;
    if (typeof value === "string") return value.trim().length > 0;
    return true;
  });
}

function latestReportReceivedDate(
  campaigns: RecallCampaignSummary[],
): string | null {
  let latest: string | null = null;
  let latestMs = -1;

  for (const campaign of campaigns) {
    const normalized = normalizeNhtsaDateForTimestamptz(
      campaign.report_received_date,
    );
    if (!normalized) continue;

    const ms = Date.parse(`${normalized}T00:00:00Z`);
    if (!Number.isFinite(ms)) continue;

    if (latest === null || ms > latestMs) {
      latest = normalized;
      latestMs = ms;
    }
  }

  return latest;
}

/**
 * Parses NHTSA recallsByVehicle JSON into buyer-safe campaigns or structured errors.
 */
export function parseNhtsaRecallsResponse(
  payload: unknown,
): {
  ok: true;
  campaigns: RecallCampaignSummary[];
} | {
  ok: false;
  code: string;
  safeMessage: string;
  retryable: boolean;
} {
  if (payload === null || typeof payload !== "object") {
    return {
      ok: false,
      code: "nhtsa_malformed_response",
      safeMessage: "nhtsa_malformed_response",
      retryable: false,
    };
  }

  const body = payload as Record<string, unknown>;
  const results = body.Results ?? body.results;
  if (!Array.isArray(results)) {
    return {
      ok: false,
      code: "nhtsa_malformed_response",
      safeMessage: "nhtsa_malformed_response",
      retryable: false,
    };
  }

  const campaigns: RecallCampaignSummary[] = [];
  for (const item of results) {
    if (item === null || typeof item !== "object") continue;
    const mapped = pickAllowlistedCampaignFields(
      mapNhtsaRecallRow(item as Record<string, unknown>),
    );
    if (campaignHasDisplayableField(mapped)) {
      campaigns.push(mapped);
    }
  }

  return { ok: true, campaigns };
}

export function buildRecallNormalizedSummary(
  campaigns: RecallCampaignSummary[],
  matchQuality: string,
): RecallNormalizedSummary {
  return {
    campaigns,
    campaign_count: campaigns.length,
    market: "US",
    match_quality: matchQuality,
  };
}

export function buildRecallNoDataResult(
  matchQuality: string = "no_match",
): RecallProviderResult {
  return {
    ok: true,
    status: "no_data",
    normalizedSummary: buildRecallNormalizedSummary([], matchQuality),
    limitationCodes: [
      ...DEFAULT_RECALL_LIMITATION_CODES,
      "source_data_unavailable",
    ],
    matchQuality,
    sourceLabel: NHTSA_RECALLS_SOURCE_LABEL,
    sourceUpdatedAt: null,
    sourceMetadata: {
      providerId: "nhtsa_recalls",
      providerVersion: NHTSA_RECALLS_PROVIDER_VERSION,
      noData: true,
    },
  };
}

export function buildRecallSuccessResult(
  campaigns: RecallCampaignSummary[],
  matchQuality: string = "exact_make_model_year",
): RecallProviderResult {
  const status = campaigns.length > 0 ? "succeeded" : "no_data";
  return {
    ok: true,
    status,
    normalizedSummary: buildRecallNormalizedSummary(campaigns, matchQuality),
    limitationCodes: [...DEFAULT_RECALL_LIMITATION_CODES],
    matchQuality,
    sourceLabel: NHTSA_RECALLS_SOURCE_LABEL,
    sourceUpdatedAt: latestReportReceivedDate(campaigns),
    sourceMetadata: {
      providerId: "nhtsa_recalls",
      providerVersion: NHTSA_RECALLS_PROVIDER_VERSION,
      resultCount: campaigns.length,
    },
  };
}

export function buildRecallPartialResult(
  campaigns: RecallCampaignSummary[],
): RecallProviderResult {
  return {
    ok: true,
    status: "partial",
    normalizedSummary: buildRecallNormalizedSummary(
      campaigns,
      "make_model_year_multiple_campaigns",
    ),
    limitationCodes: [
      ...DEFAULT_RECALL_LIMITATION_CODES,
      "multiple_campaigns_listed",
    ],
    matchQuality: "make_model_year_multiple_campaigns",
    sourceLabel: NHTSA_RECALLS_SOURCE_LABEL,
    sourceUpdatedAt: latestReportReceivedDate(campaigns),
    sourceMetadata: {
      providerId: "nhtsa_recalls",
      providerVersion: NHTSA_RECALLS_PROVIDER_VERSION,
      resultCount: campaigns.length,
      partial: true,
    },
  };
}
