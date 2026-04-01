/**
 * Kingdom Come — Modal.com Audio Module (TTS + Music)
 *
 * All audio generation runs on Modal.com using open-source models:
 *   - TTS/Narration: Bark (via modal_setup/tts_app.py)
 *   - Music:         MusicGen by Meta (via modal_setup/music_app.py)
 *
 * Endpoints handled:
 *   POST /music/generate               → generate a Catholic song via MusicGen
 *   POST /music/generate-from-verse    → generate hymn from Bible verse via MusicGen
 *   POST /music/feast-day-song         → generate song for a saint's feast day via MusicGen
 *   GET  /music/kingdom-ambient/:season → get/generate ambient music for liturgical season
 *   POST /narrate                       → TTS narration via Bark
 */

export interface AudioEnv {
  MODAL_API_KEY: string;
  MODAL_TTS_URL: string;
  MODAL_MUSIC_URL: string;
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

// ── Modal.com API wrappers ────────────────────────────────────────────────────

/**
 * Call the Modal MusicGen endpoint.
 * Returns { audio_base64: string } from the Modal function.
 */
async function generateModalMusic(
  prompt: string,
  duration: number,
  apiKey: string,
  musicUrl: string
): Promise<{ audio_base64: string }> {
  const response = await fetch(musicUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ prompt, duration }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Modal MusicGen error ${response.status}: ${err}`);
  }

  return response.json() as Promise<{ audio_base64: string }>;
}

/**
 * Call the Modal Bark TTS endpoint.
 * Returns { audio_base64: string; sample_rate: number } from the Modal function.
 */
async function generateModalTts(
  text: string,
  voicePreset: string,
  apiKey: string,
  ttsUrl: string
): Promise<{ audio_base64: string; sample_rate: number }> {
  const response = await fetch(ttsUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ text, voice_preset: voicePreset }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Modal Bark TTS error ${response.status}: ${err}`);
  }

  return response.json() as Promise<{ audio_base64: string; sample_rate: number }>;
}

// ── Ambient music cache (in-memory per isolate) ───────────────────────────────

const ambientCache = new Map<string, { result: unknown; cachedAt: number }>();
const AMBIENT_CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

// ── Liturgical season prompts ─────────────────────────────────────────────────

const LITURGICAL_SEASON_PROMPTS: Record<string, { prompt: string; duration: number }> = {
  advent: {
    prompt:
      "Peaceful Advent Catholic chant, waiting in joyful hope, purple and gold, O Come O Come Emmanuel mood, " +
      "contemplative Gregorian plainchant blended with gentle orchestral strings",
    duration: 30,
  },
  christmas: {
    prompt:
      "Joyful Christmas Catholic hymn celebrating the birth of Jesus, choir of angels, warm and celebratory, " +
      "traditional Christmas carol energy with bells and strings",
    duration: 30,
  },
  ordinary: {
    prompt:
      "Peaceful Catholic background music for ordinary time, green fields and daily faith, " +
      "gentle contemplative melody with piano and strings, uplifting without being dramatic",
    duration: 30,
  },
  lent: {
    prompt:
      "Solemn Lenten Catholic meditation, desert journey with Christ, sacrifice and hope, " +
      "Miserere tone, minor key, sparse instrumentation, profound and reflective",
    duration: 30,
  },
  easter: {
    prompt:
      "Triumphant Easter Alleluia, Christ is risen, joyful and victorious, full choir and orchestra, " +
      "golden light breaking through darkness, exultant Catholic praise",
    duration: 30,
  },
  pentecost: {
    prompt:
      "Fiery Pentecost celebration, Holy Spirit descends, red and gold, wind and flame, " +
      "vibrant and Spirit-filled contemporary Catholic worship",
    duration: 30,
  },
};

// ── Route handlers ────────────────────────────────────────────────────────────

async function handleGenerate(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
  const duration = typeof body.duration === "number" ? body.duration : 30;
  const title = typeof body.title === "string" ? body.title : "Catholic Hymn";

  if (!prompt) return jsonError("Field 'prompt' is required.");

  // Enrich prompt with Catholic context
  const enrichedPrompt =
    `Catholic sacred music for youth ages 8-18. ${prompt}. ` +
    `Appropriate for church and faith formation. No secular or inappropriate themes.`;

  try {
    const result = await generateModalMusic(
      enrichedPrompt,
      duration,
      env.MODAL_API_KEY,
      env.MODAL_MUSIC_URL
    );
    return jsonOk({ ...result, title: `Kingdom Come — ${title}` });
  } catch (err) {
    console.error("Modal /music/generate error:", err);
    return jsonError("Music generation service temporarily unavailable.", 502);
  }
}

