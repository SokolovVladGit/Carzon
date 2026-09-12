import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  handleResolveVehicleRequest,
  parseVinRequestBody,
  safeResolveLog,
  type SafeLogEvent,
} from "./handler.ts";
import type { ResolverNormalizedFields } from "./nhtsa.ts";
import type { CacheWriteRow, VinDecodeCachePort } from "./resolve.ts";

const SAMPLE = "1HGBH41JXMN109186";

function normalized(): ResolverNormalizedFields {
  return {
    make: "HONDA",
    model: "ACCORD",
    year: 2003,
    bodyType: "Sedan/Saloon",
    fuelType: "Gasoline",
    engine: null,
    transmission: null,
    manufacturer: "HONDA",
    plantCountry: null,
    plantCity: null,
    plantCompany: null,
    vehicleType: null,
    trim: "EX",
    series: null,
    driveType: null,
    doors: null,
    displacement: null,
    cylinders: null,
    grossVehicleWeightRating: null,
    market: "US_catalog_bias",
    rawCompletenessScore: 0.5,
    warnings: [],
    decodeErrorCode: "0",
    decodeErrorText: "must-not-leak",
  };
}

function cacheMiss(): VinDecodeCachePort & { writes: CacheWriteRow[] } {
  const writes: CacheWriteRow[] = [];
  return {
    writes,
    readByHash: () => Promise.resolve(null),
    upsertDecoded: (row) => {
      writes.push(row);
      return Promise.resolve();
    },
  };
}

async function readJson(res: Response): Promise<Record<string, unknown>> {
  return await res.json() as Record<string, unknown>;
}

Deno.test("parseVinRequestBody rejects malformed JSON", async () => {
  const req = new Request("http://local/resolve-vehicle", {
    method: "POST",
    body: "{",
    headers: { "Content-Type": "application/json" },
  });
  assertEquals(await parseVinRequestBody(req), {
    ok: false,
    error: "invalid_request",
  });
});

Deno.test("parseVinRequestBody rejects extra keys and non-string vin", async () => {
  const extra = new Request("http://local/resolve-vehicle", {
    method: "POST",
    body: JSON.stringify({ vin: SAMPLE, listing_id: "x" }),
  });
  assertEquals(await parseVinRequestBody(extra), {
    ok: false,
    error: "invalid_request",
  });
  const numeric = new Request("http://local/resolve-vehicle", {
    method: "POST",
    body: JSON.stringify({ vin: 1 }),
  });
  assertEquals(await parseVinRequestBody(numeric), {
    ok: false,
    error: "invalid_request",
  });
});

Deno.test("unsupported HTTP method returns 405", async () => {
  const res = await handleResolveVehicleRequest(
    new Request("http://local/resolve-vehicle", { method: "GET" }),
    {
      requireUser: () => Promise.resolve({ ok: true }),
      ports: {
        now: () => new Date(),
        cache: cacheMiss(),
        decodeNhtsa: () => Promise.resolve({ ok: false, kind: "unavailable" }),
      },
    },
  );
  assertEquals(res.status, 405);
  assertEquals(await readJson(res), { ok: false, error: "method_not_allowed" });
});

Deno.test("missing auth returns unauthorized", async () => {
  const res = await handleResolveVehicleRequest(
    new Request("http://local/resolve-vehicle", {
      method: "POST",
      body: JSON.stringify({ vin: SAMPLE }),
    }),
    {
      requireUser: () =>
        Promise.resolve({ ok: false, status: 401, error: "unauthorized" }),
      ports: {
        now: () => new Date(),
        cache: cacheMiss(),
        decodeNhtsa: () => Promise.resolve({ ok: false, kind: "unavailable" }),
      },
    },
  );
  assertEquals(res.status, 401);
  assertEquals(await readJson(res), { ok: false, error: "unauthorized" });
});

Deno.test("malformed JSON request returns invalid_request", async () => {
  const res = await handleResolveVehicleRequest(
    new Request("http://local/resolve-vehicle", {
      method: "POST",
      body: "not-json",
    }),
    {
      requireUser: () => Promise.resolve({ ok: true }),
      ports: {
        now: () => new Date(),
        cache: cacheMiss(),
        decodeNhtsa: () => Promise.resolve({ ok: false, kind: "unavailable" }),
      },
    },
  );
  assertEquals(res.status, 400);
  assertEquals(await readJson(res), { ok: false, error: "invalid_request" });
});

