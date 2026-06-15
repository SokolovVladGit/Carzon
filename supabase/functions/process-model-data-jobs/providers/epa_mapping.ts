/**
 * Pure EPA / FuelEconomy.gov XML mapping helpers (no HTTP).
 * Exported for static verification and deterministic unit behavior.
 */

import type { EpaCompatibleSummary } from "./types.ts";
import { DEFAULT_EPA_LIMITATION_CODES } from "./types.ts";

export const EPA_PROVIDER_VERSION = "fueleconomy_ws_v1";
export const EPA_SOURCE_LABEL = "EPA · FuelEconomy.gov";
export const EPA_BASE_URL = "https://fueleconomy.gov/ws/rest/vehicle";

const MPG_TO_L_PER_100KM_FACTOR = 235.214;
const G_PER_MILE_TO_G_PER_KM_FACTOR = 0.621371;

export function mpgToLPer100km(mpg: number | null | undefined): number | null {
  if (mpg == null || !Number.isFinite(mpg) || mpg <= 0) return null;
  return Math.round((MPG_TO_L_PER_100KM_FACTOR / mpg) * 10) / 10;
}

export function co2GPerMileToGPerKm(
  gPerMile: number | null | undefined,
): number | null {
  if (gPerMile == null || !Number.isFinite(gPerMile) || gPerMile < 0) {
    return null;
  }
  return Math.round(gPerMile * G_PER_MILE_TO_G_PER_KM_FACTOR);
}

export function readXmlTagText(xml: string, tag: string): string | null {
  const re = new RegExp(`<${tag}>([^<]*)</${tag}>`, "i");
  const match = xml.match(re);
  if (!match) return null;
  const text = match[1]?.trim();
  return text && text.length > 0 ? text : null;
}

export function parsePositiveNumber(value: string | null | undefined): number | null {
  if (value == null) return null;
  const trimmed = value.trim();
  if (trimmed.length === 0 || trimmed === "-1" || trimmed === "0") return null;
  const n = Number.parseFloat(trimmed);
  if (!Number.isFinite(n) || n <= 0) return null;
  return n;
}

export function parseMenuOptionVehicleIds(xml: string): string[] {
  const ids: string[] = [];
  // EPA menu XML uses <menuItem><text>…</text><value>id</value></menuItem>.
  const re = /<menuItem>[\s\S]*?<value>([^<]+)<\/value>/gi;
  let match: RegExpExecArray | null;
  while ((match = re.exec(xml)) !== null) {
    const id = match[1]?.trim();
    if (id && id.length > 0 && !ids.includes(id)) ids.push(id);
  }
  return ids;
}

export type ParsedEpaVehicleDetail = {
  providerVehicleId: string | null;
  fuelType: string | null;
  cityMpg: number | null;
  highwayMpg: number | null;
  combinedMpg: number | null;
  co2GPerMile: number | null;
  vehicleClass: string | null;
  drive: string | null;
  transmission: string | null;
  engineDescriptor: string | null;
};

export function parseEpaVehicleDetailXml(xml: string): ParsedEpaVehicleDetail {
  const providerVehicleId = readXmlTagText(xml, "id");
  const cityMpg = parsePositiveNumber(readXmlTagText(xml, "city08"));
  const highwayMpg = parsePositiveNumber(readXmlTagText(xml, "highway08"));
  const combinedMpg = parsePositiveNumber(readXmlTagText(xml, "comb08"));
  const co2GPerMile = parsePositiveNumber(readXmlTagText(xml, "co2TailpipeGpm"));

  const cylinders = readXmlTagText(xml, "cylinders");
  const displacement = readXmlTagText(xml, "displ");
  const engineParts = [displacement, cylinders ? `${cylinders} cyl` : null]
    .filter((x): x is string => x != null && x.length > 0);
  const engineDescriptor = engineParts.length > 0 ? engineParts.join(" ") : null;

  return {
    providerVehicleId,
    fuelType: readXmlTagText(xml, "fuelType"),
    cityMpg,
    highwayMpg,
    combinedMpg,
    co2GPerMile,
    vehicleClass: readXmlTagText(xml, "VClass"),
    drive: readXmlTagText(xml, "drive"),
    transmission: readXmlTagText(xml, "trany"),
    engineDescriptor,
  };
}

function averageNullable(values: Array<number | null>): number | null {
  const nums = values.filter((v): v is number => v != null);
  if (nums.length === 0) return null;
  const sum = nums.reduce((a, b) => a + b, 0);
  return Math.round((sum / nums.length) * 10) / 10;
}

