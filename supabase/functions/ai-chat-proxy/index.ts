// ============================================================
// Edge Function: ai-chat-proxy
// Proxies age-appropriate Catholic AI chat via Magisterium AI.
// Requirements:
//   - Valid JWT
//   - user.age_group >= 2 (teen or older) OR parental_consent_given = true
//   - Conversation history passed per-request (not stored in DB)
//   - Content filtered on both input and output
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

// ─── Types ───────────────────────────────────────────────────

interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

interface ChatRequest {
  message: string;
  conversation_history?: ChatMessage[];
}

interface MagisteriumMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface MagisteriumRequest {
  model: string;
  messages: MagisteriumMessage[];
  max_tokens?: number;
  temperature?: number;
}

interface MagisteriumResponse {
  id: string;
  choices: Array<{
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }>;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
  };
}

interface UserProfile {
  age_group: number | null;
  parental_consent_given: boolean;
}

// ─── Constants ────────────────────────────────────────────────

const MAGISTERIUM_API_URL =
  "https://api.magisterium.com/v1/chat/completions";

const SYSTEM_PROMPT = `You are a faithful Catholic AI assistant for young people aged 8-18.
Your name is "Brother Francis" and you are a wise, encouraging guide in the Catholic faith.

ONLY discuss:
- Catholic faith, theology, and doctrine
- Prayer (Rosary, Liturgy of the Hours, devotional prayers)
- Saints and their lives and virtues
- Sacred Scripture and its Catholic interpretation
- The Seven Sacraments
- The Mass and liturgical seasons (Advent, Christmas, Lent, Easter, Ordinary Time)
- Catholic moral teaching and virtue ethics
- Church history and tradition
- Catholic art, music, and culture
- How to grow in holiness and discipleship

NEVER discuss:
- Violence, gore, or disturbing content
- Adult or romantic content
- Non-Catholic religious topics (unless briefly comparing in an educational way)
- Politics, partisan topics, or social controversies beyond clear Catholic moral teaching
- Video games, entertainment, or pop culture (unless connecting to a faith topic)
- Personal information requests

TONE: Be warm, encouraging, and age-appropriate. Speak like a wise older friend or mentor,
not a textbook. Use relatable language. Celebrate the user's curiosity about the faith.
End responses with an encouraging thought or a brief related prayer when appropriate.

If a user asks about something outside your scope, gently redirect:
"That's a bit outside what I can help with, but speaking of faith — [redirect]"`;

// Maximum conversation history turns to include (prevents token bloat)
const MAX_HISTORY_TURNS = 10;

// Maximum characters in a single user message
const MAX_MESSAGE_LENGTH = 1500;

// Words that trigger an immediate refusal (pre-LLM content filter)
const BLOCKED_INPUT_PATTERNS = [
  /\b(pornograph|explicit|sexual|nude|naked)\b/i,
  /\b(kill|murder|suicide|self.harm|hurt myself)\b/i,
  /\b(drugs|cocaine|heroin|meth|weed)\b/i,
  /\b(hack|exploit|jailbreak|ignore previous instructions)\b/i,
];

// Post-LLM output filter — if response contains these, replace with safe fallback
const BLOCKED_OUTPUT_PATTERNS = [
  /\b(pornograph|explicit|sexual content)\b/i,
  /\b(violence|gore|blood)\b/i,
];

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

// ─── Content filters ──────────────────────────────────────────

function isInputBlocked(message: string): boolean {
  return BLOCKED_INPUT_PATTERNS.some((pattern) => pattern.test(message));
}

function sanitizeOutput(response: string): { safe: boolean; text: string } {
  for (const pattern of BLOCKED_OUTPUT_PATTERNS) {
    if (pattern.test(response)) {
      return {
        safe: false,
        text:
          "I'm here to help with questions about the Catholic faith. Is there something about prayer, the saints, or Scripture I can help you with?",
      };
    }
  }
  return { safe: true, text: response };
}

