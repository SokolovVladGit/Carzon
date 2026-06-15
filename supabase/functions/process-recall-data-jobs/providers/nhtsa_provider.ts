/**
 * NHTSA recallsByVehicle provider (server-side JSON only).
 */

import type {
  RecallFetchInput,
  RecallProvider,
  RecallProviderResult,
} from "./types.ts";
import {
  buildNhtsaRecallsByVehicleUrl,
  buildRecallNoDataResult,
  buildRecallPartialResult,
  buildRecallSuccessResult,
  parseNhtsaRecallsResponse,
} from "./nhtsa_mapping.ts";

const NHTSA_TIMEOUT_MS = 15_000;
const MAX_CAMPAIGNS_BEFORE_PARTIAL = 10;

export type NhtsaHttpClient = {
  getJson(url: string, timeoutMs: number): Promise<{
    ok: boolean;
    status: number;
    body: unknown;
  }>;
};

async function defaultHttpGetJson(
  url: string,
  timeoutMs: number,
): Promise<{ ok: boolean; status: number; body: unknown }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      method: "GET",
      signal: controller.signal,
      headers: { Accept: "application/json" },
    });
    const text = await res.text();
    let body: unknown = null;
    try {
      body = text.length > 0 ? JSON.parse(text) : null;
    } catch {
      body = null;
    }
    return { ok: res.ok, status: res.status, body };
  } finally {
    clearTimeout(timer);
  }
}

export class NhtsaRecallsProvider implements RecallProvider {
  readonly id = "nhtsa_recalls";

  constructor(private readonly http: NhtsaHttpClient = {
    getJson: defaultHttpGetJson,
  }) {}

  async fetch(input: RecallFetchInput): Promise<RecallProviderResult> {
    if (input.sourceId !== "nhtsa_recalls") {
      return {
        ok: false,
        error: {
          code: "unsupported_source",
          safeMessage: "unsupported_source",
          retryable: false,
        },
      };
    }

    const url = buildNhtsaRecallsByVehicleUrl(
      input.lookupMake,
      input.lookupModel,
      input.lookupYear,
    );

    let response: { ok: boolean; status: number; body: unknown };
    try {
      response = await this.http.getJson(url, NHTSA_TIMEOUT_MS);
    } catch {
      return {
        ok: false,
        error: {
          code: "nhtsa_request_timeout",
          safeMessage: "nhtsa_request_timeout",
          retryable: true,
        },
      };
    }

    if (response.status === 429 || response.status >= 500) {
      return {
        ok: false,
        error: {
          code: "nhtsa_http_error",
          safeMessage: "nhtsa_http_error",
          retryable: true,
        },
      };
    }

    if (!response.ok) {
      return {
        ok: false,
        error: {
          code: "nhtsa_http_error",
          safeMessage: "nhtsa_http_error",
          retryable: false,
        },
      };
    }

    const parsed = parseNhtsaRecallsResponse(response.body);
    if (!parsed.ok) {
      return {
        ok: false,
        error: {
          code: parsed.code,
          safeMessage: parsed.safeMessage,
          retryable: parsed.retryable,
        },
      };
    }

    if (parsed.campaigns.length === 0) {
      return buildRecallNoDataResult("no_match");
    }

    if (parsed.campaigns.length > MAX_CAMPAIGNS_BEFORE_PARTIAL) {
      return buildRecallPartialResult(
        parsed.campaigns.slice(0, MAX_CAMPAIGNS_BEFORE_PARTIAL),
      );
    }

    return buildRecallSuccessResult(parsed.campaigns, "exact_make_model_year");
  }
}
