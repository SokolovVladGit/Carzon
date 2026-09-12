/**
 * Carzon — authenticated pre-listing VIN vehicle resolver.
 *
 * Suggestions only. Does not create listings, jobs, or VIN report rows.
 * Durable per-user rate limiting is a remaining production-hardening risk
 * (SQL out of scope for this phase). Mitigations: one VIN per request,
 * cache-first, no NHTSA retries, one upstream call on miss.
 *
 * Required secrets (Edge Function env; never commit / never return):
 *   - SUPABASE_URL
 *   - SUPABASE_ANON_KEY
 *   - SUPABASE_SERVICE_ROLE_KEY
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createSupabaseVinDecodeCache } from "./cache.ts";
import {
  errorResponse,
  handleResolveVehicleRequest,
  safeResolveLog,
  type AuthResult,
} from "./handler.ts";
import { decodeNhtsaVinValues } from "./nhtsa.ts";
import type { ResolveVehiclePorts } from "./resolve.ts";

function requireConfiguredEnv():
  | { ok: true; url: string; anonKey: string; serviceRoleKey: string }
  | { ok: false } {
  const url = Deno.env.get("SUPABASE_URL")?.trim();
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!url || !anonKey || !serviceRoleKey) return { ok: false };
  return { ok: true, url, anonKey, serviceRoleKey };
}

async function requireUser(
  req: Request,
  url: string,
  anonKey: string,
): Promise<AuthResult> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return { ok: false, status: 401, error: "unauthorized" };

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    return { ok: false, status: 401, error: "unauthorized" };
  }
  return { ok: true };
}

Deno.serve(async (req: Request): Promise<Response> => {
  const env = requireConfiguredEnv();
  if (!env.ok) {
    safeResolveLog("internal_error");
    return errorResponse(500, "internal_error");
  }

  const admin = createClient(env.url, env.serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const ports: ResolveVehiclePorts = {
    now: () => new Date(),
    cache: createSupabaseVinDecodeCache(admin),
    decodeNhtsa: (vinNormalized) => decodeNhtsaVinValues(vinNormalized),
    onCacheHit: () => safeResolveLog("cache_reusable"),
  };

  return await handleResolveVehicleRequest(req, {
    requireUser: (request) => requireUser(request, env.url, env.anonKey),
    ports,
  });
});
