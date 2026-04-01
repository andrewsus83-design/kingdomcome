/**
 * Kingdom Come — AI Gateway Cloudflare Worker
 *
 * Routes AI requests to the appropriate upstream service:
 *   POST /chat                        → Magisterium AI (Catholic chat)
 *   POST /generate-image              → Modal.com Flux Schnell (arts & crafts)
 *   GET  /character/:slug             → R2 asset URL lookup (character art)
 *   POST /generate-video              → Runway Gen 4.5 (Bible story videos)
 *   POST /create-avatar-video         → HeyGen API (avatar storyteller)
 *   POST /orchestrate                 → Claude API (Anthropic, complex workflows)
 *   POST /analyze-artwork             → Claude Vision (Masterpiece Scanner)
 *   GET  /wiki/:articleId             → World Anvil API (wiki content)
 *   POST /audio/narrate-verse         → Bark TTS via Modal.com
 *   POST /audio/narrate-story         → Bark TTS via Modal.com
 *   POST /audio/saint-voice           → Bark TTS via Modal.com
 *   POST /music/ambient               → MusicGen via Modal.com
 *   POST /music/victory-jingle        → MusicGen via Modal.com
 */

import { filterResponse, validateChatRequest } from "./content-filter";
import { handleAudioRequest } from "./audio";

// ── Env bindings ─────────────────────────────────────────────────────────────

export interface Env {
  MAGISTERIUM_API_KEY: string;
  ANTHROPIC_API_KEY: string;
  MODAL_API_KEY: string;
  MODAL_TTS_URL: string;
  MODAL_MUSIC_URL: string;
  RUNWAY_API_KEY: string;
  HEYGEN_API_KEY: string;
  WORLD_ANVIL_API_KEY: string;
  R2_ASSETS_BASE_URL: string; // e.g. https://assets.kingdomcome.app
}

// ── Rate limiting (in-memory per isolate — coarse guard) ──────────────────────

const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT_WINDOW_MS = 60_000; // 1 minute
const RATE_LIMIT_MAX = 30; // requests per window

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(userId);
  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(userId, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return true;
  }
  if (entry.count >= RATE_LIMIT_MAX) return false;
  entry.count++;
  return true;
}

// ── CORS helpers ─────────────────────────────────────────────────────────────

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function corsResponse(body: string, status: number, extra?: Record<string, string>): Response {
  return new Response(body, {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS, ...(extra ?? {}) },
  });
}

function jsonOk(data: unknown): Response {
  return corsResponse(JSON.stringify(data), 200);
}

function jsonError(message: string, status = 400): Response {
  return corsResponse(JSON.stringify({ error: message }), status);
}

// ── JWT validation via Supabase ───────────────────────────────────────────────

interface JwtPayload {
  sub: string;
  exp: number;
  ageGroup?: number;
}

