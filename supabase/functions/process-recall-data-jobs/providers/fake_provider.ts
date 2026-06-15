/**
 * Fake recall provider — deterministic, non-production.
 *
 * Default: always no_data (safe for hosted cron before NHTSA rollout).
 * fake_sample: deterministic campaigns for Toyota Camry 2020 QA only.
 */

import type {
  RecallCampaignSummary,
  RecallFetchInput,
  RecallProvider,
  RecallProviderResult,
} from "./types.ts";
import {
  DEFAULT_RECALL_LIMITATION_CODES,
  NHTSA_RECALLS_SOURCE_LABEL,
} from "./types.ts";
import {
  buildRecallNoDataResult,
  buildRecallNormalizedSummary,
} from "./nhtsa_mapping.ts";

function foldKey(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, " ");
}

type FakeSampleSpec = {
  make: string;
  model: string;
  year: number;
  campaigns: RecallCampaignSummary[];
  sourceLabel: string;
  fakeSampleId: string;
};

const SAMPLE_CAMPAIGN_ONE: RecallCampaignSummary = {
  campaign_number: "20V000",
  manufacturer: "Toyota Motor Corporation",
  component: "AIR BAGS",
  summary:
    "Sample campaign: front passenger air bag inflator may rupture (QA fixture only).",
  consequence:
    "Sample consequence text for QA; not a live recall determination.",
  remedy:
    "Sample remedy text for QA; dealers would replace inflator in a real campaign.",
  notes: "Carzon fake_sample fixture — model/year campaigns only.",
  report_received_date: "2020-01-15",
  nhtsa_action_number: "FA",
  park_it: false,
  park_outside: false,
  over_the_air_update: false,
  model_year: 2020,
  make: "TOYOTA",
  model: "Camry",
};

const SAMPLE_CAMPAIGN_TWO: RecallCampaignSummary = {
  campaign_number: "20V001",
  manufacturer: "Toyota Motor Corporation",
  component: "FUEL SYSTEM, GASOLINE",
  summary: "Sample campaign: fuel pump may fail (QA fixture only).",
  consequence: "Sample consequence text for QA.",
  remedy: "Sample remedy text for QA.",
  notes: "Carzon fake_sample fixture.",
  report_received_date: "2020-03-01",
  nhtsa_action_number: "FB",
  park_it: false,
  park_outside: false,
  over_the_air_update: false,
  model_year: 2020,
  make: "TOYOTA",
  model: "Camry",
};

const FAKE_SAMPLE_SPECS: FakeSampleSpec[] = [
  {
    make: "toyota",
    model: "camry",
    year: 2020,
    fakeSampleId: "fake-sample-2020-camry-recalls",
    sourceLabel: "NHTSA (fake sample)",
    campaigns: [SAMPLE_CAMPAIGN_ONE, SAMPLE_CAMPAIGN_TWO],
  },
];

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

function buildFakeSampleSuccess(spec: FakeSampleSpec): RecallProviderResult {
  return {
    ok: true,
    status: "succeeded",
    normalizedSummary: buildRecallNormalizedSummary(
      spec.campaigns,
      "exact_make_model_year",
    ),
    limitationCodes: [...DEFAULT_RECALL_LIMITATION_CODES],
    matchQuality: "exact_make_model_year",
    sourceLabel: spec.sourceLabel,
    sourceUpdatedAt: "2020-03-01",
    sourceMetadata: {
      providerId: "carzon_fake_recall_data",
      providerVersion: "fake-sample-v1",
      fakeSample: true,
      fakeSampleId: spec.fakeSampleId,
    },
  };
}

export class FakeRecallProvider implements RecallProvider {
  readonly id = "carzon_fake_recall_data";

  constructor(private readonly mode: "fake" | "fake_sample") {}

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

    if (this.mode === "fake_sample") {
      const make = foldKey(input.lookupMake);
      const model = foldKey(input.lookupModel);
      const spec = matchFakeSample(make, model, input.lookupYear);
      if (spec != null) {
        return buildFakeSampleSuccess(spec);
      }
    }

    return {
      ...buildRecallNoDataResult("no_match"),
      sourceLabel: `${NHTSA_RECALLS_SOURCE_LABEL} (fake)`,
      sourceMetadata: {
        providerId: this.id,
        providerVersion: "fake-no-data-v1",
        fakeNoData: true,
      },
    };
  }
}
