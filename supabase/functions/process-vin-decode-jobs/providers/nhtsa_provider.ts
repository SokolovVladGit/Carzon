/**
 * NHTSA vPIC DecodeVinValues adapter (basic decode only; not EU/MD verification).
 */

import type {
  VinDecoderInput,
  VinDecoderNormalizedFields,
  VinDecoderProvider,
  VinDecoderResult,
} from "./types.ts";

const NHTSA_TIMEOUT_MS = 15_000;
const VPIC_BASE =
  "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues";

type NhtsaVinValuesRow = Record<string, string | undefined>;

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
  return '$n';
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

/** Maps a single DecodeVinValues row into Carzon normalized fields (no raw row stored). */
export function mapNhtsaVinValuesRow(row: NhtsaVinValuesRow): {
  normalized: VinDecoderNormalizedFields;
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

  const denom = 12;
  const rawCompletenessScore = Math.min(
    1,
    (coreFilled + extendedFilled * 0.5) / denom,
  );

  const normalized: VinDecoderNormalizedFields = {
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
  };

  return { normalized };
}

export class NhtsaVpicVinDecoderProvider implements VinDecoderProvider {
  readonly id = "nhtsa_vpic";

  async decode(input: VinDecoderInput): Promise<VinDecoderResult> {
    const started = performance.now();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), NHTSA_TIMEOUT_MS);
    try {
      const pathVin = encodeURIComponent(input.vinNormalized);
      const url = `${VPIC_BASE}/${pathVin}?format=json`;
      const res = await fetch(url, {
        method: "GET",
        signal: controller.signal,
        headers: { Accept: "application/json" },
      });

      const latencyMs = Math.round(performance.now() - started);

      if (!res.ok) {
        const retryable = res.status >= 500;
        return {
          ok: false,
          error: {
            code: "nhtsa_http_error",
            safeMessage: "nhtsa_http_error",
            retryable,
            httpStatus: res.status,
          },
        };
      }

      let body: unknown;
      try {
        body = await res.json();
      } catch {
        return {
          ok: false,
          error: {
            code: "nhtsa_invalid_json",
            safeMessage: "nhtsa_invalid_json",
            retryable: false,
          },
        };
      }

      const root = body as {
        Results?: NhtsaVinValuesRow[];
      };
      const row = root.Results?.[0];
      if (!row || typeof row !== "object") {
        return {
          ok: false,
          error: {
            code: "nhtsa_no_results",
            safeMessage: "nhtsa_no_results",
            retryable: false,
          },
        };
      }

      const { normalized } = mapNhtsaVinValuesRow(row);

      return {
        ok: true,
        normalized,
        metadata: {
          providerId: this.id,
          providerVersion: "decode-vin-values-v2",
          latencyMs,
        },
      };
    } catch (e) {
      const aborted = e instanceof Error && e.name === "AbortError";
      return {
        ok: false,
        error: {
          code: aborted ? "nhtsa_timeout" : "nhtsa_network_error",
          safeMessage: aborted ? "nhtsa_timeout" : "nhtsa_network_error",
          retryable: true,
        },
      };
    } finally {
      clearTimeout(timer);
    }
  }
}
