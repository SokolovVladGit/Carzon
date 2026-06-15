/**
 * Carzon — Model Passport Phase 1: process queued model-data fetch jobs (fake only).
 *
 * Invoked only with header `x-carzon-internal-secret` matching
 * `CARZON_PROCESS_MODEL_DATA_JOBS_SECRET`.
 *
 * Required secrets (Supabase Edge Function env; never commit):
 *   - SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - CARZON_PROCESS_MODEL_DATA_JOBS_SECRET
 *
 * Optional:
 *   - CARZON_MODEL_DATA_PROVIDER_MODE — `fake` (default) | `fake_sample` | `epa`
 *
 * Phase 1: no real EPA/FuelEconomy.gov HTTP. No Wikidata. No recall data.
 * Never logs raw provider payloads or listing identifiers beyond job_id.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createModelDataProvider,
  normalizeProviderMode,
} from "./providers/factory.ts";

const DEFAULT_BATCH = 10;

type ClaimedJobRow = {
  job_id: string;
  cache_key: string;
  source_id: string;
  lookup_make: string;
  lookup_model: string;
  lookup_year: number;
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

    const expectedSecret = Deno.env.get("CARZON_PROCESS_MODEL_DATA_JOBS_SECRET");
    const header = req.headers.get("x-carzon-internal-secret");
    if (!expectedSecret || header !== expectedSecret) {
      console.warn("process-model-data-jobs: unauthorized invoke attempt");
      return jsonResponse(401, { error: "unauthorized" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      console.error(
        "process-model-data-jobs: missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY",
      );
      return jsonResponse(500, { error: "supabase_env_missing" });
    }

    const providerMode = normalizeProviderMode(
      Deno.env.get("CARZON_MODEL_DATA_PROVIDER_MODE"),
    );
    if (providerMode === null) {
      console.error("process-model-data-jobs: invalid CARZON_MODEL_DATA_PROVIDER_MODE");
      return jsonResponse(500, { error: "model_data_provider_config_invalid" });
    }
    const provider = createModelDataProvider(providerMode);

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

    const { data: claimedRaw, error: claimError } = await supabase.rpc(
      "claim_vehicle_model_fetch_jobs_for_processing",
      { p_limit: requestedLimit },
    );

    if (claimError) {
      console.error(
        "process-model-data-jobs: claim_vehicle_model_fetch_jobs_for_processing failed",
      );
      return jsonResponse(500, { error: "claim_failed" });
    }

    const claimed = (claimedRaw ?? []) as ClaimedJobRow[];
    const n = claimed.length;
    let succeeded = 0;
    let failed = 0;

    for (const job of claimed) {
      try {
        const result = await provider.fetch({
          lookupMake: job.lookup_make,
          lookupModel: job.lookup_model,
          lookupYear: job.lookup_year,
          sourceId: job.source_id,
          jobId: job.job_id,
          cacheKey: job.cache_key,
        });

        if (!result.ok) {
          console.error(
            `process-model-data-jobs: fetch_failed job_id=${job.job_id} code=${result.error.code} retryable=${result.error.retryable}`,
          );
          await supabase.rpc("complete_vehicle_model_fetch_job_failure", {
            p_job_id: job.job_id,
            p_error_message: result.error.safeMessage,
            p_retryable: result.error.retryable,
          });
          failed += 1;
          continue;
        }

        const { error: okErr } = await supabase.rpc(
          "complete_vehicle_model_fetch_job_success",
          {
            p_job_id: job.job_id,
            p_cache_key: job.cache_key,
            p_status: result.status,
            p_confidence: result.confidence,
            p_normalized_summary: result.normalizedSummary,
            p_limitation_codes: result.limitationCodes,
            p_match_quality: result.matchQuality,
            p_source_label: result.sourceLabel,
            p_provider_version: result.providerVersion,
            p_source_metadata: result.sourceMetadata,
            p_ttl_days: result.status === "no_data" ? 7 : 90,
          },
        );

        if (okErr) {
          console.error(
            `process-model-data-jobs: complete_success_rejected job_id=${job.job_id}`,
          );
          await supabase.rpc("complete_vehicle_model_fetch_job_failure", {
            p_job_id: job.job_id,
            p_error_message: "complete_success_rejected",
            p_retryable: true,
          });
          failed += 1;
        } else {
          console.info(
            `process-model-data-jobs: job_ok job_id=${job.job_id} status=${result.status} mode=${providerMode}`,
          );
          succeeded += 1;
        }
      } catch {
        await supabase.rpc("complete_vehicle_model_fetch_job_failure", {
          p_job_id: job.job_id,
          p_error_message: "unexpected_job_error",
          p_retryable: true,
        });
        failed += 1;
      }
    }

    console.info(
      `process-model-data-jobs: batch_done claimed=${n} succeeded=${succeeded} failed=${failed} mode=${providerMode}`,
    );

    return jsonResponse(200, {
      ok: true,
      claimed: n,
      succeeded,
      failed,
    });
  } catch {
    console.error("process-model-data-jobs: fatal");
    return jsonResponse(500, { error: "internal_error" });
  }
});