Deno.test("invalid VIN returns invalid_vin without provider call", async () => {
  let providerCalls = 0;
  const res = await handleResolveVehicleRequest(
    new Request("http://local/resolve-vehicle", {
      method: "POST",
      body: JSON.stringify({ vin: "short" }),
    }),
    {
      requireUser: () => Promise.resolve({ ok: true }),
      ports: {
        now: () => new Date(),
        cache: cacheMiss(),
        decodeNhtsa: () => {
          providerCalls += 1;
          return Promise.resolve({ ok: false, kind: "unavailable" });
        },
      },
    },
  );
  assertEquals(res.status, 400);
  assertEquals(await readJson(res), { ok: false, error: "invalid_vin" });
  assertEquals(providerCalls, 0);
});

Deno.test("success response does not leak internals", async () => {
  const res = await handleResolveVehicleRequest(
    new Request("http://local/resolve-vehicle", {
      method: "POST",
      body: JSON.stringify({ vin: SAMPLE }),
    }),
    {
      requireUser: () => Promise.resolve({ ok: true }),
      ports: {
        now: () => new Date("2026-09-07T12:00:00.000Z"),
        cache: cacheMiss(),
        decodeNhtsa: () =>
          Promise.resolve({
            ok: true,
            normalized: normalized(),
            latencyMs: 4,
          }),
      },
    },
  );
  assertEquals(res.status, 200);
  const body = await readJson(res);
  const text = JSON.stringify(body);
  assertEquals(body.ok, true);
  assertEquals(body.resolution, "resolved");
  assertEquals(text.includes(SAMPLE), false);
  assertEquals(text.includes("vin_hash"), false);
  assertEquals(text.includes("must-not-leak"), false);
  assertEquals(text.includes("source_metadata"), false);
  assertEquals(text.includes("decodeError"), false);
  assertEquals(text.includes("nhtsa_vpic"), false);
  assertEquals(text.includes("listing"), false);
});

Deno.test("upstream timeout and non-2xx map to safe HTTP errors", async () => {
  const timeout = await handleResolveVehicleRequest(
    new Request("http://local/resolve-vehicle", {
      method: "POST",
      body: JSON.stringify({ vin: SAMPLE }),
    }),
    {
      requireUser: () => Promise.resolve({ ok: true }),
      ports: {
        now: () => new Date(),
        cache: cacheMiss(),
        decodeNhtsa: () => Promise.resolve({ ok: false, kind: "timeout" }),
      },
    },
  );
  assertEquals(timeout.status, 504);
  assertEquals(await readJson(timeout), {
    ok: false,
    error: "upstream_timeout",
  });

  const unavailable = await handleResolveVehicleRequest(
    new Request("http://local/resolve-vehicle", {
      method: "POST",
      body: JSON.stringify({ vin: SAMPLE }),
    }),
    {
      requireUser: () => Promise.resolve({ ok: true }),
      ports: {
        now: () => new Date(),
        cache: cacheMiss(),
        decodeNhtsa: () => Promise.resolve({ ok: false, kind: "unavailable" }),
      },
    },
  );
  assertEquals(unavailable.status, 502);
  assertEquals(await readJson(unavailable), {
    ok: false,
    error: "upstream_unavailable",
  });
});

Deno.test("safeResolveLog only emits closed event vocabulary", () => {
  const source = Deno.readTextFileSync(
    new URL("./handler.ts", import.meta.url),
  );
  assertEquals(source.includes("console.log"), false);
  assertEquals(source.includes("vin_hash"), false);
  assertEquals(/console\.info\(`resolve-vehicle: \$\{event\}`\)/.test(source), true);
  const allowed: SafeLogEvent[] = [
    "unauthorized",
    "invalid_request",
    "invalid_vin",
    "cache_reusable",
    "provider_timeout",
    "provider_unavailable",
    "internal_error",
  ];
  safeResolveLog(allowed[0]);
});
