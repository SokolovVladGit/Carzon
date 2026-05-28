/**
 * Carzon — Phase 3A: process queued message notification events (FCM HTTP v1).
 *
 * Invoked only with header `x-carzon-internal-secret` matching
 * `CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`.
 *
 * Required secrets (set in Supabase Edge Function settings; never commit):
 *   - SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET
 *   - FCM_PROJECT_ID (or `project_id` inside FCM_SERVICE_ACCOUNT_JSON)
 *   - FCM_CLIENT_EMAIL + FCM_PRIVATE_KEY
 *     OR a single FCM_SERVICE_ACCOUNT_JSON (service account key JSON)
 *
 * Does not send full message body, email, or filter-alert content.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { JWT } from "npm:google-auth-library@9.14.2";
import { messageNotificationCopyForLocale } from "../_shared/push_notification_copy.ts";

const MAX_SEND_ATTEMPTS = 8;
const DEFAULT_BATCH = 25;

type DeliveryEvent = {
  id: string;
  recipient_user_id: string;
  actor_user_id: string | null;
  conversation_id: string | null;
  message_id: string | null;
  listing_id: string | null;
  payload: Record<string, unknown> | null;
  attempts: number;
};

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function loadServiceAccount():
  | { clientEmail: string; privateKey: string; projectId: string | null }
  | null {
  const rawJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (rawJson && rawJson.trim().length > 0) {
    try {
      const o = JSON.parse(rawJson) as {
        client_email?: string;
        private_key?: string;
        project_id?: string;
      };
      if (!o.client_email || !o.private_key) return null;
      return {
        clientEmail: o.client_email,
        privateKey: o.private_key,
        projectId: o.project_id ?? null,
      };
    } catch {
      return null;
    }
  }
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL")?.trim();
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY");
  if (!clientEmail || !privateKey) return null;
  return { clientEmail, privateKey, projectId: null };
}

async function getFcmAccessToken(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const jwt = new JWT({
    email: clientEmail,
    key: privateKey.replace(/\\n/g, "\n"),
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const tok = await jwt.authorize();
  if (!tok.access_token) {
    throw new Error("Google OAuth returned no access_token for FCM");
  }
  return tok.access_token;
}

async function sendFcmToToken(params: {
  projectId: string;
  accessToken: string;
  deviceToken: string;
  title: string;
  body: string;
  data: Record<string, string>;
}): Promise<{ ok: boolean; messageId?: string; errorCode?: string; errorMessage?: string }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${params.projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${params.accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: params.deviceToken,
          notification: {
            title: params.title,
            body: params.body,
          },
          data: params.data,
          android: { priority: "HIGH" },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default" } },
          },
        },
      }),
    },
  );

  const text = await res.text();
  if (res.ok) {
    try {
      const j = JSON.parse(text) as { name?: string };
      return { ok: true, messageId: j.name };
    } catch {
      return { ok: true, messageId: undefined };
    }
  }

  let errorCode: string | undefined;
  let errorMessage: string | undefined;
  try {
    const j = JSON.parse(text) as {
      error?: { status?: string; message?: string; details?: Array<{ errorCode?: string }> };
    };
    errorMessage = j.error?.message ?? text.slice(0, 500);
    errorCode = j.error?.details?.[0]?.errorCode ?? j.error?.status;
  } catch {
    errorMessage = text.slice(0, 500);
  }
  return { ok: false, errorCode, errorMessage };
}

function shouldDeactivateToken(errorCode?: string, errorMessage?: string): boolean {
  const code = (errorCode ?? "").toUpperCase();
  const msg = (errorMessage ?? "").toUpperCase();
  if (
    code.includes("UNREGISTERED") ||
    code.includes("NOT_FOUND") ||
    code.includes("INVALID_ARGUMENT")
  ) return true;
  if (msg.includes("NOT_REGISTERED") || msg.includes("UNREGISTERED")) return true;
  return false;
}

function dataPayload(event: DeliveryEvent): Record<string, string> {
  const d: Record<string, string> = {
    type: "message",
  };
  if (event.conversation_id) d.conversation_id = event.conversation_id;
  if (event.message_id) d.message_id = event.message_id;
  if (event.listing_id) d.listing_id = event.listing_id;
  return d;
}

Deno.serve(async (req: Request): Promise<Response> => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const expectedSecret = Deno.env.get("CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET");
    const header = req.headers.get("x-carzon-internal-secret");
    if (!expectedSecret || header !== expectedSecret) {
      console.warn("process-message-notifications: unauthorized invoke attempt");
      return jsonResponse(401, { error: "unauthorized" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
      return jsonResponse(500, { error: "supabase_env_missing" });
    }

    const sa = loadServiceAccount();
    const projectId = Deno.env.get("FCM_PROJECT_ID")?.trim() ||
      (sa?.projectId?.trim() ?? "");

    if (!sa || !projectId) {
      console.error(
        "FCM not configured (need FCM_SERVICE_ACCOUNT_JSON or FCM_PROJECT_ID + FCM_CLIENT_EMAIL + FCM_PRIVATE_KEY)",
      );
      return jsonResponse(503, { error: "fcm_not_configured" });
    }

    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    let accessToken: string;
    try {
      accessToken = await getFcmAccessToken(sa.clientEmail, sa.privateKey);
    } catch (e) {
      console.error("FCM OAuth failed", e);
      return jsonResponse(503, { error: "fcm_oauth_failed" });
    }

    // DB migration Phase 4A scopes this RPC to `message_created` only (filter
    // alerts use a separate claim + Edge Function).
    const { data: claimed, error: claimError } = await supabase.rpc(
      "claim_notification_events_for_processing",
      { p_limit: DEFAULT_BATCH },
    );

    if (claimError) {
      console.error("claim_notification_events_for_processing", claimError);
      return jsonResponse(500, { error: "claim_failed", detail: claimError.message });
    }

    const events = (claimed ?? []) as DeliveryEvent[];

    for (const event of events) {
      if (
        !event.recipient_user_id || !event.actor_user_id ||
        event.recipient_user_id === event.actor_user_id
      ) {
        await supabase.from("notification_delivery_events").update({
          status: "skipped",
          processed_at: new Date().toISOString(),
          locked_at: null,
          last_error: "invalid_recipient_or_actor",
        }).eq("id", event.id);
        continue;
      }

      const { data: prefRow } = await supabase
        .from("notification_preferences")
        .select("global_enabled, messages_enabled")
        .eq("user_id", event.recipient_user_id)
        .maybeSingle();

      const globalOn = prefRow?.global_enabled === true;
      const messagesOn = prefRow?.messages_enabled === true;
      if (!globalOn || !messagesOn) {
        await supabase.from("notification_delivery_events").update({
          status: "skipped",
          processed_at: new Date().toISOString(),
          locked_at: null,
          last_error: "notification_preferences_off",
        }).eq("id", event.id);
        continue;
      }

      const { data: tokens, error: tokErr } = await supabase
        .from("user_push_tokens")
        .select("id, token, locale")
        .eq("user_id", event.recipient_user_id)
        .eq("is_active", true);

      if (tokErr) {
        console.error("user_push_tokens select", tokErr);
        await requeueOrFail(supabase, event, "token_query_failed");
        continue;
      }

      if (!tokens || tokens.length === 0) {
        await supabase.from("notification_delivery_events").update({
          status: "skipped",
          processed_at: new Date().toISOString(),
          locked_at: null,
          last_error: "no_active_push_tokens",
        }).eq("id", event.id);
        continue;
      }

      const stringData = dataPayload(event);
      let anySuccess = false;
      let lastErr = "";

      for (const row of tokens) {
        const copy = messageNotificationCopyForLocale(
          (row as { locale?: string | null }).locale,
        );
        const send = await sendFcmToToken({
          projectId,
          accessToken,
          deviceToken: row.token,
          title: copy.title,
          body: copy.body,
          data: stringData,
        });

        await supabase.from("notification_delivery_attempts").insert({
          event_id: event.id,
          recipient_user_id: event.recipient_user_id,
          token_id: row.id,
          provider: "fcm",
          status: send.ok ? "success" : "failed",
          provider_message_id: send.messageId ?? null,
          error_code: send.errorCode ?? null,
          error_message: send.errorMessage ?? null,
        });

        if (send.ok) {
          anySuccess = true;
        } else {
          lastErr = send.errorMessage ?? send.errorCode ?? "send_failed";
          if (shouldDeactivateToken(send.errorCode, send.errorMessage)) {
            await supabase.from("user_push_tokens").update({
              is_active: false,
              updated_at: new Date().toISOString(),
            }).eq("id", row.id);
          }
        }
      }

      if (anySuccess) {
        await supabase.from("notification_delivery_events").update({
          status: "sent",
          processed_at: new Date().toISOString(),
          locked_at: null,
          last_error: null,
        }).eq("id", event.id);
      } else {
        await requeueOrFail(supabase, event, lastErr || "all_tokens_failed");
      }
    }

    return jsonResponse(200, { ok: true, claimed: events.length });
  } catch (e) {
    console.error("process-message-notifications fatal", e);
    return jsonResponse(500, { error: "internal_error" });
  }
});

async function requeueOrFail(
  supabase: ReturnType<typeof createClient>,
  event: DeliveryEvent,
  lastError: string,
): Promise<void> {
  if (event.attempts >= MAX_SEND_ATTEMPTS) {
    await supabase.from("notification_delivery_events").update({
      status: "failed",
      processed_at: new Date().toISOString(),
      locked_at: null,
      last_error: lastError.slice(0, 2000),
    }).eq("id", event.id);
    return;
  }

  const backoffSec = Math.min(900, 45 * Math.pow(2, Math.max(0, event.attempts - 1)));
  const next = new Date(Date.now() + backoffSec * 1000).toISOString();

  await supabase.from("notification_delivery_events").update({
    status: "pending",
    locked_at: null,
    last_error: lastError.slice(0, 2000),
    next_attempt_at: next,
  }).eq("id", event.id);
}
