import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { sha256HexUtf8 } from "./vin.ts";
import {
  CACHE_TTL_DAYS,
  buildPublicSuccess,
  cacheWriteFromNormalized,
  classifyResolution,
  isReusableCacheRow,
  resolveVehicleFromVin,
  type CacheReadRow,
  type CacheWriteRow,
  type PublicVehicleSuggestion,
  type VinDecodeCachePort,
} from "./resolve.ts";
import type { NhtsaDecodeResult, ResolverNormalizedFields } from "./nhtsa.ts";

const SAMPLE = "1HGBH41JXMN109186";
const FIXED_NOW = new Date("2026-09-07T12:00:00.000Z");

function vehicle(partial: Partial<PublicVehicleSuggestion>): PublicVehicleSuggestion {
  return {
    make: null,
    model: null,
    year: null,
    trim: null,
    series: null,
    bodyType: null,
    fuelType: null,
    engine: null,
    transmission: null,
    driveType: null,
    displacement: null,
    cylinders: null,
    ...partial,
  };
}

function normalized(
  partial: Partial<ResolverNormalizedFields> = {},
): ResolverNormalizedFields {
  return {
    make: "HONDA",
    model: "ACCORD",
    year: 2003,
    bodyType: "Sedan/Saloon",
    fuelType: "Gasoline",
    engine: "V-Shaped J30A4 3.0",
    transmission: "Automatic (5)",
    manufacturer: "HONDA MOTOR CO., LTD",
    plantCountry: "UNITED STATES (USA)",
    plantCity: "MARYSVILLE",
    plantCompany: "Marysville Auto Plant",
    vehicleType: "PASSENGER CAR",
    trim: "EX",
    series: "CM5",
    driveType: "4x2",
    doors: "4",
    displacement: "3 L",
    cylinders: "6",
    grossVehicleWeightRating: "Class 1C",
    market: "US_catalog_bias",
    rawCompletenessScore: 0.8,
    warnings: [],
    decodeErrorCode: "0",
    decodeErrorText: null,
    ...partial,
  };
}

function memoryCache(seed?: CacheReadRow): VinDecodeCachePort & {
  writes: CacheWriteRow[];
  readCount: number;
} {
  const writes: CacheWriteRow[] = [];
  let readCount = 0;
  return {
    writes,
    get readCount() {
      return readCount;
    },
    async readByHash() {
      readCount += 1;
      return seed ?? null;
    },
    async upsertDecoded(row) {
      writes.push(row);
    },
  };
}

Deno.test("classification resolved requires make+model+year", () => {
  assertEquals(
    classifyResolution(vehicle({ make: "HONDA", model: "ACCORD", year: 2003 })),
    "resolved",
  );
});

Deno.test("classification partial when identity is incomplete", () => {
  assertEquals(
    classifyResolution(vehicle({ make: "HONDA" })),
    "partial",
  );
  assertEquals(
    classifyResolution(vehicle({ trim: "EX" })),
    "partial",
  );
});

Deno.test("classification no_data when no identity fields", () => {
  assertEquals(classifyResolution(vehicle({})), "no_data");
  assertEquals(
    classifyResolution(vehicle({ bodyType: "Sedan/Saloon", fuelType: "Gasoline" })),
    "no_data",
  );
});

Deno.test("public success allow-list strips internal fields", () => {
  const fat = {
    ...normalized(),
    vin: SAMPLE,
    vin_hash: "abc",
    source_metadata: { providerId: "nhtsa_vpic" },
    decodeErrorCode: "7",
    decodeErrorText: "secret",
    manufacturer: "HIDDEN",
    plantCountry: "US",
    listing_id: "nope",
  } as ResolverNormalizedFields & Record<string, unknown>;
  const body = buildPublicSuccess(fat);
  assertEquals(Object.keys(body).sort(), [
    "completeness",
    "ok",
    "resolution",
    "vehicle",
    "warnings",
  ]);
  assertEquals(Object.keys(body.vehicle).sort(), [
    "bodyType",
    "cylinders",
    "displacement",
    "driveType",
    "engine",
    "fuelType",
    "make",
    "model",
    "series",
    "transmission",
    "trim",
    "year",
  ]);
  const encoded = JSON.stringify(body);
  assertEquals(encoded.includes(SAMPLE), false);
  assertEquals(encoded.includes("vin_hash"), false);
  assertEquals(encoded.includes("source_metadata"), false);
  assertEquals(encoded.includes("decodeError"), false);
  assertEquals(encoded.includes("HIDDEN"), false);
  assertEquals(encoded.includes("listing_id"), false);
  assertEquals(body.resolution, "resolved");
});

