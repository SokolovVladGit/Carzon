/**
 * Cache-first VIN resolve. Suggestions only — no listing writes.
 * Durable per-user rate limiting is not implemented (SQL out of scope).
 */

import { parseResolverVin, sha256HexUtf8 } from "./vin.ts";
import {
  NHTSA_PROVIDER_ID,
  NHTSA_PROVIDER_VERSION,
  SAFE_NHTSA_WARNINGS,
  type NhtsaDecodeResult,
  type ResolverNormalizedFields,
} from "./nhtsa.ts";

export const CACHE_TTL_DAYS = 30;
export const CACHE_SCHEMA_VERSION = 1;

export type Resolution = "resolved" | "partial" | "no_data";

export type PublicVehicleSuggestion = {
  make: string | null;
  model: string | null;
  year: number | null;
  trim: string | null;
  series: string | null;
  bodyType: string | null;
  fuelType: string | null;
  engine: string | null;
  transmission: string | null;
  driveType: string | null;
  displacement: string | null;
  cylinders: string | null;
};

export type PublicResolveSuccess = {
  ok: true;
  resolution: Resolution;
  vehicle: PublicVehicleSuggestion;
  completeness: number;
  warnings: string[];
};

export type ResolveFailureCode =
  | "invalid_vin"
  | "upstream_timeout"
  | "upstream_unavailable"
  | "internal_error";

export type ResolveFailure = {
  ok: false;
  error: ResolveFailureCode;
};

export type ResolveOutcome = PublicResolveSuccess | ResolveFailure;

export type CacheReadRow = {
  decode_status: string | null;
  ttl_until: string | null;
  normalized_data: Record<string, unknown> | null;
};

export type CacheWriteRow = {
  vin_hash: string;
  schema_version: number;
  decode_status: "decoded";
  provider_id: string;
  provider_version: string;
  normalized_data: ResolverNormalizedFields;
  source_metadata: {
    providerId: string;
    providerVersion: string;
    latencyMs: number;
  };
  fetched_at: string;
  ttl_until: string;
  last_error: null;
};

export type VinDecodeCachePort = {
  readByHash(vinHash: string): Promise<CacheReadRow | null>;
  upsertDecoded(row: CacheWriteRow): Promise<void>;
};

export type ResolveVehiclePorts = {
  now: () => Date;
  cache: VinDecodeCachePort;
  decodeNhtsa: (vinNormalized: string) => Promise<NhtsaDecodeResult>;
  onCacheHit?: () => void;
};

const IDENTITY_KEYS: Array<keyof PublicVehicleSuggestion> = [
  "make",
  "model",
  "year",
  "trim",
  "series",
];

export function classifyResolution(
  vehicle: PublicVehicleSuggestion,
): Resolution {
  if (vehicle.make && vehicle.model && vehicle.year != null) {
    return "resolved";
  }
  const hasIdentity = IDENTITY_KEYS.some((key) => {
    const value = vehicle[key];
    return value != null && value !== "";
  });
  return hasIdentity ? "partial" : "no_data";
}

export function filterSafeWarnings(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  const allowed = new Set<string>(SAFE_NHTSA_WARNINGS);
  const out: string[] = [];
  for (const item of raw) {
    if (typeof item !== "string") continue;
    if (!allowed.has(item)) continue;
    if (!out.includes(item)) out.push(item);
  }
  return out;
}

function textOrNull(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value !== "string") return null;
  const t = value.trim();
  return t.length === 0 ? null : t;
}

function yearOrNull(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  if (value < 1900 || value > 2100) return null;
  return value;
}

