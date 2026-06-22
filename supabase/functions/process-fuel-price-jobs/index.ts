/**
 * Carzon — Fuel Prices v1: process queued fuel-price fetch jobs.
 *
 * Invoked only with header `x-carzon-internal-secret` matching
 * `CARZON_PROCESS_FUEL_PRICE_JOBS_SECRET`.
 *
 * Required secrets (Supabase Edge Function env; never commit):
 *   - SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - CARZON_PROCESS_FUEL_PRICE_JOBS_SECRET
 *
 * Required:
 *   - CARZON_FUEL_PRICE_PROVIDER_MODE — `live` | `fake` (must be set explicitly)
 *
 * Never logs raw HTML/JSON payloads or cache keys beyond job_id.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createFuelPriceProvider,
  normalizeProviderMode,
} from "./providers/factory.ts";
import type { FuelPriceSourceId, FuelPriceTerritory } from "./providers/types.ts";

const DEFAULT_BATCH = 10;

type ClaimedJobRow = {
  job_id: string;
  cache_key: string;
  territory: FuelPriceTerritory;
  source_id: FuelPriceSourceId;
  attempts: number;
};

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const expectedSecret = Deno.env.get("CARZON_PROCESS_FUEL_PRICE_JOBS_SECRET");
    const header = req.headers.get("x-carzon-internal-secret");
    if (!expectedSecret || header !== expectedSecret) {
      console.warn("process-fuel-price-jobs: unauthorized invoke attempt");
      return jsonResponse(401, { error: "unauthorized" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      console.error(
        "process-fuel-price-jobs: missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY",
      );
      return jsonResponse(500, { error: "supabase_env_missing" });
    }

    const providerMode = normalizeProviderMode(
      Deno.env.get("CARZON_FUEL_PRICE_PROVIDER_MODE"),
    );
    if (providerMode === null) {
      console.error(
        "process-fuel-price-jobs: invalid CARZON_FUEL_PRICE_PROVIDER_MODE",
      );
      return jsonResponse(500, { error: "fuel_price_provider_config_invalid" });
    }

    let requestedLimit = DEFAULT_BATCH;
    try {
      const ct = req.headers.get("content-type") ?? "";
      if (ct.includes("application/json")) {
        const raw = await req.json().catch(() => null) as { limit?: number } | null;
        if (raw && typeof raw.limit === "number" && Number.isFinite(raw.limit)) {
          requestedLimit = Math.trunc(raw.limit);
        }
      }
    } catch {
      /* ignore malformed optional JSON body */
    }

    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    await supabase.rpc("enqueue_all_fuel_price_fetch_jobs");

    const { data: claimedRaw, error: claimError } = await supabase.rpc(
      "claim_fuel_price_fetch_jobs_for_processing",
      { p_limit: requestedLimit },
    );

    if (claimError) {
      console.error(
        "process-fuel-price-jobs: claim_fuel_price_fetch_jobs_for_processing failed",
      );
      return jsonResponse(500, { error: "claim_failed" });
    }

    const claimed = (claimedRaw ?? []) as ClaimedJobRow[];
    const n = claimed.length;
    let succeeded = 0;
    let failed = 0;

    for (const job of claimed) {
      try {
        const provider = createFuelPriceProvider(providerMode, job.source_id);
        const result = await provider.fetch({
          cacheKey: job.cache_key,
          territory: job.territory,
          sourceId: job.source_id,
          jobId: job.job_id,
        });

        if (!result.ok) {
          console.error(
            `process-fuel-price-jobs: fetch_failed job_id=${job.job_id} code=${result.error.code} retryable=${result.error.retryable}`,
          );
          await supabase.rpc("complete_fuel_price_fetch_job_failure", {
            p_job_id: job.job_id,
            p_error_message: result.error.safeMessage,
            p_failure_code: result.error.code,
            p_retryable: result.error.retryable,
          });
          failed += 1;
          continue;
        }

        const effectiveDate = result.effectiveDate ?? null;
        const { error: okErr } = await supabase.rpc(
          "complete_fuel_price_fetch_job_success",
          {
            p_job_id: job.job_id,
            p_cache_key: job.cache_key,
            p_status: result.status,
            p_normalized_summary: result.normalizedSummary,
            p_limitation_codes: result.limitationCodes,
            p_source_label: result.sourceLabel,
            p_effective_date: effectiveDate,
            p_provider_version: result.providerVersion,
            p_source_metadata: result.sourceMetadata,
            p_ttl_hours: 24,
          },
        );

        if (okErr) {
          console.error(
            `process-fuel-price-jobs: complete_success_rejected job_id=${job.job_id}`,
          );
          await supabase.rpc("complete_fuel_price_fetch_job_failure", {
            p_job_id: job.job_id,
            p_error_message: "complete_success_rejected",
            p_failure_code: "complete_success_rejected",
            p_retryable: true,
          });
          failed += 1;
        } else {
          console.info(
            `process-fuel-price-jobs: job_ok job_id=${job.job_id} status=${result.status} mode=${providerMode} source=${job.source_id}`,
          );
          succeeded += 1;
        }
      } catch {
        await supabase.rpc("complete_fuel_price_fetch_job_failure", {
          p_job_id: job.job_id,
          p_error_message: "unexpected_job_error",
          p_failure_code: "unexpected_job_error",
          p_retryable: true,
        });
        failed += 1;
      }
    }

    console.info(
      `process-fuel-price-jobs: batch_done claimed=${n} succeeded=${succeeded} failed=${failed} mode=${providerMode}`,
    );

    return jsonResponse(200, {
      ok: true,
      claimed: n,
      succeeded,
      failed,
    });
  } catch {
    console.error("process-fuel-price-jobs: fatal");
    return jsonResponse(500, { error: "internal_error" });
  }
});
