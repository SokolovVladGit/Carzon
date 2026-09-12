import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  isNormalizedVinSyntaxOk,
  normalizeVinInput,
  parseResolverVin,
  sha256HexUtf8,
} from "./vin.ts";

// Public syntactic sample (also used by Flutter ListingVin tests). Not hosted data.
const SAMPLE_NORMALIZED = "1HGBH41JXMN109186";
// encode(digest(convert_to(utf8,'UTF8'),'sha256'),'hex') for SAMPLE_NORMALIZED
const SAMPLE_SHA256_HEX =
  "8e7f861771044a74b815000e193c0fd8a5fae4b6c597c963cb9da7aa522b41e6";

Deno.test("normalizeVinInput trims, strips spaces/hyphens, uppercases", () => {
  assertEquals(normalizeVinInput("  1hgbh41-jx mn109186  "), SAMPLE_NORMALIZED);
});

Deno.test("normalizeVinInput matches SQL replace space/hyphen only", () => {
  assertEquals(normalizeVinInput("abc-def ghi"), "ABCDEFGHI");
});

Deno.test("syntax accepts 17-char charset without I/O/Q", () => {
  assertEquals(isNormalizedVinSyntaxOk(SAMPLE_NORMALIZED), true);
});

Deno.test("syntax rejects wrong length", () => {
  assertEquals(isNormalizedVinSyntaxOk("1HGBH41JXMN10918"), false);
  assertEquals(isNormalizedVinSyntaxOk(""), false);
});

Deno.test("syntax rejects I O Q", () => {
  assertEquals(isNormalizedVinSyntaxOk("1HGBH41JXON109186"), false);
  assertEquals(isNormalizedVinSyntaxOk("1HGBH41JXMN10918I"), false);
  assertEquals(isNormalizedVinSyntaxOk("1HGBH41JXMN10918Q"), false);
});

Deno.test("parseResolverVin rejects blank and invalid", () => {
  assertEquals(parseResolverVin("   ").ok, false);
  assertEquals(parseResolverVin("not-a-vin").ok, false);
  assertEquals(parseResolverVin(SAMPLE_NORMALIZED), {
    ok: true,
    normalized: SAMPLE_NORMALIZED,
  });
});

Deno.test("sha256HexUtf8 matches carzon_sha256_hex_utf8 convention", async () => {
  assertEquals(await sha256HexUtf8(SAMPLE_NORMALIZED), SAMPLE_SHA256_HEX);
  assertEquals(SAMPLE_SHA256_HEX.length, 64);
});

Deno.test("sha256HexUtf8 is deterministic and UTF-8 based", async () => {
  const a = await sha256HexUtf8("ABC");
  const b = await sha256HexUtf8("ABC");
  assertEquals(a, b);
  const other = await sha256HexUtf8("ABD");
  assertEquals(other === a, false);
});

Deno.test("sha256HexUtf8 does not throw on empty string", async () => {
  const hex = await sha256HexUtf8("");
  assertEquals(hex.length, 64);
});
