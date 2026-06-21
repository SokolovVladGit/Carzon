/**
 * EPA / FuelEconomy.gov provider (server-side REST + XML only).
 */

import type {
  ModelDataFetchInput,
  ModelDataProvider,
  ModelDataProviderResult,
} from "./types.ts";
import {
  buildEpaMenuMatchContext,
  buildEpaModelMenuCandidates,
  buildEpaProviderModelQueryMetadata,
  type EpaMenuMatchContext,
  type EpaModelMenuCandidate,
} from "./epa_model_candidates.ts";
import {
  aggregateEpaVehicleDetails,
  buildEpaMenuOptionsUrl,
  buildEpaNoDataResult,
  buildEpaSummaryFromVehicleDetail,
  buildEpaVehicleDetailUrl,
  defaultEpaSuccessLimitationCodes,
  EPA_PROVIDER_VERSION,
  EPA_SOURCE_LABEL,
  epaSummaryHasCoreFields,
  parseEpaVehicleDetailXml,
  parseMenuOptionVehicleIds,
} from "./epa_mapping.ts";

const EPA_TIMEOUT_MS = 15_000;
const MAX_MULTI_OPTIONS = 5;

export type EpaHttpClient = {
  getText(url: string, timeoutMs: number): Promise<{
    ok: boolean;
    status: number;
    body: string;
  }>;
};

async function defaultHttpGet(
  url: string,
  timeoutMs: number,
): Promise<{ ok: boolean; status: number; body: string }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      method: "GET",
      signal: controller.signal,
      headers: { Accept: "application/xml,text/xml,*/*" },
    });
    const body = await res.text();
    return { ok: res.ok, status: res.status, body };
  } finally {
    clearTimeout(timer);
  }
}

type MenuLookupResult =
  | {
    ok: true;
    optionIds: string[];
    menuContext: EpaMenuMatchContext;
  }
  | { ok: false; result: ModelDataProviderFailure };

export class EpaFuelEconomyProvider implements ModelDataProvider {
  readonly id = "epa_fueleconomy";

  constructor(private readonly http: EpaHttpClient = { getText: defaultHttpGet }) {}

  async fetch(input: ModelDataFetchInput): Promise<ModelDataProviderResult> {
    if (input.sourceId !== "epa_fueleconomy") {
      return {
        ok: false,
        error: {
          code: "unsupported_source",
          safeMessage: "unsupported_source",
          retryable: false,
        },
      };
    }

    const menuLookup = await this.resolveMenuOptions(input);
    if (!menuLookup.ok) return menuLookup.result;

    const { optionIds, menuContext } = menuLookup;

    if (optionIds.length === 0) {
      return this.buildNoDataResult(menuContext);
    }

    const baseMetadata = buildEpaProviderModelQueryMetadata(menuContext, {
      providerId: this.id,
      providerVersion: EPA_PROVIDER_VERSION,
      optionCount: optionIds.length,
    });

    if (optionIds.length === 1) {
      return await this.fetchSingleOption(input, optionIds[0]!, baseMetadata);
    }

    return await this.fetchMultipleOptions(input, optionIds, baseMetadata);
  }

  private async resolveMenuOptions(
    input: ModelDataFetchInput,
  ): Promise<MenuLookupResult> {
    const candidates = buildEpaModelMenuCandidates({
      sellerMake: input.lookupMake,
      sellerModel: input.lookupModel,
      sellerYear: input.lookupYear,
      vinHints: input.vinHints ?? null,
    });
    const attemptedProviderModels: string[] = [];

    for (const candidate of candidates) {
      attemptedProviderModels.push(candidate.model);
      const menuUrl = buildEpaMenuOptionsUrl(
        candidate.year,
        candidate.make,
        candidate.model,
      );

      let menuResponse: { ok: boolean; status: number; body: string };
      try {
        menuResponse = await this.http.getText(menuUrl, EPA_TIMEOUT_MS);
      } catch {
        return {
          ok: false,
          result: {
            ok: false,
            error: {
              code: "epa_menu_timeout",
              safeMessage: "epa_menu_timeout",
              retryable: true,
            },
          },
        };
      }

      if (menuResponse.status === 429 || menuResponse.status >= 500) {
        return {
          ok: false,
          result: {
            ok: false,
            error: {
              code: "epa_menu_http_error",
              safeMessage: "epa_menu_http_error",
              retryable: true,
            },
          },
        };
      }

      if (!menuResponse.ok) {
        continue;
      }

      const optionIds = parseMenuOptionVehicleIds(menuResponse.body);
      if (optionIds.length === 0) {
        continue;
      }

      return {
        ok: true,
        optionIds,
        menuContext: buildEpaMenuMatchContext(
          candidates,
          candidate,
          attemptedProviderModels,
        ),
      };
    }

    const fallbackCandidate: EpaModelMenuCandidate = candidates[0] ?? {
      make: input.lookupMake.trim(),
      model: input.lookupModel.trim(),
      year: input.lookupYear,
      source: "seller_identity",
    };

    return {
      ok: true,
      optionIds: [],
      menuContext: buildEpaMenuMatchContext(
        candidates,
        fallbackCandidate,
        attemptedProviderModels,
      ),
    };
  }