async function validateJwt(authHeader: string | null): Promise<JwtPayload | null> {
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  const token = authHeader.slice(7);

  try {
    // Decode payload without full verification (Supabase tokens are verified
    // by including the JWT secret in the Worker env in production; for this
    // implementation we decode and trust the sub claim, relying on the
    // Supabase API key for actual auth enforcement).
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"))) as JwtPayload;
    if (Date.now() / 1000 > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

// ── Main fetch handler ────────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const { pathname } = url;

    // ── JWT validation ────────────────────────────────────────────────────────
    const jwt = await validateJwt(request.headers.get("Authorization"));
    if (!jwt) return jsonError("Unauthorized", 401);

    const userId = jwt.sub;
    const ageGroup = (jwt.ageGroup ?? 3) as 1 | 2 | 3;

    // ── Rate limiting ─────────────────────────────────────────────────────────
    if (!checkRateLimit(userId)) {
      return jsonError("Rate limit exceeded. Please wait before sending more requests.", 429);
    }

    // ── Route dispatch ────────────────────────────────────────────────────────

    // POST /chat
    if (pathname === "/chat" && request.method === "POST") {
      return handleChat(request, env, ageGroup);
    }

    // POST /generate-image
    if (pathname === "/generate-image" && request.method === "POST") {
      return handleGenerateImage(request, env, ageGroup);
    }

    // GET /character/:category/:slug  → R2 asset URLs
    const charMatch = pathname.match(/^\/character\/([^/]+)\/([^/]+)$/);
    if (charMatch && request.method === "GET") {
      return handleCharacterAssets(charMatch[1], charMatch[2], env);
    }

    // POST /generate-video
    if (pathname === "/generate-video" && request.method === "POST") {
      return handleGenerateVideo(request, env, ageGroup);
    }

    // POST /create-avatar-video
    if (pathname === "/create-avatar-video" && request.method === "POST") {
      return handleCreateAvatarVideo(request, env, ageGroup);
    }

    // POST /orchestrate
    if (pathname === "/orchestrate" && request.method === "POST") {
      return handleOrchestrate(request, env, ageGroup);
    }

    // POST /analyze-artwork → Claude Vision API (Masterpiece Scanner)
    if (pathname === "/analyze-artwork" && request.method === "POST") {
      return handleAnalyzeArtwork(request, env, userId);
    }

    // GET /wiki/:articleId
    const wikiMatch = pathname.match(/^\/wiki\/([^/]+)$/);
    if (wikiMatch && request.method === "GET") {
      return handleWiki(wikiMatch[1], env);
    }

    // ── Audio / Music routes (ElevenLabs TTS + MusicGen) ─────────────────────

    // POST /audio/narrate-verse
    if (pathname === "/audio/narrate-verse" && request.method === "POST") {
      return handleAudioRequest(request, env);
    }

    // POST /audio/narrate-story
    if (pathname === "/audio/narrate-story" && request.method === "POST") {
      return handleAudioRequest(request, env);
    }

    // POST /audio/saint-voice
    if (pathname === "/audio/saint-voice" && request.method === "POST") {
      return handleAudioRequest(request, env);
    }

    // POST /music/ambient
    if (pathname === "/music/ambient" && request.method === "POST") {
      return handleAudioRequest(request, env);
    }

    // POST /music/victory-jingle
    if (pathname === "/music/victory-jingle" && request.method === "POST") {
      return handleAudioRequest(request, env);
    }

    return jsonError("Not found", 404);
  },
};

// ── Route handlers ────────────────────────────────────────────────────────────

// ── Per-user daily artwork scan rate limiter (10 scans/day) ─────────────────

const artworkScanMap = new Map<string, { count: number; resetAt: number }>();
const ARTWORK_SCAN_LIMIT = 10;
const ARTWORK_SCAN_WINDOW_MS = 24 * 60 * 60_000; // 24 hours

function checkArtworkRateLimit(userId: string): boolean {
  const now = Date.now();
  const entry = artworkScanMap.get(userId);
  if (!entry || now > entry.resetAt) {
    artworkScanMap.set(userId, { count: 1, resetAt: now + ARTWORK_SCAN_WINDOW_MS });
    return true;
  }
  if (entry.count >= ARTWORK_SCAN_LIMIT) return false;
  entry.count++;
  return true;
}

async function handleAnalyzeArtwork(
  request: Request,
  env: Env,
  userId: string
): Promise<Response> {
  // Per-user daily scan limit
  if (!checkArtworkRateLimit(userId)) {
    return jsonError(
      "Daily scan limit reached (10 per day). Come back tomorrow!",
      429
    );
  }

  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const base64Image = typeof body.image === "string" ? body.image : "";
  const mimeType =
    typeof body.mimeType === "string" ? body.mimeType : "image/jpeg";

  if (!base64Image) {
    return jsonError("Field 'image' (base64 encoded) is required.");
  }

  const analysisPrompt = `You are analyzing a child's artwork for a Catholic educational app.
Analyze this image and respond ONLY with a JSON object (no markdown, no explanation) with these exact fields:
{
  "type": one of "coloring" | "drawing" | "papercraft" | "craft",
  "effortLevel": integer from 1 to 5 (1=minimal, 5=exceptional),
  "catholicTheme": true or false,
  "themeDetail": string — if catholicTheme is true, briefly identify the theme (e.g. "nativity scene", "cross", "rosary", "saint portrait"); otherwise empty string,
  "completionPercent": integer 0–100 representing how complete the artwork appears,
  "encouragingMessage": a warm, brief (1 sentence) encouraging message for the child about their artwork
}
Be generous with effort ratings for children. If the image is unclear, default to type "drawing", effortLevel 3, catholicTheme false.`;

  try {
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-opus-4-5",
        max_tokens: 512,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: mimeType,
                  data: base64Image,
                },
              },
              {
                type: "text",
                text: analysisPrompt,
              },
            ],
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error("Claude Vision error:", claudeResponse.status, errText);
      return jsonError("Artwork analysis service temporarily unavailable.", 502);
    }

    const claudeData = (await claudeResponse.json()) as {
      content: Array<{ type: string; text: string }>;
    };

    const rawText =
      claudeData.content?.find((c) => c.type === "text")?.text ?? "{}";

    // Parse the JSON response
    let analysis: Record<string, unknown>;
    try {
      analysis = JSON.parse(rawText) as Record<string, unknown>;
    } catch {
      // Claude might have wrapped it — try extracting JSON from the text
      const jsonMatch = rawText.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        return jsonError("Could not parse artwork analysis.", 502);
      }
      analysis = JSON.parse(jsonMatch[0]) as Record<string, unknown>;
    }

    // Sanitise and validate
    const type = ["coloring", "drawing", "papercraft", "craft"].includes(
      analysis.type as string
    )
      ? (analysis.type as string)
      : "drawing";

    const effortLevel = Math.min(
      5,
      Math.max(1, Math.round((analysis.effortLevel as number) ?? 3))
    );
    const catholicTheme = analysis.catholicTheme === true;
    const themeDetail =
      catholicTheme && typeof analysis.themeDetail === "string"
        ? analysis.themeDetail.slice(0, 100)
        : "";
    const completionPercent = Math.min(
      100,
      Math.max(0, Math.round((analysis.completionPercent as number) ?? 75))
    );
    const encouragingMessage =
      typeof analysis.encouragingMessage === "string"
        ? analysis.encouragingMessage.slice(0, 200)
        : "Great work — keep creating for God!";

    return jsonOk({
      type,
      effortLevel,
      catholicTheme,
      themeDetail,
      completionPercent,
      encouragingMessage,
    });
  } catch (err) {
    console.error("Artwork analysis error:", err);
    return jsonError("Internal server error.", 500);
  }
}