Deno.test("reusable cache requires decoded + future ttl + normalized_data", () => {
  const future = "2026-10-07T12:00:00.000Z";
  assertEquals(
    isReusableCacheRow({
      decode_status: "decoded",
      ttl_until: future,
      normalized_data: { make: "HONDA" },
    }, FIXED_NOW),
    true,
  );
  assertEquals(
    isReusableCacheRow({
      decode_status: "failed",
      ttl_until: future,
      normalized_data: { make: "HONDA" },
    }, FIXED_NOW),
    false,
  );
  assertEquals(
    isReusableCacheRow({
      decode_status: "decoded",
      ttl_until: "2026-08-01T00:00:00.000Z",
      normalized_data: { make: "HONDA" },
    }, FIXED_NOW),
    false,
  );
  assertEquals(
    isReusableCacheRow({
      decode_status: "decoded",
      ttl_until: future,
      normalized_data: null,
    }, FIXED_NOW),
    false,
  );
});

Deno.test("cache-hit avoids provider and returns public shape", async () => {
  const cache = memoryCache({
    decode_status: "decoded",
    ttl_until: "2026-10-07T12:00:00.000Z",
    normalized_data: normalized() as unknown as Record<string, unknown>,
  });
  let providerCalls = 0;
  const outcome = await resolveVehicleFromVin(SAMPLE, {
    now: () => FIXED_NOW,
    cache,
    decodeNhtsa: () => {
      providerCalls += 1;
      return Promise.resolve({ ok: false, kind: "unavailable" });
    },
  });
  assertEquals(providerCalls, 0);
  assertEquals(cache.writes.length, 0);
  assertEquals(outcome.ok, true);
  if (!outcome.ok) return;
  assertEquals(outcome.resolution, "resolved");
  assertEquals(outcome.vehicle.make, "HONDA");
  assertEquals(outcome.vehicle.model, "ACCORD");
  assertEquals(outcome.vehicle.year, 2003);
});

Deno.test("stale cache calls provider exactly once and writes 30-day TTL", async () => {
  const cache = memoryCache({
    decode_status: "decoded",
    ttl_until: "2026-08-01T00:00:00.000Z",
    normalized_data: { make: "OLD" },
  });
  let providerCalls = 0;
  const decoded = normalized({ make: "TOYOTA", model: "CAMRY", year: 2018 });
  const outcome = await resolveVehicleFromVin(SAMPLE, {
    now: () => FIXED_NOW,
    cache,
    decodeNhtsa: () => {
      providerCalls += 1;
      const result: NhtsaDecodeResult = {
        ok: true,
        normalized: decoded,
        latencyMs: 12,
      };
      return Promise.resolve(result);
    },
  });
  assertEquals(providerCalls, 1);
  assertEquals(cache.writes.length, 1);
  assertEquals(outcome.ok, true);
  if (!outcome.ok) return;
  assertEquals(outcome.vehicle.make, "TOYOTA");

  const write = cache.writes[0];
  const expectedHash = await sha256HexUtf8(SAMPLE);
  assertEquals(write.vin_hash, expectedHash);
  assertEquals(write.decode_status, "decoded");
  assertEquals(write.provider_id, "nhtsa_vpic");
  assertEquals(write.provider_version, "decode-vin-values-v2");
  assertEquals(write.schema_version, 1);
  assertEquals(write.last_error, null);
  assertEquals(write.fetched_at, FIXED_NOW.toISOString());
  const ttlMs = Date.parse(write.ttl_until) - Date.parse(write.fetched_at);
  assertEquals(ttlMs, CACHE_TTL_DAYS * 24 * 60 * 60 * 1000);
  assertEquals(write.normalized_data.make, "TOYOTA");
  const publicJson = JSON.stringify(outcome);
  assertEquals(publicJson.includes("source_metadata"), false);
  assertEquals(publicJson.includes(expectedHash), false);
});

