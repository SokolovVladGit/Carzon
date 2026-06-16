import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildEpaMenuMatchContext,
  buildEpaModelMenuCandidateModels,
  buildEpaModelMenuCandidates,
  buildEpaProviderModelQueryMetadata,
  normalizeEpaModelKey,
} from "./epa_model_candidates.ts";

Deno.test("BMW M340i adds Sedan aliases after original", () => {
  assertEquals(buildEpaModelMenuCandidateModels("BMW", "M340i"), [
    "M340i",
    "M340i Sedan",
    "M340i xDrive Sedan",
  ]);
});

Deno.test("BMW M340 maps to M340i Sedan variants", () => {
  assertEquals(buildEpaModelMenuCandidateModels("bmw", "M340"), [
    "M340",
    "M340i Sedan",
    "M340i xDrive Sedan",
  ]);
});

Deno.test("BMW M340i xDrive prioritizes xDrive Sedan alias", () => {
  assertEquals(buildEpaModelMenuCandidateModels("BMW", "M340i xDrive"), [
    "M340i xDrive",
    "M340i xDrive Sedan",
    "M340i Sedan",
  ]);
});

Deno.test("BMW M340i Sedan does not add duplicate aliases", () => {
  assertEquals(buildEpaModelMenuCandidateModels("BMW", "M340i Sedan"), [
    "M340i Sedan",
  ]);
});

Deno.test("non-BMW models keep original only", () => {
  assertEquals(buildEpaModelMenuCandidateModels("Toyota", "Camry"), ["Camry"]);
});

Deno.test("whitespace-normalized duplicates are deduped", () => {
  assertEquals(
    buildEpaModelMenuCandidateModels("BMW", "  M340i   Sedan  "),
    ["M340i Sedan"],
  );
});

Deno.test("menu match context marks alias usage", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "BMW",
    sellerModel: "M340i",
    sellerYear: 2023,
  });
  const matched = candidates[1]!;
  const context = buildEpaMenuMatchContext(
    candidates,
    matched,
    ["M340i", "M340i Sedan"],
  );
  assertEquals(context.originalModelQuery, "M340i");
  assertEquals(context.matchedModelQuery, "M340i Sedan");
  assertEquals(context.aliasUsed, true);
});

Deno.test("provider query metadata is internal-only shape", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "BMW",
    sellerModel: "M340i",
    sellerYear: 2023,
  });
  const matched = candidates[1]!;
  const metadata = buildEpaProviderModelQueryMetadata(
    buildEpaMenuMatchContext(candidates, matched, ["M340i", "M340i Sedan"]),
    { optionCount: 1 },
  );
  assertEquals(metadata.provider_model_query_original, "M340i");
  assertEquals(metadata.provider_model_query_matched, "M340i Sedan");
  assertEquals(metadata.provider_model_alias_used, true);
  assertEquals(metadata.optionCount, 1);
});

Deno.test("case-insensitive model keys compare equal", () => {
  assertEquals(normalizeEpaModelKey(" M340I "), normalizeEpaModelKey("m340i"));
});