function completenessOrZero(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

export function publicVehicleFromNormalized(
  data: Record<string, unknown> | ResolverNormalizedFields,
): PublicVehicleSuggestion {
  return {
    make: textOrNull(data.make),
    model: textOrNull(data.model),
    year: yearOrNull(data.year),
    trim: textOrNull(data.trim),
    series: textOrNull(data.series),
    bodyType: textOrNull(data.bodyType),
    fuelType: textOrNull(data.fuelType),
    engine: textOrNull(data.engine),
    transmission: textOrNull(data.transmission),
    driveType: textOrNull(data.driveType),
    displacement: textOrNull(data.displacement),
    cylinders: textOrNull(data.cylinders),
  };
}

export function buildPublicSuccess(
  data: Record<string, unknown> | ResolverNormalizedFields,
): PublicResolveSuccess {
  const vehicle = publicVehicleFromNormalized(data);
  return {
    ok: true,
    resolution: classifyResolution(vehicle),
    vehicle,
    completeness: completenessOrZero(
      (data as { rawCompletenessScore?: unknown }).rawCompletenessScore,
    ),
    warnings: filterSafeWarnings(
      (data as { warnings?: unknown }).warnings,
    ),
  };
}

export function isReusableCacheRow(
  row: CacheReadRow | null,
  now: Date,
): row is CacheReadRow & { normalized_data: Record<string, unknown> } {
  if (!row) return false;
  if (row.decode_status !== "decoded") return false;
  if (row.normalized_data == null || typeof row.normalized_data !== "object") {
    return false;
  }
  if (!row.ttl_until) return false;
  const ttl = Date.parse(row.ttl_until);
  if (!Number.isFinite(ttl) || ttl <= now.getTime()) return false;
  return true;
}

export function ttlUntilIso(fetchedAt: Date): string {
  return new Date(
    fetchedAt.getTime() + CACHE_TTL_DAYS * 24 * 60 * 60 * 1000,
  ).toISOString();
}

export function cacheWriteFromNormalized(input: {
  vinHash: string;
  normalized: ResolverNormalizedFields;
  latencyMs: number;
  fetchedAt: Date;
}): CacheWriteRow {
  return {
    vin_hash: input.vinHash,
    schema_version: CACHE_SCHEMA_VERSION,
    decode_status: "decoded",
    provider_id: NHTSA_PROVIDER_ID,
    provider_version: NHTSA_PROVIDER_VERSION,
    normalized_data: input.normalized,
    source_metadata: {
      providerId: NHTSA_PROVIDER_ID,
      providerVersion: NHTSA_PROVIDER_VERSION,
      latencyMs: input.latencyMs,
    },
    fetched_at: input.fetchedAt.toISOString(),
    ttl_until: ttlUntilIso(input.fetchedAt),
    last_error: null,
  };
}

export function assertPublicAllowList(
  body: PublicResolveSuccess,
): PublicResolveSuccess {
  const src = body.vehicle;
  const vehicle: PublicVehicleSuggestion = {
    make: src.make,
    model: src.model,
    year: src.year,
    trim: src.trim,
    series: src.series,
    bodyType: src.bodyType,
    fuelType: src.fuelType,
    engine: src.engine,
    transmission: src.transmission,
    driveType: src.driveType,
    displacement: src.displacement,
    cylinders: src.cylinders,
  };
  return {
    ok: true,
    resolution: body.resolution,
    vehicle,
    completeness: body.completeness,
    warnings: [...body.warnings],
  };
}

export async function resolveVehicleFromVin(
  rawVin: string,
  ports: ResolveVehiclePorts,
): Promise<ResolveOutcome> {
  const parsed = parseResolverVin(rawVin);
  if (!parsed.ok) return parsed;

  const vinHash = await sha256HexUtf8(parsed.normalized);
  const now = ports.now();

  let cached: CacheReadRow | null;
  try {
    cached = await ports.cache.readByHash(vinHash);
  } catch {
    cached = null;
  }

  if (isReusableCacheRow(cached, now)) {
    ports.onCacheHit?.();
    return assertPublicAllowList(buildPublicSuccess(cached.normalized_data));
  }

  const decoded = await ports.decodeNhtsa(parsed.normalized);
  if (!decoded.ok) {
    return {
      ok: false,
      error: decoded.kind === "timeout"
        ? "upstream_timeout"
        : "upstream_unavailable",
    };
  }

  const write = cacheWriteFromNormalized({
    vinHash,
    normalized: decoded.normalized,
    latencyMs: decoded.latencyMs,
    fetchedAt: now,
  });

  try {
    await ports.cache.upsertDecoded(write);
  } catch {
    // Decode already succeeded; cache persist must not drop the suggestion.
  }

  return assertPublicAllowList(buildPublicSuccess(decoded.normalized));
}
