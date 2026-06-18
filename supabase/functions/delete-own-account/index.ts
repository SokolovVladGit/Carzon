/**
 * Carzon — authenticated self-service account deletion.
 *
 * Verifies the caller JWT, runs `public.delete_own_account()` (listing + storage
 * cleanup), then removes the auth user via `auth.admin.deleteUser`.
 *
 * Required secrets (Supabase Edge Function settings):
 *   - SUPABASE_URL
 *   - SUPABASE_ANON_KEY
 *   - SUPABASE_SERVICE_ROLE_KEY
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const SUPPORT_EMAIL = "admin@carzon.com";

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse(500, { error: "server_misconfigured" });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse(401, { error: "missing_authorization" });
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  const user = userData.user;
  if (userError || !user) {
    return jsonResponse(401, { error: "invalid_session" });
  }

  const email = user.email?.trim().toLowerCase() ?? "";
  if (email === SUPPORT_EMAIL.toLowerCase()) {
    return jsonResponse(403, { error: "account_cannot_be_self_deleted" });
  }

  const { error: rpcError } = await userClient.rpc("delete_own_account");
  if (rpcError) {
    console.error("delete_own_account RPC failed");
    return jsonResponse(500, { error: "account_data_cleanup_failed" });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error("auth.admin.deleteUser failed");
    return jsonResponse(500, { error: "auth_user_deletion_failed" });
  }

  return jsonResponse(200, { deleted: true });
});
