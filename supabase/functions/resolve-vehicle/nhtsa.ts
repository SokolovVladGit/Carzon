/**
 * NHTSA vPIC adapter for pre-listing resolve-vehicle.
 * Mapping stays compatible with process-vin-decode-jobs/providers/nhtsa_provider.ts.
 * Does not import or modify the worker. One fetch, no retries.
 */

export const NHTSA_TIMEOUT_MS = 15_000;
export const NHTSA_PROVIDER_ID = "nhtsa_vpic";
export const NHTSA_PROVIDER_VERSION = "decode-vin-values-v2";

const VPIC_BASE = "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues";

export const SAFE_NHTSA_WARNINGS = [
  "nhtsa_partial_or_empty_decode",
  "nhtsa_catalog_decode_caution",
] as const;

export type NhtsaVinValuesRow = Record<string, string | undefined>;

export type ResolverNormalizedFields = {
  make: string | null;
  model: string | null;
  year: number | null;
  bodyType: string | null;
  fuelType: string | null;
  engine: string | null;
  transmission: string | null;
  manufacturer: string | null;
  plantCountry: string | null;
  plantCity: string | null;
  plantCompany: string | null;
  vehicleType: string | null;
  trim: string | null;
  series: string | null;
  driveType: string | null;
  doors: string | null;
  displacement: string | null;
  cylinders: string | null;
  grossVehicleWeightRating: string | null;
  market: string | null;
  rawCompletenessScore: number;
  warnings: string[];
  decodeErrorCode: string | null;
  decodeErrorText: string | null;
};

export type NhtsaHttpClient = {
  fetchVinValues(
    vinNormalized: string,
    signal: AbortSignal,
  ): Promise<{ ok: boolean; status: number; json: () => Promise<unknown> }>;
};

export type NhtsaDecodeSuccess = {
  ok: true;
  normalized: ResolverNormalizedFields;
  latencyMs: number;
};

export type NhtsaDecodeFailure = {
  ok: false;
  kind: "timeout" | "unavailable";
};

export type NhtsaDecodeResult = NhtsaDecodeSuccess | NhtsaDecodeFailure;

function trimOrNull(v: unknown): string | null {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return s.length === 0 ? null : s;
}

function parseYear(v: unknown): number | null {
  const s = trimOrNull(v);
  if (!s) return null;
  const n = Number.parseInt(s, 10);
  if (!Number.isFinite(n) || n < 1900 || n > 2100) return null;
  return n;
}

function parsePositiveIntString(v: unknown): string | null {
  const s = trimOrNull(v);
  if (!s) return null;
  const n = Number.parseInt(s, 10);
  if (!Number.isFinite(n) || n <= 0) return s;
  return `${n}`;
}

function formatDisplacementLiters(v: unknown): string | null {
  const s = trimOrNull(v);
  if (!s) return null;
  const n = Number.parseFloat(s);
  if (!Number.isFinite(n) || n <= 0) return s;
  return `${n} L`;
}

function buildEngine(row: NhtsaVinValuesRow): string | null {
  const parts = [
    trimOrNull(row["EngineConfiguration"]),
    trimOrNull(row["EngineModel"]),
    trimOrNull(row["DisplacementL"]),
  ].filter((x): x is string => x !== null);
  if (parts.length === 0) return null;
  return parts.join(" ");
}

function buildTransmission(row: NhtsaVinValuesRow): string | null {
  const style = trimOrNull(row["TransmissionStyle"]);
  const speeds = trimOrNull(row["TransmissionSpeeds"]);
  if (style && speeds) return `${style} (${speeds})`;
  return style ?? speeds;
}

function decodeIssueWarnings(row: NhtsaVinValuesRow): string[] {
  const code = trimOrNull(row["ErrorCode"]);
  const text = trimOrNull(row["ErrorText"]);
  if (!code && !text) return [];
  if (code === "0" || code?.toLowerCase() === "success") return [];
  return ["nhtsa_catalog_decode_caution"];
}