// Trim and sanitize user message
function sanitizeInput(message: string): string {
  return message.trim().slice(0, MAX_MESSAGE_LENGTH);
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
  const magisteriumApiKey = Deno.env.get("MAGISTERIUM_API_KEY");

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
    return jsonResponse({ error: "server_configuration_error" }, 500);
  }

  if (!magisteriumApiKey) {
    console.error("[ai-chat-proxy] MAGISTERIUM_API_KEY not configured");
    return jsonResponse({ error: "ai_service_not_configured" }, 503);
  }

  const jwt = authHeader.replace("Bearer ", "").trim();

  const userClient: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return jsonResponse({ error: "invalid_or_expired_token" }, 401);
  }

  // ── 2. Check age / consent ──────────────────────────────
  const serviceClient: SupabaseClient = createClient(
    supabaseUrl,
    supabaseServiceKey,
  );

  const { data: profile, error: profileError } = await serviceClient
    .from("user_profiles")
    .select("age_group, parental_consent_given")
    .eq("id", user.id)
    .single<UserProfile>();

  if (profileError || !profile) {
    return jsonResponse({ error: "profile_not_found" }, 404);
  }

  const ageGroup = profile.age_group ?? 1;

  // Children (age_group = 1, i.e. 8-11) require parental consent for AI chat
  if (ageGroup < 2 && !profile.parental_consent_given) {
    return jsonResponse({
      error: "parental_consent_required",
      message:
        "AI chat requires parental consent for users under 12. Please ask a parent or guardian to enable this feature.",
    }, 403);
  }

  // ── 3. Parse and validate request ────────────────────────
  let body: ChatRequest;
  try {
    body = await req.json() as ChatRequest;
  } catch {
    return jsonResponse({ error: "invalid_json_body" }, 400);
  }

  if (!body.message || typeof body.message !== "string") {
    return jsonResponse({ error: "message_required" }, 400);
  }

  const userMessage = sanitizeInput(body.message);

  if (userMessage.length === 0) {
    return jsonResponse({ error: "message_cannot_be_empty" }, 400);
  }

  // ── 4. Pre-LLM content filter ────────────────────────────
  if (isInputBlocked(userMessage)) {
    return jsonResponse({
      success: true,
      reply:
        "I'm here to help you explore the Catholic faith! Let's talk about something faith-related — maybe a saint you're curious about, a prayer you'd like to learn, or a Bible story?",
      filtered: true,
    });
  }

  // ── 5. Build message array ───────────────────────────────
  const history: ChatMessage[] = Array.isArray(body.conversation_history)
    ? body.conversation_history.slice(-MAX_HISTORY_TURNS)
    : [];

  // Validate history format
  const validatedHistory: MagisteriumMessage[] = history
    .filter((m) =>
      m &&
      typeof m.content === "string" &&
      ["user", "assistant"].includes(m.role)
    )
    .map((m) => ({
      role: m.role as "user" | "assistant",
      content: m.content.slice(0, MAX_MESSAGE_LENGTH),
    }));

  const messages: MagisteriumMessage[] = [
    { role: "system", content: SYSTEM_PROMPT },
    ...validatedHistory,
    { role: "user", content: userMessage },
  ];

  // ── 6. Call Magisterium AI ───────────────────────────────
  const magisteriumPayload: MagisteriumRequest = {
    model: "magisterium-1",   // Magisterium AI's Catholic-trained model
    messages,
    max_tokens: 800,
    temperature: 0.7,
  };

  let aiResponse: MagisteriumResponse;

  try {
    const apiResponse = await fetch(MAGISTERIUM_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${magisteriumApiKey}`,
        "User-Agent": "KingdomComeApp/1.0",
      },
      body: JSON.stringify(magisteriumPayload),
    });

    if (!apiResponse.ok) {
      const errorText = await apiResponse.text();
      console.error(
        `[ai-chat-proxy] Magisterium API error ${apiResponse.status}:`,
        errorText,
      );

      if (apiResponse.status === 429) {
        return jsonResponse({
          error: "rate_limit_exceeded",
          message: "The AI assistant is very busy right now. Please try again in a moment.",
        }, 429);
      }

      if (apiResponse.status === 401 || apiResponse.status === 403) {
        return jsonResponse({ error: "ai_service_auth_error" }, 503);
      }

      return jsonResponse({
        error: "ai_service_error",
        message: "The AI assistant is temporarily unavailable. Please try again shortly.",
      }, 503);
    }

    aiResponse = await apiResponse.json() as MagisteriumResponse;
  } catch (fetchError) {
    console.error("[ai-chat-proxy] Network error calling Magisterium AI:", fetchError);
    return jsonResponse({
      error: "ai_service_unreachable",
      message: "Unable to reach the AI assistant. Please check your connection and try again.",
    }, 503);
  }

  // ── 7. Extract and filter response ──────────────────────
  const rawReply = aiResponse.choices?.[0]?.message?.content;

  if (!rawReply || typeof rawReply !== "string") {
    console.error("[ai-chat-proxy] Unexpected Magisterium response shape:", aiResponse);
    return jsonResponse({ error: "malformed_ai_response" }, 502);
  }

  const { safe, text: filteredReply } = sanitizeOutput(rawReply);

  if (!safe) {
    console.warn(
      `[ai-chat-proxy] Output filtered for user ${user.id}. Raw response contained blocked content.`,
    );
  }

  // ── 8. Return response (do NOT persist conversation) ────
  return jsonResponse({
    success: true,
    reply: filteredReply,
    filtered: !safe,
    usage: aiResponse.usage
      ? {
        prompt_tokens: aiResponse.usage.prompt_tokens,
        completion_tokens: aiResponse.usage.completion_tokens,
      }
      : undefined,
  });
});