async function handleGenerateFromVerse(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const verseText = typeof body.verseText === "string" ? body.verseText.trim() : "";
  const verseRef = typeof body.verseRef === "string" ? body.verseRef.trim() : "";
  const style = typeof body.style === "string" ? body.style : "hymn";

  if (!verseText) return jsonError("Field 'verseText' is required.");
  if (!verseRef) return jsonError("Field 'verseRef' is required.");

  const validStyles = ["gregorian", "hymn", "contemporary", "kids"];
  if (!validStyles.includes(style)) {
    return jsonError(`Field 'style' must be one of: ${validStyles.join(", ")}.`);
  }

  const styleDescriptions: Record<string, string> = {
    gregorian: "Gregorian chant, ancient Catholic plainchant, monastery choir, sacred and meditative",
    hymn: "traditional Catholic hymn, four-part harmony, organ, reverent and uplifting",
    contemporary: "contemporary Catholic worship, guitar and piano, modern praise, youth-friendly",
    kids: "fun Catholic kids song, simple melody, joyful and bouncy, easy to sing along",
  };

  const prompt =
    `A ${styleDescriptions[style]} setting of this Bible verse: "${verseText}" (${verseRef}). ` +
    `Sacred, Catholic, faith-filled music.`;

  try {
    const result = await generateModalMusic(
      prompt,
      30,
      env.MODAL_API_KEY,
      env.MODAL_MUSIC_URL
    );
    return jsonOk({ ...result, verseRef, verseText });
  } catch (err) {
    console.error("Modal /music/generate-from-verse error:", err);
    return jsonError("Hymn generation service temporarily unavailable.", 502);
  }
}

async function handleFeastDaySong(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const saintName = typeof body.saintName === "string" ? body.saintName.trim() : "";
  const patronage = typeof body.patronage === "string" ? body.patronage.trim() : "";
  const era = typeof body.era === "string" ? body.era.trim() : "unknown era";

  if (!saintName) return jsonError("Field 'saintName' is required.");

  const patronageText = patronage ? `, patron of ${patronage}` : "";

  const prompt =
    `A joyful Catholic feast day hymn celebrating ${saintName}${patronageText}, who lived in the ${era}. ` +
    `Traditional Catholic hymn style, uplifting, suitable for children and youth.`;

  try {
    const result = await generateModalMusic(
      prompt,
      30,
      env.MODAL_API_KEY,
      env.MODAL_MUSIC_URL
    );
    return jsonOk({ ...result, saintName, patronage, era, title: `Feast of ${saintName}` });
  } catch (err) {
    console.error("Modal /music/feast-day-song error:", err);
    return jsonError("Feast day song generation temporarily unavailable.", 502);
  }
}

async function handleKingdomAmbient(season: string, env: AudioEnv): Promise<Response> {
  const validSeasons = ["advent", "christmas", "ordinary", "lent", "easter", "pentecost"];
  if (!validSeasons.includes(season)) {
    return jsonError(`Season must be one of: ${validSeasons.join(", ")}.`);
  }

  // Check in-memory cache
  const cached = ambientCache.get(season);
  if (cached && Date.now() - cached.cachedAt < AMBIENT_CACHE_TTL_MS) {
    return jsonOk({ ...cached.result, cached: true });
  }

  const preset = LITURGICAL_SEASON_PROMPTS[season];

  try {
    const result = await generateModalMusic(
      preset.prompt,
      preset.duration,
      env.MODAL_API_KEY,
      env.MODAL_MUSIC_URL
    );

    const seasonLabel = season.charAt(0).toUpperCase() + season.slice(1);
    const response = { ...result, season, title: `Kingdom Come — ${seasonLabel} Ambient` };
    ambientCache.set(season, { result: response, cachedAt: Date.now() });
    return jsonOk(response);
  } catch (err) {
    console.error(`Modal /music/kingdom-ambient/${season} error:`, err);
    return jsonError("Ambient music generation temporarily unavailable.", 502);
  }
}

async function handleNarrate(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const text = typeof body.text === "string" ? body.text.trim() : "";
  const voicePreset =
    typeof body.voice_preset === "string" ? body.voice_preset : "v2/en_speaker_6";

  if (!text) return jsonError("Field 'text' is required.");

  try {
    const result = await generateModalTts(
      text,
      voicePreset,
      env.MODAL_API_KEY,
      env.MODAL_TTS_URL
    );
    return jsonOk(result);
  } catch (err) {
    console.error("Modal /narrate error:", err);
    return jsonError("Narration service temporarily unavailable.", 502);
  }
}

// ── Main exported handler ─────────────────────────────────────────────────────

export async function handleAudioRequest(request: Request, env: AudioEnv): Promise<Response> {
  const { pathname, method } = request;

  // POST /music/generate
  if (pathname === "/music/generate" && method === "POST") {
    return handleGenerate(request, env);
  }

  // POST /music/generate-from-verse
  if (pathname === "/music/generate-from-verse" && method === "POST") {
    return handleGenerateFromVerse(request, env);
  }

  // POST /music/feast-day-song
  if (pathname === "/music/feast-day-song" && method === "POST") {
    return handleFeastDaySong(request, env);
  }

  // GET /music/kingdom-ambient/:season
  const ambientMatch = pathname.match(/^\/music\/kingdom-ambient\/([^/]+)$/);
  if (ambientMatch && method === "GET") {
    return handleKingdomAmbient(ambientMatch[1], env);
  }

  // POST /music/quest-victory/:category
  const questMatch = pathname.match(/^\/music\/quest-victory\/([^/]+)$/);
  if (questMatch && method === "POST") {
    const category = questMatch[1];
    const prompt =
      `Short triumphant Catholic victory jingle for completing a ${category} quest in a Catholic game for children. ` +
      `Celebratory, sacred, uplifting.`;
    try {
      const result = await generateModalMusic(
        prompt,
        10,
        env.MODAL_API_KEY,
        env.MODAL_MUSIC_URL
      );
      return jsonOk({ ...result, questCategory: category });
    } catch {
      return jsonError("Victory jingle generation temporarily unavailable.", 502);
    }
  }

  // POST /narrate
  if (pathname === "/narrate" && method === "POST") {
    return handleNarrate(request, env);
  }

  return jsonError("Audio: route not found.", 404);
}
