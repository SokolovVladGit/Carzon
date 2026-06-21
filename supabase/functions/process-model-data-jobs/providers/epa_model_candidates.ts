/**
 * Deterministic EPA Model Passport menu candidate resolver (no HTTP, no fuzzy/LLM match).
 */

export const EPA_MAX_MODEL_MENU_CANDIDATES = 5;

export type EpaModelCandidateSource =
  | "seller_identity"
  | "seller_alias"
  | "vin_decoded_identity"
  | "vin_alias";

export type VinModelFetchHints = {
  make?: string | null;
  model?: string | null;
  year?: number | null;
  body_type?: string | null;
  series?: string | null;
  trim?: string | null;
  drive_type?: string | null;
};

export type EpaModelMenuCandidate = {
  make: string;
  model: string;
  year: number;
  source: EpaModelCandidateSource;
};

export type EpaModelCandidateBuildInput = {
  sellerMake: string;
  sellerModel: string;
  sellerYear: number;
  vinHints?: VinModelFetchHints | null;
  maxCandidates?: number;
};

export type EpaMenuMatchContext = {
  originalModelQuery: string;
  matchedModelQuery: string;
  aliasUsed: boolean;
  identityCandidateSource: EpaModelCandidateSource;
  candidateAttemptCount: number;
  attemptedProviderModels: string[];
};

export function normalizeEpaMakeKey(make: string): string {
  return make.trim().replace(/\s+/g, " ").toLowerCase();
}

export function normalizeEpaModelKey(model: string): string {
  return model.trim().replace(/\s+/g, " ").toLowerCase();
}

function normalizeModelLabel(model: string): string {
  return model.trim().replace(/\s+/g, " ");
}

function modelKeyContainsXDrive(modelKey: string): boolean {
  return modelKey.includes("xdrive");
}

function driveTypeSuggestsXDrive(driveType: string | null | undefined): boolean {
  if (driveType == null) return false;
  const value = driveType.trim().toLowerCase();
  return value.includes("xdrive") ||
    value.includes("all-wheel") ||
    value.includes("all wheel") ||
    value.includes("awd") ||
    value.includes("4wd");
}

function isGenericSeriesModel(modelKey: string): boolean {
  if (modelKey === "3 series" || modelKey === "3-series") return true;
  return /\bseries$/.test(modelKey) && !modelKey.startsWith("m");
}

function parsePositiveInt(value: unknown): number | null {
  if (typeof value === "number" && Number.isInteger(value) && value >= 1900) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number.parseInt(value.trim(), 10);
    if (Number.isInteger(parsed) && parsed >= 1900) return parsed;
  }
  return null;
}

export function isVinIdentityCompatibleWithSeller(
  seller: { make: string; model: string; year: number },
  vin: VinModelFetchHints,
): boolean {
  const vinMake = vin.make?.trim();
  const vinModel = vin.model?.trim();
  const vinYear = parsePositiveInt(vin.year);
  if (vinMake == null || vinMake.length === 0) return false;
  if (vinModel == null || vinModel.length === 0) return false;
  if (vinYear == null) return false;
  if (normalizeEpaMakeKey(vinMake) !== normalizeEpaMakeKey(seller.make)) {
    return false;
  }
  return vinYear === seller.year;
}

type AliasContext = {
  preferXDrive?: boolean;
};

type CandidateCollector = {
  add: (
    make: string,
    model: string,
    year: number,
    source: EpaModelCandidateSource,
  ) => void;
};

function candidateKey(make: string, model: string, year: number): string {
  return `${normalizeEpaMakeKey(make)}|${normalizeEpaModelKey(model)}|${year}`;
}

function appendDeterministicProviderAliases(
  makeKey: string,
  modelKey: string,
  addModel: (model: string) => void,
  context: AliasContext = {},
): void {
  if (makeKey !== "bmw") return;

  const sedan = "M340i Sedan";
  const xDriveSedan = "M340i xDrive Sedan";
  const preferXDrive = context.preferXDrive === true ||
    modelKeyContainsXDrive(modelKey);

  if (modelKey === "m340i" || modelKey === "m340") {
    if (preferXDrive) {
      addModel(xDriveSedan);
      addModel(sedan);
    } else {
      addModel(sedan);
      addModel(xDriveSedan);
    }
    return;
  }

  if (modelKey === "m340i xdrive") {
    addModel(xDriveSedan);
    addModel(sedan);
  }
}

