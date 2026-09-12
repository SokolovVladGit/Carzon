import type { VinDecodeCachePort, CacheReadRow, CacheWriteRow } from "./resolve.ts";

type SupabaseCacheClient = {
  // supabase-js builders are thenable; keep this port runtime-shaped only.
  from(table: string): {
    select(columns: string): {
      eq(
        column: string,
        value: string,
      ): {
        maybeSingle(): PromiseLike<{
          data: CacheReadRow | null;
          error: { message?: string } | null;
        }>;
      };
    };
    upsert(
      row: CacheWriteRow,
      options: { onConflict: string },
    ): PromiseLike<{ error: { message?: string } | null }>;
  };
};

const CACHE_TABLE = "vin_decode_cache";
const READ_COLUMNS = "decode_status, ttl_until, normalized_data";

export function createSupabaseVinDecodeCache(
  client: SupabaseCacheClient,
): VinDecodeCachePort {
  return {
    async readByHash(vinHash) {
      const { data, error } = await client
        .from(CACHE_TABLE)
        .select(READ_COLUMNS)
        .eq("vin_hash", vinHash)
        .maybeSingle();
      if (error) throw new Error("cache_read_failed");
      if (!data) return null;
      const normalized = data.normalized_data;
      return {
        decode_status: data.decode_status,
        ttl_until: data.ttl_until,
        normalized_data:
          normalized != null && typeof normalized === "object" &&
            !Array.isArray(normalized)
            ? normalized as Record<string, unknown>
            : null,
      };
    },

    async upsertDecoded(row) {
      const { error } = await client.from(CACHE_TABLE).upsert(row, {
        onConflict: "vin_hash",
      });
      if (error) throw new Error("cache_write_failed");
    },
  };
}