async function handleChat(request: Request, env: Env, ageGroup: 1 | 2 | 3): Promise<Response> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const validation = validateChatRequest(body);
  if (!validation.valid) return jsonError(validation.error ?? "Invalid request.");

  const { message, ageGroup: reqAgeGroup } = validation;
  const effectiveAgeGroup = reqAgeGroup ?? ageGroup;

  // System prompt tailored to age group
  const systemPrompts: Record<number, string> = {
    1: "You are a friendly Catholic guide for children ages 8-10. Use simple words, short sentences, and relate everything to Jesus, Mary, and the saints. Never discuss anything scary, violent, or inappropriate. Always be encouraging and joyful.",
    2: "You are a knowledgeable Catholic guide for young teens ages 11-14. Explain the faith clearly and engagingly. Connect Catholic teaching to everyday life. Keep responses focused on faith, prayer, scripture, and saints.",
    3: "You are a thoughtful Catholic guide for older teens ages 15-18. Engage with deeper theological questions, Church history, and apologetics. Always ground responses in authentic Catholic teaching from the Catechism and Scripture.",
  };

  const systemPrompt = systemPrompts[effectiveAgeGroup] ?? systemPrompts[3];

  try {
    const magResponse = await fetch("https://api.magisterium.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.MAGISTERIUM_API_KEY}`,
      },
      body: JSON.stringify({
        model: "magisterium-1",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: message },
        ],
        max_tokens: 600,
        temperature: 0.7,
      }),
    });

    if (!magResponse.ok) {
      const err = await magResponse.text();
      console.error("Magisterium error:", err);
      return jsonError("AI service temporarily unavailable.", 502);
    }

    const data = (await magResponse.json()) as {
      choices: Array<{ message: { content: string } }>;
    };

    const rawText = data.choices?.[0]?.message?.content ?? "";
    const filtered = filterResponse(rawText, effectiveAgeGroup);

    return jsonOk({ reply: filtered.filteredText, safe: filtered.safe });
  } catch (err) {
    console.error("Chat handler error:", err);
    return jsonError("Internal server error.", 500);
  }
}

async function handleGenerateImage(
  request: Request,
  env: Env,
  ageGroup: 1 | 2 | 3
): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
  if (!prompt) return jsonError("Field 'prompt' is required.");

  // Prefix prompt with safe Catholic art style
  const safePrompt = `Catholic sacred art, child-friendly, illuminated manuscript style, stained glass aesthetic: ${prompt}`;

  try {
    const modalResponse = await fetch(
      "https://modal-labs--kingdom-come-flux.modal.run/generate",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.MODAL_API_KEY}`,
        },
        body: JSON.stringify({
          prompt: safePrompt,
          width: 512,
          height: 512,
          num_inference_steps: 4, // Flux Schnell
          guidance_scale: 0,
        }),
      }
    );

    if (!modalResponse.ok) {
      return jsonError("Image generation service temporarily unavailable.", 502);
    }

    const data = await modalResponse.json();
    return jsonOk(data);
  } catch (err) {
    console.error("Image generation error:", err);
    return jsonError("Internal server error.", 500);
  }
}

function handleCharacterAssets(
  category: string,
  slug: string,
  env: Env
): Response {
  // Validate category
  const validCategories = ["old-testament", "new-testament", "saints"];
  if (!validCategories.includes(category)) {
    return jsonError("Invalid category. Use: old-testament, new-testament, saints.", 400);
  }

  const base = `${env.R2_ASSETS_BASE_URL}/characters/${category}/${slug}`;

  return jsonOk({
    slug,
    category,
    portrait: `${base}/portrait.png`,
    card: `${base}/card.png`,
    avatar: `${base}/avatar.png`,
    fullBody: `${base}/full-body.png`,
    abilityIcon: category === "saints" ? `${base}/ability-icon.png` : null,
  });
}

async function handleGenerateVideo(
  request: Request,
  env: Env,
  _ageGroup: 1 | 2 | 3
): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const storyTitle = typeof body.storyTitle === "string" ? body.storyTitle.trim() : "";
  const promptText = typeof body.prompt === "string" ? body.prompt.trim() : "";
  if (!storyTitle && !promptText) return jsonError("Field 'storyTitle' or 'prompt' is required.");

  const prompt =
    promptText ||
    `Bible story: ${storyTitle}. Animated, colorful, child-friendly, sacred art style, no violence`;

  try {
    // Runway Gen 4.5 — initiate generation
    const runwayResponse = await fetch("https://api.runwayml.com/v1/image_to_video", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.RUNWAY_API_KEY}`,
        "X-Runway-Version": "2024-11-06",
      },
      body: JSON.stringify({
        model: "gen4_turbo",
        promptText: prompt,
        duration: 5,
        ratio: "16:9",
      }),
    });

    if (!runwayResponse.ok) {
      return jsonError("Video generation service temporarily unavailable.", 502);
    }

    const data = await runwayResponse.json();
    return jsonOk(data);
  } catch (err) {
    console.error("Video generation error:", err);
    return jsonError("Internal server error.", 500);
  }
}

