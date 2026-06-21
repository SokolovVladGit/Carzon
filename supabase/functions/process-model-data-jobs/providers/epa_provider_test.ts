import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { buildEpaMenuOptionsUrl } from "./epa_mapping.ts";
import {
  EpaFuelEconomyProvider,
  type EpaHttpClient,
} from "./epa_provider.ts";

const EMPTY_MENU =
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><menuItems></menuItems>';

function menuWithOption(id: string): string {
  return `<?xml version="1.0"?><menuItems><menuItem><text>cfg</text><value>${id}</value></menuItem></menuItems>`;
}

function vehicleDetailXml(id: string): string {
  return `<vehicle><id>${id}</id><city08>23</city08><highway08>31</highway08><comb08>26</comb08><co2TailpipeGpm>340</co2TailpipeGpm><fuelType>Premium</fuelType><VClass>Compact Cars</VClass></vehicle>`;
}

function modelFromMenuUrl(url: string): string | null {
  return new URL(url).searchParams.get("model");
}

function createRoutingHttp(
  menuByModel: Record<string, string>,
  detailById: Record<string, string> = {},
): { client: EpaHttpClient; requests: string[] } {
  const requests: string[] = [];
  const client: EpaHttpClient = {
    getText: async (url: string) => {
      requests.push(url);
      if (url.includes("/menu/options")) {
        const model = modelFromMenuUrl(url);
        const body = model != null ? (menuByModel[model] ?? EMPTY_MENU) : EMPTY_MENU;
        return { ok: true, status: 200, body };
      }
      const id = url.split("/").pop() ?? "";
      const body = detailById[id] ?? vehicleDetailXml(id);
      return { ok: true, status: 200, body };
    },
  };
  return { client, requests };
}

const baseInput = {
  lookupMake: "BMW",
  lookupModel: "M340i",
  lookupYear: 2023,
  sourceId: "epa_fueleconomy",
  jobId: "job-1",
  cacheKey: "cache-1",
};

Deno.test("original exact menu match succeeds without alias metadata", async () => {
  const { client, requests } = createRoutingHttp({
    Camry: menuWithOption("100"),
  }, { "100": vehicleDetailXml("100") });
  const provider = new EpaFuelEconomyProvider(client);

  const result = await provider.fetch({
    ...baseInput,
    lookupMake: "Toyota",
    lookupModel: "Camry",
    lookupYear: 2020,
  });

  assertEquals(result.ok, true);
  if (!result.ok) return;
  assertEquals(result.status, "succeeded");
  assertEquals(result.sourceMetadata.provider_model_query_original, "Camry");
  assertEquals(result.sourceMetadata.provider_model_query_matched, "Camry");
  assertEquals(result.sourceMetadata.provider_model_alias_used, false);
  assertEquals(requests.filter((u) => u.includes("/menu/options")).length, 1);
});

Deno.test("BMW M340i falls back to M340i Sedan and succeeds", async () => {
  const { client, requests } = createRoutingHttp({
    M340i: EMPTY_MENU,
    "M340i Sedan": menuWithOption("45603"),
  }, { "45603": vehicleDetailXml("45603") });
  const provider = new EpaFuelEconomyProvider(client);

  const result = await provider.fetch(baseInput);

  assertEquals(result.ok, true);
  if (!result.ok) return;
  assertEquals(result.status, "succeeded");
  assertEquals(result.sourceMetadata.provider_model_query_original, "M340i");
  assertEquals(result.sourceMetadata.provider_model_query_matched, "M340i Sedan");
  assertEquals(result.sourceMetadata.provider_model_alias_used, true);
  assertEquals(result.sourceMetadata.identity_candidate_source, "seller_alias");
  assertEquals(result.normalizedSummary.combined_mpg, 26);
  assertEquals(requests.filter((u) => u.includes("/menu/options")).length, 2);
});