  private buildNoDataResult(
    menuContext: EpaMenuMatchContext,
  ): ModelDataProviderResult {
    const noData = buildEpaNoDataResult("no_match");
    return {
      ok: true,
      status: noData.status,
      confidence: noData.confidence,
      normalizedSummary: noData.normalizedSummary,
      limitationCodes: noData.limitationCodes,
      matchQuality: noData.matchQuality,
      sourceLabel: EPA_SOURCE_LABEL,
      providerVersion: EPA_PROVIDER_VERSION,
      sourceMetadata: buildEpaProviderModelQueryMetadata(menuContext, {
        providerId: this.id,
        providerVersion: EPA_PROVIDER_VERSION,
        optionCount: 0,
      }),
    };
  }

  private async fetchSingleOption(
    input: ModelDataFetchInput,
    vehicleId: string,
    baseMetadata: Record<string, unknown>,
  ): Promise<ModelDataProviderResult> {
    const detailResult = await this.fetchVehicleDetailXml(vehicleId);
    if (!detailResult.ok) return detailResult.result;

    const parsed = parseEpaVehicleDetailXml(detailResult.body);
    const summary = buildEpaSummaryFromVehicleDetail(
      parsed,
      "exact_make_model_year",
    );

    if (!epaSummaryHasCoreFields(summary)) {
      const noData = buildEpaNoDataResult("exact_make_model_year", [
        "source_data_unavailable",
      ]);
      return {
        ok: true,
        status: "no_data",
        confidence: "unknown",
        normalizedSummary: {},
        limitationCodes: noData.limitationCodes,
        matchQuality: "exact_make_model_year",
        sourceLabel: EPA_SOURCE_LABEL,
        providerVersion: EPA_PROVIDER_VERSION,
        sourceMetadata: {
          ...baseMetadata,
          optionVehicleIds: [vehicleId],
        },
      };
    }

    return {
      ok: true,
      status: "succeeded",
      confidence: "official",
      normalizedSummary: summary,
      limitationCodes: defaultEpaSuccessLimitationCodes([
        "basic_catalog_reference_only",
      ]),
      matchQuality: "exact_make_model_year",
      sourceLabel: EPA_SOURCE_LABEL,
      providerVersion: EPA_PROVIDER_VERSION,
      sourceMetadata: {
        ...baseMetadata,
        optionVehicleIds: [vehicleId],
      },
    };
  }

  private async fetchMultipleOptions(
    input: ModelDataFetchInput,
    optionIds: string[],
    baseMetadata: Record<string, unknown>,
  ): Promise<ModelDataProviderResult> {
    const selected = optionIds.slice(0, MAX_MULTI_OPTIONS);
    const parsedDetails = [];

    for (const id of selected) {
      const detailResult = await this.fetchVehicleDetailXml(id);
      if (!detailResult.ok) {
        if (detailResult.result.error.retryable) {
          return detailResult.result;
        }
        continue;
      }
      parsedDetails.push(parseEpaVehicleDetailXml(detailResult.body));
    }

    if (parsedDetails.length === 0) {
      return {
        ok: false,
        error: {
          code: "epa_detail_unavailable",
          safeMessage: "epa_detail_unavailable",
          retryable: true,
        },
      };
    }

    const summary = aggregateEpaVehicleDetails(parsedDetails, selected);
    if (!epaSummaryHasCoreFields(summary)) {
      const noData = buildEpaNoDataResult("make_model_year_multiple_options");
      return {
        ok: true,
        status: "no_data",
        confidence: "unknown",
        normalizedSummary: {},
        limitationCodes: noData.limitationCodes,
        matchQuality: "make_model_year_multiple_options",
        sourceLabel: EPA_SOURCE_LABEL,
        providerVersion: EPA_PROVIDER_VERSION,
        sourceMetadata: {
          ...baseMetadata,
          optionVehicleIds: selected,
          aggregatedFrom: parsedDetails.length,
          strategy: "average_numeric_fields",
        },
      };
    }

    return {
      ok: true,
      status: "partial",
      confidence: "official",
      normalizedSummary: summary,
      limitationCodes: defaultEpaSuccessLimitationCodes([
        "multiple_configurations_possible",
        "basic_catalog_reference_only",
      ]),
      matchQuality: "make_model_year_multiple_options",
      sourceLabel: EPA_SOURCE_LABEL,
      providerVersion: EPA_PROVIDER_VERSION,
      sourceMetadata: {
        ...baseMetadata,
        optionVehicleIds: selected,
        aggregatedFrom: parsedDetails.length,
        strategy: "average_numeric_fields",
      },
    };
  }

  private async fetchVehicleDetailXml(
    vehicleId: string,
  ): Promise<
    | { ok: true; body: string }
    | { ok: false; result: ModelDataProviderFailure }
  > {
    const url = buildEpaVehicleDetailUrl(vehicleId);
    let response: { ok: boolean; status: number; body: string };
    try {
      response = await this.http.getText(url, EPA_TIMEOUT_MS);
    } catch {
      return {
        ok: false,
        result: {
          ok: false,
          error: {
            code: "epa_detail_timeout",
            safeMessage: "epa_detail_timeout",
            retryable: true,
          },
        },
      };
    }

    if (response.status === 429 || response.status >= 500) {
      return {
        ok: false,
        result: {
          ok: false,
          error: {
            code: "epa_detail_http_error",
            safeMessage: "epa_detail_http_error",
            retryable: true,
          },
        },
      };
    }

    if (!response.ok) {
      return {
        ok: false,
        result: {
          ok: false,
          error: {
            code: "epa_detail_http_error",
            safeMessage: "epa_detail_http_error",
            retryable: false,
          },
        },
      };
    }

    return { ok: true, body: response.body };
  }
}

type ModelDataProviderFailure = Extract<ModelDataProviderResult, { ok: false }>;
