import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  mapNhtsaVinValuesRow,
  parsePositiveIntString,
} from "./nhtsa_provider.ts";

Deno.test("parsePositiveIntString serializes valid counts as digit strings", () => {
  assertEquals(parsePositiveIntString("4"), "4");
  assertEquals(parsePositiveIntString(4), "4");
  assertEquals(parsePositiveIntString("1"), "1");
  assertEquals(parsePositiveIntString("16"), "16");
  assertEquals(parsePositiveIntString(" 5 "), "5");
  assertEquals(typeof parsePositiveIntString("4"), "string");
  assertEquals(parsePositiveIntString("4") === "$n", false);
});

Deno.test("parsePositiveIntString keeps missing and non-positive values", () => {
  assertEquals(parsePositiveIntString(null), null);
  assertEquals(parsePositiveIntString(undefined), null);
  assertEquals(parsePositiveIntString(""), null);
  assertEquals(parsePositiveIntString("   "), null);
  assertEquals(parsePositiveIntString("0"), "0");
  assertEquals(parsePositiveIntString("-1"), "-1");
  assertEquals(parsePositiveIntString("abc"), "abc");
  assertEquals(parsePositiveIntString("4 doors"), "4");
});

Deno.test("worker mapper writes Corolla counts as digits and omits EngineHP", () => {
  const { normalized } = mapNhtsaVinValuesRow({
    EngineCylinders: "4",
    Doors: "4",
    Seats: "5",
    EngineHP: "139",
    EngineHP_to: "148",
  });
  assertEquals(normalized.cylinders, "4");
  assertEquals(normalized.doors, "4");
  assertEquals(normalized.seats, "5");
  assertEquals(typeof normalized.cylinders, "string");
  assertEquals(typeof normalized.doors, "string");
  assertEquals(typeof normalized.seats, "string");
  const encoded = JSON.stringify(normalized);
  assertEquals(encoded.includes("139"), false);
  assertEquals(encoded.includes("$n"), false);
  assertEquals(Object.hasOwn(normalized, "seats"), true);
  assertEquals(Object.hasOwn(normalized, "fuelTypeSecondary"), true);
  assertEquals(Object.hasOwn(normalized, "electrificationLevel"), true);
});