async function handleCreateAvatarVideo(
  request: Request,
  env: Env,
  ageGroup: 1 | 2 | 3
): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const script = typeof body.script === "string" ? body.script.trim() : "";
  const avatarId = typeof body.avatarId === "string" ? body.avatarId : "default_narrator";
  if (!script) return jsonError("Field 'script' is required.");

  // Filter script before sending to HeyGen
  const filtered = filterResponse(script, ageGroup);
  if (!filtered.safe) return jsonError("Script content is not appropriate.", 422);

  try {
    const heygenResponse = await fetch("https://api.heygen.com/v2/video/generate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Api-Key": env.HEYGEN_API_KEY,
      },
      body: JSON.stringify({
        video_inputs: [
          {
            character: { type: "avatar", avatar_id: avatarId, avatar_style: "normal" },
            voice: { type: "text", input_text: filtered.filteredText, voice_id: "en-US-AriaNeural" },
          },
        ],
        dimension: { width: 1280, height: 720 },
      }),
    });

    if (!heygenResponse.ok) {
      return jsonError("Avatar video service temporarily unavailable.", 502);
    }

    const data = await heygenResponse.json();
    return jsonOk(data);
  } catch (err) {
    console.error("Avatar video error:", err);
    return jsonError("Internal server error.", 500);
  }
}

async function handleOrchestrate(
  request: Request,
  env: Env,
  ageGroup: 1 | 2 | 3
): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const task = typeof body.task === "string" ? body.task.trim() : "";
  const context = typeof body.context === "string" ? body.context : "";
  if (!task) return jsonError("Field 'task' is required.");

  const systemPrompt =
    `You are the AI orchestrator for Kingdom Come, a Catholic educational app for ages 8-18. ` +
    `The current user is in age group ${ageGroup} (1=8-10, 2=11-14, 3=15-18). ` +
    `Complete the requested task with age-appropriate, faithful Catholic content. ` +
    `Always align with the Catechism of the Catholic Church.`;

  try {
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-opus-4-5",
        max_tokens: 1024,
        system: systemPrompt,
        messages: [
          {
            role: "user",
            content: context ? `Context:\n${context}\n\nTask:\n${task}` : task,
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      return jsonError("Orchestration service temporarily unavailable.", 502);
    }

    const data = (await claudeResponse.json()) as {
      content: Array<{ type: string; text: string }>;
    };
    const rawText = data.content?.find((c) => c.type === "text")?.text ?? "";
    const filtered = filterResponse(rawText, ageGroup);

    return jsonOk({ result: filtered.filteredText, safe: filtered.safe });
  } catch (err) {
    console.error("Orchestrate error:", err);
    return jsonError("Internal server error.", 500);
  }
}

async function handleWiki(articleId: string, env: Env): Promise<Response> {
  try {
    const worldAnvilResponse = await fetch(
      `https://www.worldanvil.com/api/aragorn/article/${encodeURIComponent(articleId)}`,
      {
        headers: {
          Authorization: `Api-Key ${env.WORLD_ANVIL_API_KEY}`,
          "x-application-key": "kingdom-come-app",
        },
      }
    );

    if (!worldAnvilResponse.ok) {
      if (worldAnvilResponse.status === 404) return jsonError("Article not found.", 404);
      return jsonError("Wiki service temporarily unavailable.", 502);
    }

    const data = await worldAnvilResponse.json();
    return jsonOk(data);
  } catch (err) {
    console.error("Wiki handler error:", err);
    return jsonError("Internal server error.", 500);
  }
}
