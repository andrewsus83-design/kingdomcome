// ============================================================
// Edge Function: unlock-saint
// Atomically unlocks a saint for a user by:
//   1. Validating JWT
//   2. Calling unlock_saint_atomic RPC (validates monastery level
//      and holy_points balance, deducts cost, inserts user_saints)
//   3. Optionally setting the unlocked saint as the active saint
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

// ─── Types ───────────────────────────────────────────────────

interface UnlockSaintRequest {
  saint_id: string;
  set_as_active?: boolean; // If true, immediately set as active saint after unlock
}

interface UnlockSaintResult {
  success: boolean;
  error?: string;
  detail?: string;
  saint_id?: string;
  saint_name?: string;
  cost_paid?: number;
  holy_points_remaining?: number;
  required_level?: number;
  current_level?: number;
  have?: number;
  need?: number;
}

interface ActivateSaintResult {
  success: boolean;
  error?: string;
  ability_ends_at?: string;
  duration_hours?: number;
  cooldown_ends_at?: string;
}

// ─── CORS ─────────────────────────────────────────────────────

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function isValidUUID(str: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    .test(str);
}

// ─── Main handler ─────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // ── 1. Authenticate ─────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "missing_authorization" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
    return jsonResponse({ error: "server_configuration_error" }, 500);
  }

  const jwt = authHeader.replace("Bearer ", "").trim();

  const userClient: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return jsonResponse({ error: "invalid_or_expired_token" }, 401);
  }

  // ── 2. Parse request ────────────────────────────────────
  let body: UnlockSaintRequest;
  try {
    body = await req.json() as UnlockSaintRequest;
  } catch {
    return jsonResponse({ error: "invalid_json_body" }, 400);
  }

  const { saint_id, set_as_active = false } = body;

  if (!saint_id) {
    return jsonResponse({ error: "saint_id_required" }, 400);
  }

  if (!isValidUUID(saint_id)) {
    return jsonResponse({ error: "invalid_saint_id_format" }, 400);
  }

  // ── 3. Call unlock_saint_atomic ──────────────────────────
  const serviceClient: SupabaseClient = createClient(
    supabaseUrl,
    supabaseServiceKey,
  );

  const { data: rpcData, error: rpcError } = await serviceClient
    .rpc("unlock_saint_atomic", {
      p_user_id: user.id,
      p_saint_id: saint_id,
    });

  if (rpcError) {
    console.error("[unlock-saint] RPC error:", rpcError);
    return jsonResponse({
      error: "internal_server_error",
      detail: rpcError.message,
    }, 500);
  }

  const result = rpcData as UnlockSaintResult;

  if (!result.success) {
    // Map DB errors to HTTP status codes
    const statusMap: Record<string, number> = {
      saint_not_found: 404,
      user_not_found: 404,
      already_unlocked: 409,
      monastery_level_insufficient: 403,
      insufficient_holy_points: 402, // Payment Required — fitting
    };

    const status = statusMap[result.error ?? ""] ?? 400;

    return jsonResponse({
      error: result.error,
      detail: result.detail,
      // Include helpful context for specific errors
      ...(result.required_level !== undefined && {
        monastery_level_required: result.required_level,
        monastery_level_current: result.current_level,
      }),
      ...(result.have !== undefined && {
        holy_points_have: result.have,
        holy_points_need: result.need,
        holy_points_short: (result.need ?? 0) - (result.have ?? 0),
      }),
    }, status);
  }

  // ── 4. Optionally activate the saint immediately ─────────
  let activationResult: ActivateSaintResult | null = null;

  if (set_as_active) {
    const { data: activateData, error: activateError } = await serviceClient
      .rpc("activate_saint_ability", {
        p_user_id: user.id,
        p_saint_id: saint_id,
      });

    if (activateError) {
      console.warn("[unlock-saint] Activation failed after unlock:", activateError);
      // Non-fatal: unlock succeeded, activation can be retried
    } else {
      activationResult = activateData as ActivateSaintResult;
    }
  }

  // ── 5. Return full success payload ──────────────────────
  return jsonResponse({
    success: true,
    saint_id: result.saint_id,
    saint_name: result.saint_name,
    holy_points_spent: result.cost_paid,
    holy_points_remaining: result.holy_points_remaining,
    ...(set_as_active && activationResult && {
      saint_activated: activationResult.success,
      ability_ends_at: activationResult.ability_ends_at,
      ability_duration_hours: activationResult.duration_hours,
    }),
  });
});