Deno.test("missing cache calls provider once", async () => {
  const cache = memoryCache();
  let providerCalls = 0;
  await resolveVehicleFromVin(SAMPLE, {
    now: () => FIXED_NOW,
    cache,
    decodeNhtsa: () => {
      providerCalls += 1;
      return Promise.resolve({
        ok: true,
        normalized: normalized(),
        latencyMs: 1,
      });
    },
  });
  assertEquals(providerCalls, 1);
});

Deno.test("invalid VIN does not touch cache or provider", async () => {
  const cache = memoryCache();
  let providerCalls = 0;
  const outcome = await resolveVehicleFromVin("not-valid", {
    now: () => FIXED_NOW,
    cache,
    decodeNhtsa: () => {
      providerCalls += 1;
      return Promise.resolve({ ok: false, kind: "unavailable" });
    },
  });
  assertEquals(outcome, { ok: false, error: "invalid_vin" });
  assertEquals(providerCalls, 0);
  assertEquals(cache.readCount, 0);
});

Deno.test("provider timeout returns safe error", async () => {
  const outcome = await resolveVehicleFromVin(SAMPLE, {
    now: () => FIXED_NOW,
    cache: memoryCache(),
    decodeNhtsa: () => Promise.resolve({ ok: false, kind: "timeout" }),
  });
  assertEquals(outcome, { ok: false, error: "upstream_timeout" });
});

Deno.test("provider unavailable returns safe error", async () => {
  const outcome = await resolveVehicleFromVin(SAMPLE, {
    now: () => FIXED_NOW,
    cache: memoryCache(),
    decodeNhtsa: () => Promise.resolve({ ok: false, kind: "unavailable" }),
  });
  assertEquals(outcome, { ok: false, error: "upstream_unavailable" });
});

Deno.test("empty provider identity is ok=true no_data", async () => {
  const outcome = await resolveVehicleFromVin(SAMPLE, {
    now: () => FIXED_NOW,
    cache: memoryCache(),
    decodeNhtsa: () =>
      Promise.resolve({
        ok: true,
        normalized: normalized({
          make: null,
          model: null,
          year: null,
          trim: null,
          series: null,
          warnings: ["nhtsa_partial_or_empty_decode"],
        }),
        latencyMs: 3,
      }),
  });
  assertEquals(outcome.ok, true);
  if (!outcome.ok) return;
  assertEquals(outcome.resolution, "no_data");
  assertEquals(outcome.warnings, ["nhtsa_partial_or_empty_decode"]);
});

Deno.test("unsafe warnings and ErrorText are not forwarded", () => {
  const body = buildPublicSuccess(
    normalized({
      warnings: [
        "nhtsa_catalog_decode_caution",
        "Invalid characters in VIN 1HGBH41JXMN109186",
        "nhtsa_partial_or_empty_decode",
      ],
      decodeErrorText: "raw boom",
    }),
  );
  assertEquals(body.warnings, [
    "nhtsa_catalog_decode_caution",
    "nhtsa_partial_or_empty_decode",
  ]);
  assertEquals(JSON.stringify(body).includes("raw boom"), false);
});

Deno.test("cacheWriteFromNormalized is compatible with worker cache contract", () => {
  const write = cacheWriteFromNormalized({
    vinHash: "x".repeat(64),
    normalized: normalized(),
    latencyMs: 9,
    fetchedAt: FIXED_NOW,
  });
  assertEquals(write.decode_status, "decoded");
  assertEquals(write.provider_id, "nhtsa_vpic");
  assertEquals(write.provider_version, "decode-vin-values-v2");
  assertEquals(write.source_metadata.providerId, "nhtsa_vpic");
  assertEquals(typeof write.normalized_data.decodeErrorCode, "string");
});
