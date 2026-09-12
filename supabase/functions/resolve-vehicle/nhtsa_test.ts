import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { mapNhtsaVinValuesRow } from "../process-vin-decode-jobs/providers/nhtsa_provider.ts";
import {
  decodeNhtsaVinValues,
  mapResolverNhtsaVinValuesRow,
  type NhtsaHttpClient,
  type NhtsaVinValuesRow,
} from "./nhtsa.ts";

const FULL_ROW: NhtsaVinValuesRow = {
  Make: "HONDA",
  Model: "ACCORD",
  ModelYear: "2003",
  BodyClass: "Sedan/Saloon",
  FuelTypePrimary: "Gasoline",
  EngineConfiguration: "V-Shaped",
  EngineModel: "J30A4",
  DisplacementL: "3.0",
  TransmissionStyle: "Automatic",
  TransmissionSpeeds: "5",
  Manufacturer: "HONDA MOTOR CO., LTD",
  PlantCountry: "UNITED STATES (USA)",
  PlantCity: "MARYSVILLE",
  PlantCompany: "Marysville Auto Plant",
  VehicleType: "PASSENGER CAR",
  Trim: "EX",
  Series: "CM5",
  DriveType: "4x2",
  Doors: "4",
  EngineCylinders: "6",
  GVWR: "Class 1C: 4,001 - 5,000 lb",
  ErrorCode: "0",
  ErrorText: "",
};

const EMPTY_ROW: NhtsaVinValuesRow = {
  Make: "",
  Model: "",
  ModelYear: "",
  ErrorCode: "11",
  ErrorText: "Invalid characters",
};

Deno.test("resolver mapper fills shared identity and spec strings", () => {
  const { normalized } = mapResolverNhtsaVinValuesRow(FULL_ROW);
  assertEquals(normalized.make, "HONDA");
  assertEquals(normalized.model, "ACCORD");
  assertEquals(normalized.year, 2003);
  assertEquals(normalized.trim, "EX");
  assertEquals(normalized.series, "CM5");
  assertEquals(normalized.bodyType, "Sedan/Saloon");
  assertEquals(normalized.fuelType, "Gasoline");
  assertEquals(normalized.engine, "V-Shaped J30A4 3.0");
  assertEquals(normalized.transmission, "Automatic (5)");
  assertEquals(normalized.driveType, "4x2");
  assertEquals(normalized.displacement, "3 L");
  assertEquals(normalized.cylinders, "6");
  assertEquals(normalized.market, "US_catalog_bias");
  assertEquals(normalized.warnings, []);
});

Deno.test("resolver mapper keeps decode errors internal on the normalized object", () => {
  const { normalized } = mapResolverNhtsaVinValuesRow(EMPTY_ROW);
  assertEquals(normalized.decodeErrorCode, "11");
  assertEquals(normalized.decodeErrorText, "Invalid characters");
  assertEquals(normalized.warnings.includes("nhtsa_catalog_decode_caution"), true);
  assertEquals(normalized.warnings.includes("nhtsa_partial_or_empty_decode"), true);
});

Deno.test("parity: shared fields match process-vin-decode-jobs mapper", () => {
  const resolver = mapResolverNhtsaVinValuesRow(FULL_ROW).normalized;
  const worker = mapNhtsaVinValuesRow(FULL_ROW).normalized;
  const keys = [
    "make",
    "model",
    "year",
    "bodyType",
    "fuelType",
    "engine",
    "transmission",
    "trim",
    "series",
    "driveType",
    "displacement",
    "manufacturer",
    "plantCountry",
    "plantCity",
    "plantCompany",
    "vehicleType",
    "market",
    "rawCompletenessScore",
  ] as const;
  for (const key of keys) {
    assertEquals(resolver[key], worker[key], key);
  }
  assertEquals(resolver.warnings, worker.warnings);
});

Deno.test("decodeNhtsaVinValues maps HTTP 200 Results row", async () => {
  const http: NhtsaHttpClient = {
    fetchVinValues: () =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ Results: [FULL_ROW] }),
      }),
  };
  const result = await decodeNhtsaVinValues("1HGBH41JXMN109186", http);
  assertEquals(result.ok, true);
  if (!result.ok) return;
  assertEquals(result.normalized.make, "HONDA");
  assertEquals(result.normalized.model, "ACCORD");
  assertEquals(result.normalized.year, 2003);
});

Deno.test("decodeNhtsaVinValues treats empty Results as empty normalized success", async () => {
  const http: NhtsaHttpClient = {
    fetchVinValues: () =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ Results: [] }),
      }),
  };
  const result = await decodeNhtsaVinValues("1HGBH41JXMN109186", http);
  assertEquals(result.ok, true);
  if (!result.ok) return;
  assertEquals(result.normalized.make, null);
  assertEquals(result.normalized.model, null);
  assertEquals(result.normalized.year, null);
});

Deno.test("decodeNhtsaVinValues non-2xx is unavailable", async () => {
  const http: NhtsaHttpClient = {
    fetchVinValues: () =>
      Promise.resolve({
        ok: false,
        status: 503,
        json: () => Promise.resolve({}),
      }),
  };
  const result = await decodeNhtsaVinValues("1HGBH41JXMN109186", http);
  assertEquals(result, { ok: false, kind: "unavailable" });
});

Deno.test("decodeNhtsaVinValues timeout is timeout", async () => {
  const http: NhtsaHttpClient = {
    fetchVinValues: (_vin, signal) =>
      new Promise((_, reject) => {
        signal.addEventListener("abort", () => {
          const err = new Error("aborted");
          err.name = "AbortError";
          reject(err);
        });
      }),
  };
  const result = await decodeNhtsaVinValues("1HGBH41JXMN109186", http, 10);
  assertEquals(result, { ok: false, kind: "timeout" });
});

Deno.test("decodeNhtsaVinValues invalid JSON is unavailable", async () => {
  const http: NhtsaHttpClient = {
    fetchVinValues: () =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.reject(new Error("bad json")),
      }),
  };
  const result = await decodeNhtsaVinValues("1HGBH41JXMN109186", http);
  assertEquals(result, { ok: false, kind: "unavailable" });
});
