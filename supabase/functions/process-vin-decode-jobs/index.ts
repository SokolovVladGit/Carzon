/**
 * Carzon — Phase 2C: process queued VIN decode jobs (fake + optional NHTSA vPIC).
 *
 * Invoked only with header `x-carzon-internal-secret` matching
 * `CARZON_PROCESS_VIN_DECODE_JOBS_SECRET`.
 *
 * Required secrets (Supabase Edge Function env; never commit):
 *   - SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - CARZON_PROCESS_VIN_DECODE_JOBS_SECRET
 *
 * Optional:
 *   - CARZON_VIN_DECODER_MODE — `fake` (default) | `nhtsa`
 *
 * Never logs or returns full VIN or vin_hash. Never puts VIN in URLs logged to console.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createVinDecoderProvider, normalizeDecoderMode } from "./providers/factory.ts";

const DEFAULT_BATCH = 10;

type ClaimedJobRow = {
  job_id: string;
  listing_id: string;
  owner_id: string;
  vin_hash: string;
  idempotency_key: string;
  attempts: number;
  max_attempts: number;
};

type VinRow = { vin_normalized: string };

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

    const expectedSecret = Deno.env.get("CARZON_PROCESS_VIN_DECODE_JOBS_SECRET");
    const header = req.headers.get("x-carzon-internal-secret");
    if (!expectedSecret || header !== expectedSecret) {
      console.warn("process-vin-decode-jobs: unauthorized invoke attempt");
      return jsonResponse(401, { error: "unauthorized" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      console.error("process-vin-decode-jobs: missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
      return jsonResponse(500, { error: "supabase_env_missing" });
    }

    const decoderMode = normalizeDecoderMode(Deno.env.get("CARZON_VIN_DECODER_MODE"));
    if (decoderMode === null) {
      console.error("process-vin-decode-jobs: invalid CARZON_VIN_DECODER_MODE");
      return jsonResponse(500, { error: "vin_decoder_config_invalid" });
    }
    const decoder = createVinDecoderProvider(decoderMode);

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
      "claim_vin_decode_jobs_for_processing",
      {
        p_limit: requestedLimit,
        p_worker_id: "edge_process_vin_decode_jobs_phase2c",
      },
    );

    if (claimError) {
      console.error("process-vin-decode-jobs: claim_vin_decode_jobs_for_processing failed");
      return jsonResponse(500, { error: "claim_failed" });
    }

    const claimed = (claimedRaw ?? []) as ClaimedJobRow[];
    const n = claimed.length;
    let succeeded = 0;
    let failed = 0;

    for (const job of claimed) {
      try {
        const { data: vinRows, error: vinErr } = await supabase.rpc(
          "get_vin_for_decode_job",
          { p_job_id: job.job_id },
        );

        if (vinErr || !vinRows?.length) {
          console.error(
            `process-vin-decode-jobs: vin_unavailable_for_job job_id=${job.job_id} listing_id=${job.listing_id}`,
          );
          await supabase.rpc("complete_vin_decode_job_failure", {
            p_job_id: job.job_id,
            p_error_message: "vin_unavailable_for_job",
            p_retryable: false,
          });
          failed += 1;
          continue;
        }

        const vinNormalized = (vinRows as VinRow[])[0].vin_normalized;
        const decoded = await decoder.decode({
          vinNormalized,
          jobId: job.job_id,
          listingId: job.listing_id,
        });

        if (!decoded.ok) {
          console.error(
            `process-vin-decode-jobs: decode_failed job_id=${job.job_id} listing_id=${job.listing_id} provider=${decoder.id} code=${decoded.error.code} retryable=${decoded.error.retryable}`,
          );
          await supabase.rpc("complete_vin_decode_job_failure", {
            p_job_id: job.job_id,
            p_error_message: decoded.error.safeMessage,
            p_retryable: decoded.error.retryable,
          });
          failed += 1;
          continue;
        }

        const norm = decoded.normalized;
        const meta = decoded.metadata;

        const pNormalizedData: Record<string, unknown> = {
          make: norm.make,
          model: norm.model,
          year: norm.year,
          bodyType: norm.bodyType,
          fuelType: norm.fuelType,
          engine: norm.engine,
          transmission: norm.transmission,
          manufacturer: norm.manufacturer,
          plantCountry: norm.plantCountry,
          plantCity: norm.plantCity,
          plantCompany: norm.plantCompany,
          vehicleType: norm.vehicleType,
          trim: norm.trim,
          series: norm.series,
          driveType: norm.driveType,
          doors: norm.doors,
          displacement: norm.displacement,
          cylinders: norm.cylinders,
          grossVehicleWeightRating: norm.grossVehicleWeightRating,
          market: norm.market,
          rawCompletenessScore: norm.rawCompletenessScore,
          warnings: norm.warnings,
          decodeErrorCode: norm.decodeErrorCode,
          decodeErrorText: norm.decodeErrorText,
        };

        const pSourceMetadata: Record<string, unknown> = {
          providerId: meta.providerId,
          providerVersion: meta.providerVersion,
          latencyMs: meta.latencyMs,
        };
        if (meta.requestId) pSourceMetadata.requestId = meta.requestId;

        const pSummary: Record<string, unknown> = {
          completeness: norm.rawCompletenessScore,
          warnings: norm.warnings,
        };

        const { error: okErr } = await supabase.rpc(
          "complete_vin_decode_job_success",
          {
            p_job_id: job.job_id,
            p_vin_hash: job.vin_hash,
            p_provider_id: meta.providerId,
            p_provider_version: meta.providerVersion,
            p_normalized_data: pNormalizedData,
            p_source_metadata: pSourceMetadata,
            p_decoded_make: norm.make,
            p_decoded_model: norm.model,
            p_decoded_year: norm.year,
            p_decoded_body_type: norm.bodyType,
            p_decoded_fuel_type: norm.fuelType,
            p_field_comparisons: [],
            p_summary: pSummary,
          },
        );

        if (okErr) {
          console.error(
            `process-vin-decode-jobs: complete_success_rejected job_id=${job.job_id} listing_id=${job.listing_id} provider=${meta.providerId}`,
          );
          await supabase.rpc("complete_vin_decode_job_failure", {
            p_job_id: job.job_id,
            p_error_message: "complete_success_rejected",
            p_retryable: true,
          });
          failed += 1;
        } else {
          console.info(
            `process-vin-decode-jobs: job_ok job_id=${job.job_id} listing_id=${job.listing_id} provider=${meta.providerId} latency_ms=${meta.latencyMs}`,
          );
          succeeded += 1;
        }
      } catch {
        await supabase.rpc("complete_vin_decode_job_failure", {
          p_job_id: job.job_id,
          p_error_message: "unexpected_job_error",
          p_retryable: true,
        });
        failed += 1;
      }
    }

    console.info(
      `process-vin-decode-jobs: batch_done claimed=${n} succeeded=${succeeded} failed=${failed} mode=${decoderMode}`,
    );

    return jsonResponse(200, {
      ok: true,
      claimed: n,
      succeeded,
      failed,
    });
  } catch {
    console.error("process-vin-decode-jobs: fatal");
    return jsonResponse(500, { error: "internal_error" });
  }
});
