// ============================================================
// Edge Function: liturgical-events
// Cron-triggered function that:
//   1. Calculates the current liturgical season
//   2. Sets verse_of_day for the next 7 days (if not already set)
//   3. Creates/activates seasonal quests for the current season
//
// Trigger via pg_cron or external cron scheduler (daily at midnight).
// Can also be called manually via authenticated POST.
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Types ───────────────────────────────────────────────────

type LiturgicalSeason =
  | "advent"
  | "christmas"
  | "ordinary_time"
  | "lent"
  | "holy_week"
  | "easter"
  | "ordinary_time_post_pentecost";

interface LiturgicalInfo {
  season: LiturgicalSeason;
  weekNumber: number;
  description: string;
  color: "purple" | "white" | "green" | "red" | "rose";
}

interface VerseOfDayRow {
  verse_id: string;
  scheduled_for: string;
}

interface QuestRow {
  id: string;
  title: string;
  liturgical_season: string | null;
  is_active: boolean;
}

interface BibleVerseRow {
  id: string;
  thematic_tags: string[];
}

// ─── CORS ─────────────────────────────────────────────────────

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ─── Liturgical Calendar Calculation ─────────────────────────
// Calculates the Catholic liturgical season for a given date.
// Uses the Roman Rite calendar rules.

function getEasterDate(year: number): Date {
  // Anonymous Gregorian algorithm
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return new Date(year, month - 1, day);
}

function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

