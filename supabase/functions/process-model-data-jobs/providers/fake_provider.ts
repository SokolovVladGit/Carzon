/**
 * Phase 1 fake model-data provider — deterministic, non-production.
 *
 * Default behavior: always returns no_data (safe for hosted cron before EPA phase).
 * Sample payload only when CARZON_MODEL_DATA_PROVIDER_MODE=fake_sample (manual QA).
 */

import type {
  ModelDataFetchInput,
  ModelDataProvider,
  ModelDataProviderResult,
} from "./types.ts";
import { DEFAULT_EPA_LIMITATION_CODES } from "./types.ts";
import type { EpaCompatibleSummary } from "./types.ts";

function foldKey(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, " ");
}

type FakeSampleSpec = {
  make: string;
  model: string;
  year: number;
  normalizedSummary: EpaCompatibleSummary;
  sourceLabel: string;
  fakeSampleId: string;
};

const FAKE_SAMPLE_SPECS: FakeSampleSpec[] = [
  {
    make: "toyota",
    model: "camry",
    year: 2020,
    fakeSampleId: "fake-sample-2020-camry",
    sourceLabel: "EPA · FuelEconomy.gov (fake sample)",
    normalizedSummary: {
      provider_vehicle_id: "fake-sample-2020-camry",
      fuel_type: "regular_gasoline",
      city_mpg: 28,
      highway_mpg: 39,
      combined_mpg: 32,
      city_l_per_100km: 8.4,
      highway_l_per_100km: 6.0,
      combined_l_per_100km: 7.4,
      co2_g_per_mile: 278,
      co2_g_per_km: 173,
      vehicle_class: "Midsize Cars",
      market: "US",
      match_quality: "exact_make_model_year",
    },
  },
  {
    make: "toyota",
    model: "highlander",
    year: 2020,
    fakeSampleId: "fake-sample-2020-highlander",
    sourceLabel: "EPA · FuelEconomy.gov",
    normalizedSummary: {
      provider_vehicle_id: "fake-sample-2020-highlander",
      fuel_type: "regular_gasoline",
      city_mpg: 21,
      highway_mpg: 29,
      combined_mpg: 24,
      city_l_per_100km: 11.2,
      highway_l_per_100km: 8.1,
      combined_l_per_100km: 9.8,
      co2_g_per_mile: 350,
      co2_g_per_km: 217,
      vehicle_class: "Standard Sport Utility Vehicle 4WD",
      market: "US",
      match_quality: "exact_make_model_year",
    },
  },
];

function buildFakeSampleSuccess(spec: FakeSampleSpec): ModelDataProviderResult {
  return {
    ok: true,
    status: "succeeded",
    confidence: "official",
    normalizedSummary: spec.normalizedSummary,
    limitationCodes: [...DEFAULT_EPA_LIMITATION_CODES],
    matchQuality: "exact_make_model_year",
    sourceLabel: spec.sourceLabel,
    providerVersion: "fake-sample-v1",
    sourceMetadata: {
      providerId: "carzon_fake_model_data",
      providerVersion: "fake-sample-v1",
      fakeSample: true,
      fakeSampleId: spec.fakeSampleId,
    },
  };
}

function matchFakeSample(
  make: string,
  model: string,
  year: number,
): FakeSampleSpec | null {
  for (const spec of FAKE_SAMPLE_SPECS) {
    if (make === spec.make && model === spec.model && year === spec.year) {
      return spec;
    }
  }
  return null;
}

export class FakeModelDataProvider implements ModelDataProvider {
  readonly id = "carzon_fake_model_data";

  constructor(private readonly mode: "fake" | "fake_sample") {}

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

    if (this.mode === "fake_sample") {
      const make = foldKey(input.lookupMake);
      const model = foldKey(input.lookupModel);
      const spec = matchFakeSample(make, model, input.lookupYear);
      if (spec != null) {
        return buildFakeSampleSuccess(spec);
      }
    }

    return {
      ok: true,
      status: "no_data",
      confidence: "unknown",
      normalizedSummary: {},
      limitationCodes: [...DEFAULT_EPA_LIMITATION_CODES, "source_data_unavailable"],
      matchQuality: "no_match",
      sourceLabel: "EPA · FuelEconomy.gov (fake)",
      providerVersion: "fake-no-data-v1",
      sourceMetadata: {
        providerId: this.id,
        providerVersion: "fake-no-data-v1",
        fakeNoData: true,
      },
    };
  }
}
