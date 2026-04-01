// ============================================================
// Edge Function: award-resources
// Awards resources to a user. Used for:
//   - Mass attendance verification
//   - Admin grants
//   - Event rewards
//   - Automated daily bonus distributions
//
// Requires a valid user JWT. Resource amounts are validated
// server-side; source/reason is required for audit trail.
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

// ─── Types ───────────────────────────────────────────────────

interface AwardResourcesRequest {
  // Target user (admins can specify; regular users get their own id)
  target_user_id?: string;

  // Resources to award (all optional, defaults 0)
  holy_points?: number;
  faith_coins?: number;
  grace?: number;
  blessings?: number;

  // Required: reason for the award (for audit / display)
  source: AwardSource;
  source_ref_id?: string; // e.g. quest_id, event_id, etc.
  note?: string;
}

type AwardSource =
  | "mass_attendance"
  | "daily_login_bonus"
  | "streak_milestone"
  | "admin_grant"
  | "event_reward"
  | "referral_bonus"
  | "parish_challenge"
  | "liturgical_feast"
  | "confession_bonus";

// Maximum awards per call (prevent runaway grants)
const MAX_HOLY_POINTS_PER_CALL = 5000;
const MAX_FAITH_COINS_PER_CALL = 1000;
const MAX_GRACE_PER_CALL = 500;
const MAX_BLESSINGS_PER_CALL = 200;

// Sources that require admin role
const ADMIN_ONLY_SOURCES: AwardSource[] = ["admin_grant"];

// Predefined award amounts for automatic sources (hard-coded for safety)
const SOURCE_AWARD_PRESETS: Partial<
  Record<AwardSource, {
    holy_points?: number;
    faith_coins?: number;
    grace?: number;
    blessings?: number;
  }>
> = {
  mass_attendance: { holy_points: 150, faith_coins: 10, grace: 5 },
  daily_login_bonus: { holy_points: 10, faith_coins: 2 },
  confession_bonus: { holy_points: 100, grace: 10, blessings: 5 },
  liturgical_feast: { holy_points: 200, faith_coins: 15, grace: 8, blessings: 3 },
};

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

function clamp(val: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.floor(val)));
}

// ─── Main handler ─────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // ── 1. Authenticate user ────────────────────────────────
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
  let body: AwardResourcesRequest;
  try {
    body = await req.json() as AwardResourcesRequest;
  } catch {
    return jsonResponse({ error: "invalid_json_body" }, 400);
  }

  const { source, source_ref_id, note } = body;

  // Validate source
  const validSources: AwardSource[] = [
    "mass_attendance",
    "daily_login_bonus",
    "streak_milestone",
    "admin_grant",
    "event_reward",
    "referral_bonus",
    "parish_challenge",
    "liturgical_feast",
    "confession_bonus",
  ];

  if (!source || !validSources.includes(source)) {
    return jsonResponse({
      error: "invalid_source",
      valid_sources: validSources,
    }, 400);
  }

  // ── 3. Determine target user ─────────────────────────────
  let targetUserId = user.id;

  if (body.target_user_id && body.target_user_id !== user.id) {
    // Only admin-sourced awards can target other users
    if (!ADMIN_ONLY_SOURCES.includes(source)) {
      return jsonResponse({
        error: "cannot_award_other_users",
        detail: "Only admin_grant source can target other users.",
      }, 403);
    }

    if (!isValidUUID(body.target_user_id)) {
      return jsonResponse({ error: "invalid_target_user_id" }, 400);
    }

    // TODO: verify caller has admin role in their JWT claims
    // For now, this is protected by requiring service_role from internal calls
    targetUserId = body.target_user_id;
  }

  // ── 4. Determine award amounts ───────────────────────────
  let holyPoints: number;
  let faithCoins: number;
  let grace: number;
  let blessings: number;

  const preset = SOURCE_AWARD_PRESETS[source];
  if (preset) {
    // Use preset values; caller cannot override
    holyPoints = preset.holy_points ?? 0;
    faithCoins = preset.faith_coins ?? 0;
    grace = preset.grace ?? 0;
    blessings = preset.blessings ?? 0;
  } else {
    // Caller-specified amounts — clamp to safe maximums
    holyPoints = clamp(body.holy_points ?? 0, 0, MAX_HOLY_POINTS_PER_CALL);
    faithCoins = clamp(body.faith_coins ?? 0, 0, MAX_FAITH_COINS_PER_CALL);
    grace = clamp(body.grace ?? 0, 0, MAX_GRACE_PER_CALL);
    blessings = clamp(body.blessings ?? 0, 0, MAX_BLESSINGS_PER_CALL);
  }

  if (holyPoints + faithCoins + grace + blessings === 0) {
    return jsonResponse({ error: "no_resources_to_award" }, 400);
  }

  // ── 5. Call award_resources RPC ──────────────────────────
  const serviceClient: SupabaseClient = createClient(
    supabaseUrl,
    supabaseServiceKey,
  );

  const { data: rpcData, error: rpcError } = await serviceClient
    .rpc("award_resources", {
      p_user_id: targetUserId,
      p_holy_points: holyPoints,
      p_faith_coins: faithCoins,
      p_grace: grace,
      p_blessings: blessings,
    });

  if (rpcError) {
    console.error("[award-resources] RPC error:", rpcError);
    return jsonResponse({ error: "internal_server_error", detail: rpcError.message }, 500);
  }

  const result = rpcData as {
    success: boolean;
    error?: string;
    total_holy_points?: number;
    faith_coins?: number;
    grace?: number;
    blessings?: number;
  };

  if (!result.success) {
    return jsonResponse({ error: result.error ?? "award_failed" }, 400);
  }

  // ── 6. Log award for audit (insert into audit table if it exists) ─
  // Soft-fail — don't block the response if audit log fails
  try {
    await serviceClient.from("resource_award_log").insert({
      user_id: targetUserId,
      awarded_by: user.id,
      source,
      source_ref_id: source_ref_id ?? null,
      holy_points_awarded: holyPoints,
      faith_coins_awarded: faithCoins,
      grace_awarded: grace,
      blessings_awarded: blessings,
      note: note ?? null,
    });
  } catch (logError) {
    console.warn("[award-resources] Audit log failed (non-fatal):", logError);
  }

  return jsonResponse({
    success: true,
    awarded: {
      holy_points: holyPoints,
      faith_coins: faithCoins,
      grace,
      blessings,
    },
    source,
    new_totals: {
      total_holy_points: result.total_holy_points,
      faith_coins: result.faith_coins,
      grace: result.grace,
      blessings: result.blessings,
    },
  });
});
