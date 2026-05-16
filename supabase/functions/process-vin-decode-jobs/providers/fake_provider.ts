/**
 * Phase 2C fake decoder — deterministic placeholder (no external calls).
 */

import type { VinDecoderInput, VinDecoderProvider, VinDecoderResult } from "./types.ts";

export class FakeVinDecoderProvider implements VinDecoderProvider {
  readonly id = "carzon_fake_vin_decoder";

  async decode(input: VinDecoderInput): Promise<VinDecoderResult> {
    const started = performance.now();
    void input;
    return {
      ok: true,
      normalized: {
        make: null,
        model: null,
        year: null,
        bodyType: null,
        fuelType: null,
        engine: null,
        transmission: null,
        market: null,
        rawCompletenessScore: 0,
        warnings: ["fake_decoder_placeholder"],
      },
      metadata: {
        providerId: this.id,
        providerVersion: "phase2c-fake-v1",
        latencyMs: Math.round(performance.now() - started),
      },
    };
  }
}