Deno.test("BMW M340i xDrive tries xDrive Sedan before plain Sedan", async () => {
  const triedModels: string[] = [];
  const client: EpaHttpClient = {
    getText: async (url: string) => {
      if (url.includes("/menu/options")) {
        const model = modelFromMenuUrl(url);
        if (model != null) triedModels.push(model);
        if (model === "M340i xDrive Sedan") {
          return { ok: true, status: 200, body: menuWithOption("45493") };
        }
        return { ok: true, status: 200, body: EMPTY_MENU };
      }
      return { ok: true, status: 200, body: vehicleDetailXml("45493") };
    },
  };
  const provider = new EpaFuelEconomyProvider(client);

  const result = await provider.fetch({
    ...baseInput,
    lookupModel: "M340i xDrive",
  });

  assertEquals(result.ok, true);
  if (!result.ok) return;
  assertEquals(result.status, "succeeded");
  assertEquals(triedModels, [
    "M340i xDrive",
    "M340i xDrive Sedan",
  ]);
  assertEquals(result.sourceMetadata.provider_model_query_matched, "M340i xDrive Sedan");
});

Deno.test("does not request duplicate menu candidates", async () => {
  const { client, requests } = createRoutingHttp({
    "M340i Sedan": menuWithOption("45603"),
  }, { "45603": vehicleDetailXml("45603") });
  const provider = new EpaFuelEconomyProvider(client);

  await provider.fetch({
    ...baseInput,
    lookupModel: "M340i Sedan",
  });

  assertEquals(requests.filter((u) => u.includes("/menu/options")).length, 1);
  assert(
    requests[0]!.includes(
      encodeURIComponent("M340i Sedan"),
    ),
  );
});

Deno.test("unknown model with no aliases returns no_data", async () => {
  const { client, requests } = createRoutingHttp({
    "Unknown Widget": EMPTY_MENU,
  });
  const provider = new EpaFuelEconomyProvider(client);

  const result = await provider.fetch({
    ...baseInput,
    lookupMake: "Acme",
    lookupModel: "Unknown Widget",
  });

  assertEquals(result.ok, true);
  if (!result.ok) return;
  assertEquals(result.status, "no_data");
  assertEquals(result.matchQuality, "no_match");
  assertEquals(result.sourceMetadata.optionCount, 0);
  assertEquals(result.sourceMetadata.provider_model_alias_used, false);
  assertEquals(requests.filter((u) => u.includes("/menu/options")).length, 1);
});

Deno.test("VIN AWD hints prioritize xDrive Sedan for BMW M340i", async () => {
  const triedModels: string[] = [];
  const client: EpaHttpClient = {
    getText: async (url: string) => {
      if (url.includes("/menu/options")) {
        const model = modelFromMenuUrl(url);
        if (model != null) triedModels.push(model);
        if (model === "M340i xDrive Sedan") {
          return { ok: true, status: 200, body: menuWithOption("45493") };
        }
        return { ok: true, status: 200, body: EMPTY_MENU };
      }
      return { ok: true, status: 200, body: vehicleDetailXml("45493") };
    },
  };
  const provider = new EpaFuelEconomyProvider(client);

  const result = await provider.fetch({
    ...baseInput,
    vinHints: {
      make: "BMW",
      model: "M340i",
      year: 2023,
      drive_type: "All-Wheel Drive",
    },
  });

  assertEquals(result.ok, true);
  if (!result.ok) return;
  assertEquals(triedModels, ["M340i", "M340i xDrive Sedan"]);
  assertEquals(result.sourceMetadata.provider_model_query_matched, "M340i xDrive Sedan");
});

Deno.test("menu URL builder unchanged for exact candidate", () => {
  assertEquals(
    buildEpaMenuOptionsUrl(2023, "BMW", "M340i Sedan"),
    "https://fueleconomy.gov/ws/rest/vehicle/menu/options?year=2023&make=BMW&model=M340i%20Sedan",
  );
});
