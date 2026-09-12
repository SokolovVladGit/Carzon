/**
 * VIN normalize / syntax / hash — compatible with
 * carzon_normalize_vin_input, carzon_normalized_vin_syntax_ok,
 * carzon_sha256_hex_utf8 (encode(digest(convert_to(utf8),'sha256'),'hex')).
 */

const VIN_SYNTAX = /^[A-HJ-NPR-Z0-9]{17}$/;

export function normalizeVinInput(raw: string): string {
  return raw.trim().replaceAll(" ", "").replaceAll("-", "").toUpperCase();
}

export function isNormalizedVinSyntaxOk(normalized: string): boolean {
  return normalized.length === 17 && VIN_SYNTAX.test(normalized);
}

/** SHA-256 hex of UTF-8 bytes — same contract as public.carzon_sha256_hex_utf8. */
export async function sha256HexUtf8(plain: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(plain),
  );
  return Array.from(new Uint8Array(digest), (b) =>
    b.toString(16).padStart(2, "0"),
  ).join("");
}

export type VinParseOk = { ok: true; normalized: string };
export type VinParseErr = { ok: false; error: "invalid_vin" };

export function parseResolverVin(raw: string): VinParseOk | VinParseErr {
  const normalized = normalizeVinInput(raw);
  if (!isNormalizedVinSyntaxOk(normalized)) {
    return { ok: false, error: "invalid_vin" };
  }
  return { ok: true, normalized };
}
