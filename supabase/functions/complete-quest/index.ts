// ============================================================
// Edge Function: complete-quest
// Validates JWT, calls complete_quest_atomic, returns result.
// Must be called with service_role privileges (set via invoker).
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

// ─── Types ───────────────────────────────────────────────────

interface CompleteQuestRequest {
  quest_id: string;
  proof_url?: string;
}

interface RewardsGranted {
  holy_points: number;
  faith_coins: number;
  grace: number;
  blessings: number;
  xp: number;
  multiplier: number;
}

interface StreakInfo {
  streak_type: string;
  new_streak: number;
  longest: number;
  streak_broken: boolean;
}

interface AtomicResult {
  success: boolean;
  error?: string;
  detail?: string;
  completion_id?: string;
  rewards_granted?: RewardsGranted;
  new_totals?: {
    total_holy_points: number;
    faith_coins: number;
    grace: number;
    blessings: number;
  };
  leveled_up?: boolean;
  new_level?: number;
  current_xp?: number;
  xp_to_next_level?: number;
  streak_updated?: StreakInfo;
}

// ─── CORS headers ────────────────────────────────────────────

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ─── Helpers ─────────────────────────────────────────────────

function jsonResponse(
  body: unknown,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function isValidUUID(str: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    .test(str);
}

// ─── Achievement checks ──────────────────────────────────────
// Lightweight in-memory achievement detection.
// Detailed achievement storage would be a separate table/function.
function detectAchievements(result: AtomicResult): string[] {
  const achievements: string[] = [];

  if (result.leveled_up && result.new_level) {
    if (result.new_level === 5) achievements.push("faith_seeker");
    if (result.new_level === 10) achievements.push("apprentice_saint");
    if (result.new_level === 25) achievements.push("knight_of_faith");
    if (result.new_level === 50) achievements.push("champion_of_christ");
    if (result.new_level === 100) achievements.push("heavenly_warrior");
  }

  if (result.streak_updated) {
    const { new_streak } = result.streak_updated;
    if (new_streak === 7) achievements.push("weekly_warrior");
    if (new_streak === 30) achievements.push("monthly_faithful");
    if (new_streak === 100) achievements.push("century_saint");
    if (new_streak === 365) achievements.push("year_of_grace");
  }

  return achievements;
}

// ─── Main handler ─────────────────────────────────────────────

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // ── 1. Extract and validate JWT ──────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "missing_authorization" }, 401);
  }

  const jwt = authHeader.replace("Bearer ", "").trim();

  // Create a user-scoped client (validates JWT automatically)
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
    return jsonResponse({ error: "server_configuration_error" }, 500);
  }

  // Validate user JWT with anon client
  const userClient: SupabaseClient = createClient(
    supabaseUrl,
    supabaseAnonKey,
    { global: { headers: { Authorization: `Bearer ${jwt}` } } },
  );

  const { data: { user }, error: authError } = await userClient.auth.getUser();

  if (authError || !user) {
    return jsonResponse({ error: "invalid_or_expired_token" }, 401);
  }

  // ── 2. Parse request body ────────────────────────────────
  let body: CompleteQuestRequest;
  try {
    body = await req.json() as CompleteQuestRequest;
  } catch {
    return jsonResponse({ error: "invalid_json_body" }, 400);
  }

  const { quest_id, proof_url } = body;

  if (!quest_id) {
    return jsonResponse({ error: "quest_id_required" }, 400);
  }

  if (!isValidUUID(quest_id)) {
    return jsonResponse({ error: "invalid_quest_id_format" }, 400);
  }

  if (proof_url && typeof proof_url !== "string") {
    return jsonResponse({ error: "invalid_proof_url" }, 400);
  }

  // Validate proof_url is a proper URL if provided
  if (proof_url) {
    try {
      new URL(proof_url);
    } catch {
      return jsonResponse({ error: "invalid_proof_url_format" }, 400);
    }
  }

  // ── 3. Call atomic function via service role ─────────────
  // Service role bypasses RLS so the function can write to
  // quest_completions and update user_profiles atomically.
  const serviceClient: SupabaseClient = createClient(
    supabaseUrl,
    supabaseServiceKey,
  );

  const { data: rpcData, error: rpcError } = await serviceClient
    .rpc("complete_quest_atomic", {
      p_user_id: user.id,
      p_quest_id: quest_id,
      p_proof_url: proof_url ?? null,
    });

  if (rpcError) {
    console.error("[complete-quest] RPC error:", rpcError);
    return jsonResponse({
      error: "internal_server_error",
      detail: rpcError.message,
    }, 500);
  }

  const result = rpcData as AtomicResult;

  if (!result.success) {
    // Map DB-level errors to appropriate HTTP status codes
    const statusMap: Record<string, number> = {
      quest_not_found_or_inactive: 404,
      user_not_found: 404,
      age_group_insufficient: 403,
      level_insufficient: 403,
      already_completed_today: 409,
      already_completed_this_week: 409,
      already_completed: 409,
    };
    const status = statusMap[result.error ?? ""] ?? 400;
    return jsonResponse({ error: result.error, detail: result.detail }, status);
  }

  // ── 4. Detect achievements ───────────────────────────────
  const achievements = detectAchievements(result);

  // ── 5. Return success payload ────────────────────────────
  return jsonResponse({
    success: true,
    completion_id: result.completion_id,
    rewards_granted: result.rewards_granted,
    new_totals: result.new_totals,
    leveled_up: result.leveled_up,
    new_level: result.new_level,
    current_xp: result.current_xp,
    xp_to_next_level: result.xp_to_next_level,
    streak_updated: result.streak_updated,
    achievements_earned: achievements,
  });
});