/** Maps DecodeVinValues row. Does not keep the raw row. */
export function mapResolverNhtsaVinValuesRow(row: NhtsaVinValuesRow): {
  normalized: ResolverNormalizedFields;
} {
  const make = trimOrNull(row["Make"]);
  const model = trimOrNull(row["Model"]);
  const year = parseYear(row["ModelYear"]);
  const bodyType = trimOrNull(row["BodyClass"]);
  const fuelType = trimOrNull(row["FuelTypePrimary"]);
  const engine = buildEngine(row);
  const transmission = buildTransmission(row);

  const issueWarnings = decodeIssueWarnings(row);
  const warnings: string[] = [];
  if (!make && !model && year === null) {
    warnings.push("nhtsa_partial_or_empty_decode");
  }
  for (const w of issueWarnings) {
    if (!warnings.includes(w)) warnings.push(w);
  }

  const coreFilled = [
    make,
    model,
    year !== null ? "y" : null,
    bodyType,
    fuelType,
    engine,
    transmission,
  ].filter((x) => x !== null).length;

  const extendedFilled = [
    trimOrNull(row["Manufacturer"]),
    trimOrNull(row["VehicleType"]),
    trimOrNull(row["Trim"]),
    trimOrNull(row["DriveType"]),
    trimOrNull(row["PlantCountry"]),
  ].filter((x) => x !== null).length;

  const rawCompletenessScore = Math.min(
    1,
    (coreFilled + extendedFilled * 0.5) / 12,
  );

  return {
    normalized: {
      make,
      model,
      year,
      bodyType,
      fuelType,
      engine,
      transmission,
      manufacturer: trimOrNull(row["Manufacturer"]),
      plantCountry: trimOrNull(row["PlantCountry"]),
      plantCity: trimOrNull(row["PlantCity"]),
      plantCompany: trimOrNull(row["PlantCompany"]),
      vehicleType: trimOrNull(row["VehicleType"]),
      trim: trimOrNull(row["Trim"]),
      series: trimOrNull(row["Series"]),
      driveType: trimOrNull(row["DriveType"]),
      doors: parsePositiveIntString(row["Doors"]),
      displacement: formatDisplacementLiters(row["DisplacementL"]),
      cylinders: parsePositiveIntString(
        row["EngineCylinders"] ?? row["EngineNumberOfCylinders"],
      ),
      grossVehicleWeightRating: trimOrNull(row["GVWR"]),
      market: "US_catalog_bias",
      rawCompletenessScore,
      warnings,
      decodeErrorCode: trimOrNull(row["ErrorCode"]),
      decodeErrorText: trimOrNull(row["ErrorText"]),
    },
  };
}

export function createDefaultNhtsaHttpClient(): NhtsaHttpClient {
  return {
    async fetchVinValues(vinNormalized, signal) {
      const url = `${VPIC_BASE}/${encodeURIComponent(vinNormalized)}?format=json`;
      const res = await fetch(url, {
        method: "GET",
        signal,
        headers: { Accept: "application/json" },
      });
      return {
        ok: res.ok,
        status: res.status,
        json: () => res.json(),
      };
    },
  };
}

export async function decodeNhtsaVinValues(
  vinNormalized: string,
  http: NhtsaHttpClient = createDefaultNhtsaHttpClient(),
  timeoutMs: number = NHTSA_TIMEOUT_MS,
): Promise<NhtsaDecodeResult> {
  const started = performance.now();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await http.fetchVinValues(vinNormalized, controller.signal);
    const latencyMs = Math.round(performance.now() - started);

    if (!res.ok) {
      return { ok: false, kind: "unavailable" };
    }

    let body: unknown;
    try {
      body = await res.json();
    } catch {
      return { ok: false, kind: "unavailable" };
    }

    const row = (body as { Results?: NhtsaVinValuesRow[] }).Results?.[0];
    if (!row || typeof row !== "object") {
      return {
        ok: true,
        normalized: mapResolverNhtsaVinValuesRow({}).normalized,
        latencyMs,
      };
    }

    return {
      ok: true,
      normalized: mapResolverNhtsaVinValuesRow(row).normalized,
      latencyMs,
    };
  } catch (e) {
    const aborted = e instanceof Error && e.name === "AbortError";
    return { ok: false, kind: aborted ? "timeout" : "unavailable" };
  } finally {
    clearTimeout(timer);
  }
}
