import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildEpaMenuMatchContext,
  buildEpaModelMenuCandidates,
  buildEpaProviderModelQueryMetadata,
  EPA_MAX_MODEL_MENU_CANDIDATES,
  isVinIdentityCompatibleWithSeller,
  normalizeEpaModelKey,
} from "./epa_model_candidates.ts";

Deno.test("seller exact identity is first candidate", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "Toyota",
    sellerModel: "Camry",
    sellerYear: 2020,
  });
  assertEquals(candidates[0]?.source, "seller_identity");
  assertEquals(candidates[0]?.model, "Camry");
});

Deno.test("BMW M340i seller aliases follow seller identity", () => {
  assertEquals(
    buildEpaModelMenuCandidates({
      sellerMake: "BMW",
      sellerModel: "M340i",
      sellerYear: 2023,
    }).map((c) => `${c.source}:${c.model}`),
    [
      "seller_identity:M340i",
      "seller_alias:M340i Sedan",
      "seller_alias:M340i xDrive Sedan",
    ],
  );
});

Deno.test("compatible VIN decoded identity is included when model differs", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "BMW",
    sellerModel: "3 Series",
    sellerYear: 2023,
    vinHints: {
      make: "BMW",
      model: "M340i",
      year: 2023,
      body_type: "Sedan/Saloon",
    },
  });
  assertEquals(
    candidates.some((c) =>
      c.source === "vin_decoded_identity" && c.model === "M340i"
    ),
    true,
  );
});

Deno.test("generic VIN series is not used as EPA candidate", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "BMW",
    sellerModel: "M340i",
    sellerYear: 2023,
    vinHints: {
      make: "BMW",
      model: "3-Series",
      year: 2023,
      series: "3-Series",
    },
  });
  assertEquals(
    candidates.some((c) => normalizeEpaModelKey(c.model) === "3-series"),
    false,
  );
});

Deno.test("conflicting VIN make or year is ignored", () => {
  assertEquals(
    isVinIdentityCompatibleWithSeller(
      { make: "BMW", model: "M340i", year: 2023 },
      { make: "Audi", model: "M340i", year: 2023 },
    ),
    false,
  );
  assertEquals(
    isVinIdentityCompatibleWithSeller(
      { make: "BMW", model: "M340i", year: 2023 },
      { make: "BMW", model: "M340i", year: 2022 },
    ),
    false,
  );
});

Deno.test("VIN AWD drive_type prioritizes xDrive Sedan in seller_alias", () => {
  assertEquals(
    buildEpaModelMenuCandidates({
      sellerMake: "BMW",
      sellerModel: "M340i",
      sellerYear: 2023,
      vinHints: {
        make: "BMW",
        model: "M340i",
        year: 2023,
        drive_type: "All-Wheel Drive",
      },
    }).map((c) => c.model),
    ["M340i", "M340i xDrive Sedan", "M340i Sedan"],
  );
});

Deno.test("duplicate candidates are removed across sources", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "BMW",
    sellerModel: "M340i Sedan",
    sellerYear: 2023,
    vinHints: {
      make: "BMW",
      model: "M340i Sedan",
      year: 2023,
    },
  });
  assertEquals(candidates.length, 1);
});

Deno.test("max candidate count is enforced", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "BMW",
    sellerModel: "M340i",
    sellerYear: 2023,
    maxCandidates: 2,
  });
  assertEquals(candidates.length, 2);
  assertEquals(candidates.length <= EPA_MAX_MODEL_MENU_CANDIDATES, true);
});

Deno.test("metadata records identity candidate source and attempts", () => {
  const candidates = buildEpaModelMenuCandidates({
    sellerMake: "BMW",
    sellerModel: "M340i",
    sellerYear: 2023,
  });
  const matched = candidates[1]!;
  const context = buildEpaMenuMatchContext(
    candidates,
    matched,
    ["M340i", matched.model],
  );
  const metadata = buildEpaProviderModelQueryMetadata(context, {
    optionCount: 1,
  });
  assertEquals(context.identityCandidateSource, "seller_alias");
  assertEquals(metadata.identity_candidate_source, "seller_alias");
  assertEquals(metadata.candidate_attempt_count, 2);
  assertEquals(metadata.attempted_provider_models, ["M340i", "M340i Sedan"]);
});
