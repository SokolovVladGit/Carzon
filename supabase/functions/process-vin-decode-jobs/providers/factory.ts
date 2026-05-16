/**
 * Select VIN decoder implementation from CARZON_VIN_DECODER_MODE.
 */

import { FakeVinDecoderProvider } from "./fake_provider.ts";
import { NhtsaVpicVinDecoderProvider } from "./nhtsa_provider.ts";
import type { VinDecoderProvider } from "./types.ts";

export type DecoderMode = "fake" | "nhtsa";

export function normalizeDecoderMode(raw: string | undefined): DecoderMode | null {
  const v = (raw ?? "fake").trim().toLowerCase();
  if (v === "" || v === "fake") return "fake";
  if (v === "nhtsa") return "nhtsa";
  return null;
}

export function createVinDecoderProvider(mode: DecoderMode): VinDecoderProvider {
  if (mode === "nhtsa") return new NhtsaVpicVinDecoderProvider();
  return new FakeVinDecoderProvider();
}