function dateOnly(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function getAdventStart(year: number): Date {
  // Advent starts the Sunday closest to November 30
  const nov30 = new Date(year, 10, 30);
  const dow = nov30.getDay(); // 0=Sun
  const diff = dow === 0 ? 0 : dow <= 3 ? -dow : 7 - dow;
  return dateOnly(addDays(nov30, diff));
}

function getLiturgicalInfo(date: Date): LiturgicalInfo {
  const year = date.getFullYear();
  const today = dateOnly(date);

  // Key dates for this year
  const easter = dateOnly(getEasterDate(year));
  const ashWednesday = dateOnly(addDays(easter, -46));
  const palmSunday = dateOnly(addDays(easter, -7));
  const pentecost = dateOnly(addDays(easter, 49));
  const christmasThisYear = dateOnly(new Date(year, 11, 25)); // Dec 25
  const epiphany = dateOnly(new Date(year, 0, 6));             // Jan 6
  const baptismOfLord = dateOnly(addDays(
    // Sunday after Epiphany (or Monday if Epiphany is Sunday/Monday)
    epiphany,
    epiphany.getDay() === 0 ? 1 : 7 - epiphany.getDay()
  ));

  // Advent for this year and last year
  const adventThisYear = dateOnly(getAdventStart(year));
  const adventLastYear = dateOnly(getAdventStart(year - 1));

  const between = (d: Date, start: Date, end: Date): boolean =>
    d >= start && d <= end;

  // ── Advent ──────────────────────────────────────────────
  if (between(today, adventThisYear, new Date(year, 11, 24))) {
    const weekNum = Math.floor(
      (today.getTime() - adventThisYear.getTime()) / (7 * 86400000)
    ) + 1;
    return {
      season: "advent",
      weekNumber: Math.min(weekNum, 4),
      description: `Week ${Math.min(weekNum, 4)} of Advent`,
      color: weekNum === 3 ? "rose" : "purple",
    };
  }

  // ── Christmas Season ────────────────────────────────────
  if (between(today, new Date(year, 11, 25), new Date(year + 1, 0, 1)) ||
      between(today, new Date(year, 0, 1), baptismOfLord)) {
    return {
      season: "christmas",
      weekNumber: 1,
      description: "Christmas Season",
      color: "white",
    };
  }

  // ── Last year's Advent into January (edge case) ──────────
  if (between(today, adventLastYear, new Date(year, 0, 6))) {
    return {
      season: "advent",
      weekNumber: 4,
      description: "Advent Season",
      color: "purple",
    };
  }

  // ── Ordinary Time (pre-Lent) ────────────────────────────
  if (between(today, addDays(baptismOfLord, 1), addDays(ashWednesday, -1))) {
    const weekNum = Math.floor(
      (today.getTime() - baptismOfLord.getTime()) / (7 * 86400000)
    ) + 1;
    return {
      season: "ordinary_time",
      weekNumber: weekNum,
      description: `Week ${weekNum} of Ordinary Time`,
      color: "green",
    };
  }

  // ── Lent ─────────────────────────────────────────────────
  if (between(today, ashWednesday, addDays(palmSunday, -1))) {
    const weekNum = Math.floor(
      (today.getTime() - ashWednesday.getTime()) / (7 * 86400000)
    ) + 1;
    return {
      season: "lent",
      weekNumber: weekNum,
      description: `Week ${weekNum} of Lent`,
      color: "purple",
    };
  }

  // ── Holy Week ─────────────────────────────────────────────
  if (between(today, palmSunday, addDays(easter, -1))) {
    return {
      season: "holy_week",
      weekNumber: 1,
      description: "Holy Week",
      color: "red",
    };
  }

  // ── Easter Season ─────────────────────────────────────────
  if (between(today, easter, addDays(pentecost, -1))) {
    const weekNum = Math.floor(
      (today.getTime() - easter.getTime()) / (7 * 86400000)
    ) + 1;
    return {
      season: "easter",
      weekNumber: weekNum,
      description: `Week ${weekNum} of Easter`,
      color: "white",
    };
  }

  // ── Ordinary Time (post-Pentecost) ───────────────────────
  const weekNum = Math.floor(
    (today.getTime() - pentecost.getTime()) / (7 * 86400000)
  ) + 9; // Ordinary Time resumes at ~Week 9 after Pentecost

  return {
    season: "ordinary_time_post_pentecost",
    weekNumber: weekNum,
    description: `Week ${weekNum} of Ordinary Time`,
    color: "green",
  };
}

// Tags to use for verse selection per season
const SEASON_VERSE_TAGS: Record<LiturgicalSeason, string[]> = {
  advent: ["advent", "hope", "preparation", "messiah", "prophecy"],
  christmas: ["christmas", "incarnation", "nativity", "joy", "light"],
  ordinary_time: ["discipleship", "faith", "love", "wisdom", "daily_life"],
  lent: ["lent", "repentance", "fasting", "prayer", "sacrifice", "mercy"],
  holy_week: ["passion", "suffering", "redemption", "cross", "sacrifice"],
  easter: ["resurrection", "joy", "new_life", "hope", "alleluia"],
  ordinary_time_post_pentecost: [
    "holy_spirit", "church", "mission", "love", "service",
  ],
};

// ─── Verse scheduling ─────────────────────────────────────────

async function scheduleVersesForNextDays(
  client: SupabaseClient,
  days: number,
  season: LiturgicalSeason,
): Promise<{ scheduled: number; skipped: number }> {
  let scheduled = 0;
  let skipped = 0;

  const tags = SEASON_VERSE_TAGS[season];

  for (let i = 0; i < days; i++) {
    const targetDate = addDays(new Date(), i);
    const dateStr = targetDate.toISOString().split("T")[0];

    // Check if already scheduled
    const { data: existing } = await client
      .from("verse_of_day")
      .select("id")
      .eq("scheduled_for", dateStr)
      .maybeSingle();

    if (existing) {
      skipped++;
      continue;
    }

    // Find a candidate verse not recently used
    const recentDays = 90;
    const recentCutoff = addDays(new Date(), -recentDays).toISOString().split("T")[0];

    const { data: recentlyUsed } = await client
      .from("verse_of_day")
      .select("verse_id")
      .gte("scheduled_for", recentCutoff);

    const recentlyUsedIds = (recentlyUsed ?? []).map((r: VerseOfDayRow) => r.verse_id);

    // Query candidate verses with matching tags
    let query = client
      .from("bible_verses")
      .select("id, thematic_tags")
      .eq("is_verse_of_day_candidate", true)
      .overlaps("thematic_tags", tags)
      .limit(50);

    if (recentlyUsedIds.length > 0) {
      query = query.not("id", "in", `(${recentlyUsedIds.map((id: string) => `"${id}"`).join(",")})`);
    }

    const { data: candidates } = await query;

    let chosenVerse: BibleVerseRow | null = null;

    if (candidates && candidates.length > 0) {
      // Pick a random candidate
      chosenVerse = candidates[Math.floor(Math.random() * candidates.length)] as BibleVerseRow;
    } else {
      // Fallback: any candidate verse
      const { data: fallback } = await client
        .from("bible_verses")
        .select("id, thematic_tags")
        .eq("is_verse_of_day_candidate", true)
        .limit(200);

      if (fallback && fallback.length > 0) {
        chosenVerse = fallback[Math.floor(Math.random() * fallback.length)] as BibleVerseRow;
      }
    }

    if (!chosenVerse) {
      console.warn(`[liturgical-events] No candidate verse found for ${dateStr}`);
      skipped++;
      continue;
    }

    const liturgicalInfo = getLiturgicalInfo(targetDate);

    const { error: insertError } = await client
      .from("verse_of_day")
      .insert({
        verse_id: chosenVerse.id,
        scheduled_for: dateStr,
        liturgical_context: liturgicalInfo.description,
      });

    if (insertError) {
      console.error(`[liturgical-events] Failed to insert verse for ${dateStr}:`, insertError);
      skipped++;
    } else {
      scheduled++;
    }
  }

  return { scheduled, skipped };
}

// ─── Quest activation ─────────────────────────────────────────

async function activateSeasonalQuests(
  client: SupabaseClient,
  season: LiturgicalSeason,
): Promise<{ activated: number; deactivated: number }> {
  const canonicalSeason = season === "ordinary_time_post_pentecost"
    ? "ordinary_time"
    : season;

  // Activate quests for this season
  const { data: toActivate } = await client
    .from("quests")
    .update({ is_active: true })
    .eq("liturgical_season", canonicalSeason)
    .eq("is_active", false)
    .select("id") as { data: QuestRow[] | null };

  // Deactivate seasonal quests from OTHER seasons
  const otherSeasons = ["advent", "christmas", "lent", "holy_week", "easter"]
    .filter((s) => s !== canonicalSeason && s !== "ordinary_time");

  let deactivated = 0;
  for (const otherSeason of otherSeasons) {
    const { data: deactivated_ } = await client
      .from("quests")
      .update({ is_active: false })
      .eq("liturgical_season", otherSeason)
      .eq("is_active", true)
      .select("id") as { data: QuestRow[] | null };

    deactivated += (deactivated_ ?? []).length;
  }

  return {
    activated: (toActivate ?? []).length,
    deactivated,
  };
}

// ─── Main handler ─────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // Accept GET (for cron) or POST (for manual trigger)
  if (req.method !== "GET" && req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // ── 1. Authenticate: cron secret or admin JWT ────────────
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const cronSecret = Deno.env.get("CRON_SECRET");

  if (!supabaseUrl || !supabaseServiceKey) {
    return jsonResponse({ error: "server_configuration_error" }, 500);
  }

  // Check cron secret header (for pg_cron / external schedulers)
  const providedCronSecret = req.headers.get("x-cron-secret");
  const authHeader = req.headers.get("Authorization");

  const isCronCall = cronSecret && providedCronSecret === cronSecret;

  if (!isCronCall) {
    // Require valid JWT for manual calls
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonResponse({ error: "missing_authorization" }, 401);
    }
    // For manual triggers, just verify the JWT is valid
    // (In production, add admin role check here)
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (supabaseAnonKey) {
      const jwt = authHeader.replace("Bearer ", "").trim();
      const verifyClient = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: `Bearer ${jwt}` } },
      });
      const { error: authError } = await verifyClient.auth.getUser();
      if (authError) {
        return jsonResponse({ error: "invalid_or_expired_token" }, 401);
      }
    }
  }

  // ── 2. Calculate current liturgical info ─────────────────
  const now = new Date();
  const liturgicalInfo = getLiturgicalInfo(now);

  console.log(
    `[liturgical-events] Running for ${now.toISOString()}, season: ${liturgicalInfo.season}`,
  );

  const serviceClient: SupabaseClient = createClient(
    supabaseUrl,
    supabaseServiceKey,
  );

  // ── 3. Schedule verses for next 7 days ───────────────────
  const verseResult = await scheduleVersesForNextDays(
    serviceClient,
    7,
    liturgicalInfo.season,
  );

  // ── 4. Activate seasonal quests ──────────────────────────
  const questResult = await activateSeasonalQuests(
    serviceClient,
    liturgicalInfo.season,
  );

  // ── 5. Update any parish leaderboards ────────────────────
  // Refresh leaderboard if it's Monday (start of new week)
  let leaderboardRefreshed = false;
  if (now.getDay() === 1) { // Monday
    const { error: lbError } = await serviceClient.rpc(
      "refresh_parish_leaderboard",
    );
    if (lbError) {
      console.error("[liturgical-events] Leaderboard refresh failed:", lbError);
    } else {
      leaderboardRefreshed = true;
    }
  }

  const summary = {
    success: true,
    executed_at: now.toISOString(),
    liturgical_season: liturgicalInfo.season,
    liturgical_description: liturgicalInfo.description,
    liturgical_color: liturgicalInfo.color,
    week_number: liturgicalInfo.weekNumber,
    verses_scheduled: verseResult.scheduled,
    verses_skipped: verseResult.skipped,
    quests_activated: questResult.activated,
    quests_deactivated: questResult.deactivated,
    leaderboard_refreshed: leaderboardRefreshed,
  };

  console.log("[liturgical-events] Completed:", JSON.stringify(summary));
  return jsonResponse(summary);
});
