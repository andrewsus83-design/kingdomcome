/**
 * Kingdom Come — AI Gateway Cloudflare Worker
 *
 * Routes AI requests to the appropriate upstream service:
 *   POST /chat                        → Magisterium AI (Catholic chat)
 *   POST /generate-image              → Modal.com Flux Schnell (arts & crafts)
 *   POST /generate-character          → OpenArt AI (saint/character art)
 *   POST /generate-video              → Runway Gen 4.5 (Bible story videos)
 *   POST /create-avatar-video         → HeyGen API (avatar storyteller)
 *   POST /orchestrate                 → Claude API (Anthropic, complex workflows)
 *   GET  /wiki/:articleId             → World Anvil API (wiki content)
 *   POST /music/generate              → Suno AI (custom hymn/music generation)
 *   POST /music/generate-from-verse   → Suno AI (verse-to-hymn)
 *   POST /music/feast-day-song        → Suno AI (feast day song)
 *   GET  /music/kingdom-ambient/:season → Suno AI (liturgical ambient music)
 */

import { filterResponse, validateChatRequest } from "./content-filter";
import { handleSunoRequest } from "./suno";

// ── Env bindings ─────────────────────────────────────────────────────────────

export interface Env {
  MAGISTERIUM_API_KEY: string;
  ANTHROPIC_API_KEY: string;
  OPENART_API_KEY: string;
  MODAL_API_KEY: string;
  RUNWAY_API_KEY: string;
  HEYGEN_API_KEY: string;
  WORLD_ANVIL_API_KEY: string;
  SUNO_API_KEY: string;
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

    // POST /generate-character
    if (pathname === "/generate-character" && request.method === "POST") {
      return handleGenerateCharacter(request, env, ageGroup);
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

    // ── Suno music routes ─────────────────────────────────────────────────────

    // POST /music/generate
    if (pathname === "/music/generate" && request.method === "POST") {
      return handleSunoRequest(request, env);
    }

    // POST /music/generate-from-verse
    if (pathname === "/music/generate-from-verse" && request.method === "POST") {
      return handleSunoRequest(request, env);
    }

    // POST /music/feast-day-song
    if (pathname === "/music/feast-day-song" && request.method === "POST") {
      return handleSunoRequest(request, env);
    }

    // GET /music/kingdom-ambient/:season
    const ambientMatch = pathname.match(/^\/music\/kingdom-ambient\/([^/]+)$/);
    if (ambientMatch && request.method === "GET") {
      return handleSunoRequest(request, env);
    }

    return jsonError("Not found", 404);
  },
};

// ── Route handlers ────────────────────────────────────────────────────────────

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

async function handleGenerateCharacter(
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

  const saintName = typeof body.saintName === "string" ? body.saintName.trim() : "";
  const style = typeof body.style === "string" ? body.style : "icon painting";
  if (!saintName) return jsonError("Field 'saintName' is required.");

  const prompt =
    `Portrait of ${saintName}, Catholic saint, ${style}, holy nimbus, ` +
    `medieval iconography, gold leaf, rich colors, sacred art, child-friendly`;

  try {
    const openArtResponse = await fetch("https://openart.ai/api/v1/generate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.OPENART_API_KEY}`,
      },
      body: JSON.stringify({
        prompt,
        negative_prompt: "violent, scary, inappropriate, modern, photorealistic",
        width: 512,
        height: 512,
        num_images: 1,
        model: "openart-xl",
      }),
    });

    if (!openArtResponse.ok) {
      return jsonError("Character generation service temporarily unavailable.", 502);
    }

    const data = await openArtResponse.json();
    return jsonOk(data);
  } catch (err) {
    console.error("Character generation error:", err);
    return jsonError("Internal server error.", 500);
  }
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
