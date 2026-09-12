/**
 * HTTP adapter for resolve-vehicle.
 * Never logs VIN, VIN hash, raw provider bodies, or secrets.
 */

import {
  resolveVehicleFromVin,
  type ResolveVehiclePorts,
  type PublicResolveSuccess,
} from "./resolve.ts";

export type JsonErrorCode =
  | "invalid_request"
  | "invalid_vin"
  | "unauthorized"
  | "method_not_allowed"
  | "upstream_timeout"
  | "upstream_unavailable"
  | "internal_error";

export type SafeLogEvent =
  | "unauthorized"
  | "invalid_request"
  | "invalid_vin"
  | "cache_reusable"
  | "provider_timeout"
  | "provider_unavailable"
  | "internal_error";

const SAFE_LOG_EVENTS: ReadonlySet<string> = new Set([
  "unauthorized",
  "invalid_request",
  "invalid_vin",
  "cache_reusable",
  "provider_timeout",
  "provider_unavailable",
  "internal_error",
]);

export function safeResolveLog(event: SafeLogEvent): void {
  if (!SAFE_LOG_EVENTS.has(event)) return;
  console.info(`resolve-vehicle: ${event}`);
}

export function jsonResponse(
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export function errorResponse(status: number, error: JsonErrorCode): Response {
  return jsonResponse(status, { ok: false, error });
}

export type AuthResult =
  | { ok: true }
  | { ok: false; status: number; error: "unauthorized" };

export type ResolveVehicleHttpDeps = {
  requireUser: (req: Request) => Promise<AuthResult>;
  ports: ResolveVehiclePorts;
  log?: (event: SafeLogEvent) => void;
};

function statusForResolveError(
  error: "invalid_vin" | "upstream_timeout" | "upstream_unavailable" | "internal_error",
): number {
  switch (error) {
    case "invalid_vin":
      return 400;
    case "upstream_timeout":
      return 504;
    case "upstream_unavailable":
      return 502;
    case "internal_error":
      return 500;
  }
}

export async function parseVinRequestBody(
  req: Request,
): Promise<{ ok: true; vin: string } | { ok: false; error: "invalid_request" }> {
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return { ok: false, error: "invalid_request" };
  }
  if (raw == null || typeof raw !== "object" || Array.isArray(raw)) {
    return { ok: false, error: "invalid_request" };
  }
  const keys = Object.keys(raw as Record<string, unknown>);
  if (keys.length !== 1 || keys[0] !== "vin") {
    return { ok: false, error: "invalid_request" };
  }
  const vin = (raw as { vin: unknown }).vin;
  if (typeof vin !== "string") {
    return { ok: false, error: "invalid_request" };
  }
  return { ok: true, vin };
}

export async function handleResolveVehicleRequest(
  req: Request,
  deps: ResolveVehicleHttpDeps,
): Promise<Response> {
  const log = deps.log ?? safeResolveLog;

  if (req.method !== "POST") {
    return errorResponse(405, "method_not_allowed");
  }

  const auth = await deps.requireUser(req);
  if (!auth.ok) {
    log("unauthorized");
    return errorResponse(auth.status, "unauthorized");
  }

  const parsed = await parseVinRequestBody(req);
  if (!parsed.ok) {
    log("invalid_request");
    return errorResponse(400, "invalid_request");
  }

  const outcome = await resolveVehicleFromVin(parsed.vin, deps.ports);
  if (!outcome.ok) {
    if (outcome.error === "invalid_vin") log("invalid_vin");
    if (outcome.error === "upstream_timeout") log("provider_timeout");
    if (outcome.error === "upstream_unavailable") log("provider_unavailable");
    if (outcome.error === "internal_error") log("internal_error");
    return errorResponse(statusForResolveError(outcome.error), outcome.error);
  }

  const body: PublicResolveSuccess = outcome;
  return jsonResponse(200, body);
}
