/**
 * Kingdom Come — Audio module
 *
 * All music is pre-generated with Suno and stored in R2.
 * This module provides URL helpers to serve tracks from R2.
 *
 * Routes:
 *   GET  /audio/track/:path           → R2 URL for any audio file
 *   GET  /music/kingdom-ambient/:season → R2 URL for liturgical season music
 *   GET  /music/character/:slug       → R2 URL for character theme
 */

export interface AudioEnv {
  MODAL_API_KEY: string;
  R2_ASSETS_BASE_URL: string;
}

// ── CORS / response helpers ───────────────────────────────────────────────────

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function jsonOk(data: unknown): Response {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

function jsonError(message: string, status = 400): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

// ── Liturgical season → R2 filename mapping ───────────────────────────────────

const SEASON_FILES: Record<string, string> = {
  advent:       "music/seasons/advent.mp3",
  christmas:    "music/seasons/christmas.mp3",
  ordinary:     "music/seasons/ordinary-time.mp3",
  lent:         "music/seasons/lent.mp3",
  holy_week:    "music/seasons/holy-week.mp3",
  easter:       "music/seasons/easter.mp3",
  pentecost:    "music/seasons/pentecost.mp3",
};

// ── Main exported handler ─────────────────────────────────────────────────────

export async function handleAudioRequest(request: Request, env: AudioEnv): Promise<Response> {
  const url = new URL(request.url);
  const { pathname, method } = url;

  // GET /music/kingdom-ambient/:season → R2 URL
  const ambientMatch = pathname.match(/^\/music\/kingdom-ambient\/([^/]+)$/);
  if (ambientMatch && method === "GET") {
    const season = ambientMatch[1];
    const file = SEASON_FILES[season];
    if (!file) {
      return jsonError(`Season must be one of: ${Object.keys(SEASON_FILES).join(", ")}.`);
    }
    return jsonOk({ url: `${env.R2_ASSETS_BASE_URL}/${file}`, season });
  }

  // GET /music/character/:slug → R2 URL
  const charMatch = pathname.match(/^\/music\/character\/([^/]+)$/);
  if (charMatch && method === "GET") {
    const slug = charMatch[1];
    // Try saints first, then nt/ot — client can fall back
    return jsonOk({
      url: `${env.R2_ASSETS_BASE_URL}/audio/music/characters/${slug}.mp3`,
      slug,
    });
  }

  // POST /audio/narrate-verse, /audio/narrate-story, /audio/saint-voice
  // TTS not yet available — placeholder for future ElevenLabs integration
  if (pathname.startsWith("/audio/") && method === "POST") {
    return jsonError("Audio narration is not yet available.", 501);
  }

  return jsonError("Audio: route not found.", 404);
}