function expandAliasCandidates(
  make: string,
  model: string,
  year: number,
  source: "seller_alias" | "vin_alias",
  collector: CandidateCollector,
  context: AliasContext = {},
): void {
  const makeKey = normalizeEpaMakeKey(make);
  const modelKey = normalizeEpaModelKey(model);
  if (isGenericSeriesModel(modelKey)) return;

  const addModel = (candidateModel: string) => {
    collector.add(make, candidateModel, year, source);
  };

  appendDeterministicProviderAliases(makeKey, modelKey, addModel, context);
}

/**
 * Ordered unique EPA menu candidates for provider lookup.
 */
export function buildEpaModelMenuCandidates(
  input: EpaModelCandidateBuildInput,
): EpaModelMenuCandidate[] {
  const maxCandidates = input.maxCandidates ?? EPA_MAX_MODEL_MENU_CANDIDATES;
  const sellerMake = input.sellerMake.trim();
  const sellerModel = normalizeModelLabel(input.sellerModel);
  const sellerYear = input.sellerYear;

  const ordered: EpaModelMenuCandidate[] = [];
  const seen = new Set<string>();

  const collector: CandidateCollector = {
    add: (make, model, year, source) => {
      if (ordered.length >= maxCandidates) return;
      const normalizedModel = normalizeModelLabel(model);
      if (!normalizedModel) return;
      const key = candidateKey(make, normalizedModel, year);
      if (seen.has(key)) return;
      seen.add(key);
      ordered.push({
        make: make.trim(),
        model: normalizedModel,
        year,
        source,
      });
    },
  };

  collector.add(sellerMake, sellerModel, sellerYear, "seller_identity");

  const vin = input.vinHints;
  const vinCompatible = vin != null &&
    isVinIdentityCompatibleWithSeller(
      { make: sellerMake, model: sellerModel, year: sellerYear },
      vin,
    );
  const preferXDriveFromVin = vinCompatible &&
    driveTypeSuggestsXDrive(vin!.drive_type);

  expandAliasCandidates(
    sellerMake,
    sellerModel,
    sellerYear,
    "seller_alias",
    collector,
    { preferXDrive: preferXDriveFromVin },
  );

  if (vinCompatible) {
    const vinMake = vin!.make!.trim();
    const vinModel = normalizeModelLabel(vin!.model!);
    const vinYear = parsePositiveInt(vin!.year)!;
    const vinModelKey = normalizeEpaModelKey(vinModel);

    if (!isGenericSeriesModel(vinModelKey) &&
      vinModelKey !== normalizeEpaModelKey(sellerModel)) {
      collector.add(vinMake, vinModel, vinYear, "vin_decoded_identity");
      expandAliasCandidates(
        vinMake,
        vinModel,
        vinYear,
        "vin_alias",
        collector,
        { preferXDrive: driveTypeSuggestsXDrive(vin!.drive_type) },
      );
    } else if (!isGenericSeriesModel(vinModelKey)) {
      expandAliasCandidates(
        vinMake,
        vinModel,
        vinYear,
        "vin_alias",
        collector,
        { preferXDrive: driveTypeSuggestsXDrive(vin!.drive_type) },
      );
    }
  }

  return ordered;
}

/** @deprecated Use buildEpaModelMenuCandidates. Kept for legacy call sites/tests. */
export function buildEpaModelMenuCandidateModels(
  make: string,
  model: string,
): string[] {
  return buildEpaModelMenuCandidates({
    sellerMake: make,
    sellerModel: model,
    sellerYear: 2020,
    maxCandidates: EPA_MAX_MODEL_MENU_CANDIDATES,
  }).map((candidate) => candidate.model);
}

export function buildEpaMenuMatchContext(
  candidates: EpaModelMenuCandidate[],
  matched: EpaModelMenuCandidate,
  attemptedProviderModels: string[],
): EpaMenuMatchContext {
  const original = candidates.find((c) => c.source === "seller_identity") ??
    candidates[0] ?? matched;
  return {
    originalModelQuery: original.model,
    matchedModelQuery: matched.model,
    aliasUsed: normalizeEpaModelKey(matched.model) !==
      normalizeEpaModelKey(original.model),
    identityCandidateSource: matched.source,
    candidateAttemptCount: attemptedProviderModels.length,
    attemptedProviderModels,
  };
}

export function buildEpaProviderModelQueryMetadata(
  context: EpaMenuMatchContext,
  extra: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    provider_model_query_original: context.originalModelQuery,
    provider_model_query_matched: context.matchedModelQuery,
    provider_model_alias_used: context.aliasUsed,
    identity_candidate_source: context.identityCandidateSource,
    candidate_attempt_count: context.candidateAttemptCount,
    attempted_provider_models: context.attemptedProviderModels,
    ...extra,
  };
}