function averageNullableInt(values: Array<number | null>): number | null {
  const nums = values.filter((v): v is number => v != null);
  if (nums.length === 0) return null;
  const sum = nums.reduce((a, b) => a + b, 0);
  return Math.round(sum / nums.length);
}

export function buildEpaSummaryFromVehicleDetail(
  detail: ParsedEpaVehicleDetail,
  matchQuality: string,
): EpaCompatibleSummary {
  const cityMpg = detail.cityMpg;
  const highwayMpg = detail.highwayMpg;
  const combinedMpg = detail.combinedMpg;

  return {
    provider_vehicle_id: detail.providerVehicleId,
    fuel_type: detail.fuelType,
    city_mpg: cityMpg,
    highway_mpg: highwayMpg,
    combined_mpg: combinedMpg,
    city_l_per_100km: mpgToLPer100km(cityMpg),
    highway_l_per_100km: mpgToLPer100km(highwayMpg),
    combined_l_per_100km: mpgToLPer100km(combinedMpg),
    co2_g_per_mile: detail.co2GPerMile,
    co2_g_per_km: co2GPerMileToGPerKm(detail.co2GPerMile),
    vehicle_class: detail.vehicleClass,
    drive: detail.drive,
    transmission: detail.transmission,
    engine_descriptor: detail.engineDescriptor,
    market: "US",
    match_quality: matchQuality,
  };
}

export function aggregateEpaVehicleDetails(
  details: ParsedEpaVehicleDetail[],
  optionVehicleIds: string[],
): EpaCompatibleSummary {
  const cityMpg = averageNullable(details.map((d) => d.cityMpg));
  const highwayMpg = averageNullable(details.map((d) => d.highwayMpg));
  const combinedMpg = averageNullable(details.map((d) => d.combinedMpg));
  const co2GPerMile = averageNullableInt(details.map((d) => d.co2GPerMile));

  const fuelTypes = [...new Set(
    details.map((d) => d.fuelType).filter((x): x is string => x != null),
  )];
  const vehicleClasses = [...new Set(
    details.map((d) => d.vehicleClass).filter((x): x is string => x != null),
  )];

  return {
    provider_vehicle_id: null,
    fuel_type: fuelTypes.length === 1 ? fuelTypes[0] : null,
    city_mpg: cityMpg,
    highway_mpg: highwayMpg,
    combined_mpg: combinedMpg,
    city_l_per_100km: mpgToLPer100km(cityMpg),
    highway_l_per_100km: mpgToLPer100km(highwayMpg),
    combined_l_per_100km: mpgToLPer100km(combinedMpg),
    co2_g_per_mile: co2GPerMile,
    co2_g_per_km: co2GPerMileToGPerKm(co2GPerMile),
    vehicle_class: vehicleClasses.length === 1 ? vehicleClasses[0] : null,
    market: "US",
    match_quality: "make_model_year_multiple_options",
  };
}

export function epaSummaryHasCoreFields(summary: EpaCompatibleSummary): boolean {
  return summary.combined_mpg != null ||
    summary.city_mpg != null ||
    summary.highway_mpg != null ||
    summary.co2_g_per_mile != null;
}

export function buildEpaLimitationCodes(
  base: readonly string[],
  extra: string[] = [],
): string[] {
  const out = [...base];
  for (const code of extra) {
    if (!out.includes(code)) out.push(code);
  }
  return out;
}

export function defaultEpaSuccessLimitationCodes(extra: string[] = []): string[] {
  return buildEpaLimitationCodes([...DEFAULT_EPA_LIMITATION_CODES], extra);
}

export function buildEpaNoDataResult(
  matchQuality: string,
  extraLimitations: string[] = ["source_data_unavailable"],
) {
  return {
    status: "no_data" as const,
    confidence: "unknown",
    normalizedSummary: {} as EpaCompatibleSummary,
    limitationCodes: defaultEpaSuccessLimitationCodes(extraLimitations),
    matchQuality,
  };
}

export function encodeEpaQueryParam(value: string): string {
  return encodeURIComponent(value.trim());
}

export function buildEpaMenuOptionsUrl(
  year: number,
  make: string,
  model: string,
): string {
  return `${EPA_BASE_URL}/menu/options?year=${year}&make=${encodeEpaQueryParam(make)}&model=${encodeEpaQueryParam(model)}`;
}

export function buildEpaVehicleDetailUrl(vehicleId: string): string {
  return `${EPA_BASE_URL}/${encodeURIComponent(vehicleId.trim())}`;
}
