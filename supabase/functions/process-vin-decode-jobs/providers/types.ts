/**
 * Shared types for VIN decode providers (Phase 2C).
 * Never log the normalized VIN or keyed digest values.
 */

export type VinDecoderInput = {
  vinNormalized: string;
  jobId: string;
  listingId: string;
};

export type VinDecoderNormalizedFields = {
  make: string | null;
  model: string | null;
  year: number | null;
  bodyType: string | null;
  fuelType: string | null;
  engine: string | null;
  transmission: string | null;
  market: string | null;
  rawCompletenessScore: number;
  warnings: string[];
};

export type VinDecoderSuccessMetadata = {
  providerId: string;
  providerVersion: string;
  latencyMs: number;
  requestId?: string;
};

export type VinDecoderFailure = {
  code: string;
  safeMessage: string;
  retryable: boolean;
  httpStatus?: number;
};

export type VinDecoderResult =
  | {
    ok: true;
    normalized: VinDecoderNormalizedFields;
    metadata: VinDecoderSuccessMetadata;
  }
  | {
    ok: false;
    error: VinDecoderFailure;
  };

export interface VinDecoderProvider {
  readonly id: string;
  decode(input: VinDecoderInput): Promise<VinDecoderResult>;
}
