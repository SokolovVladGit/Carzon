import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

const FILES = [
  "index.ts",
  "handler.ts",
  "resolve.ts",
  "nhtsa.ts",
  "vin.ts",
  "cache.ts",
];

function read(name: string): string {
  return Deno.readTextFileSync(new URL(`./${name}`, import.meta.url));
}

Deno.test("resolver sources never console.log", () => {
  for (const name of FILES) {
    const text = read(name).toLowerCase();
    assertEquals(text.includes("console.log"), false, name);
  }
});

Deno.test("resolver sources do not interpolate vin or hash into logs", () => {
  for (const name of FILES) {
    const text = read(name);
    assertEquals(text.includes("${vin"), false, name);
    assertEquals(text.includes("${vinHash"), false, name);
    assertEquals(text.includes("${vin_hash"), false, name);
    assertEquals(text.includes("`vin_hash"), false, name);
  }
});

Deno.test("index never returns or logs service-role material", () => {
  const index = read("index.ts");
  assertEquals(index.includes("serviceRoleKey"), true);
  assertEquals(index.includes("jsonResponse") && index.includes("SERVICE_ROLE"), false);
  assertEquals(index.toLowerCase().includes("console.log"), false);
  assertEquals(index.includes("Deno.env.get(\"SUPABASE_SERVICE_ROLE_KEY\")"), true);
});
