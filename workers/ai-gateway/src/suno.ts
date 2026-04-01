/**
 * Kingdom Come — Suno AI Music Generation Module
 *
 * Endpoints handled:
 *   POST /music/generate               → generate a Catholic song
 *   POST /music/generate-from-verse    → generate hymn from Bible verse
 *   POST /music/feast-day-song         → generate song for a saint's feast day
 *   GET  /music/kingdom-ambient/:season → get/generate ambient music for liturgical season
 */

export interface SunoEnv {
  SUNO_API_KEY: string;
}

// ── Suno API types ────────────────────────────────────────────────────────────

interface SunoGenerateRequest {
  prompt: string;
  style?: string;
  title?: string;
  instrumental?: boolean;
  make_instrumental?: boolean;
  tags?: string;
  wait_audio?: boolean;
}

interface SunoClip {
  id: string;
  audio_url: string;
  video_url?: string;
  title: string;
  metadata?: {
    duration?: number;
    tags?: string;
  };
  duration?: number;
  status: string;
}

interface SunoGenerateResponse {
  clips?: SunoClip[];
  id?: string;
  audio_url?: string;
  video_url?: string;
  title?: string;
  duration?: number;
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

// ── Suno API wrapper ──────────────────────────────────────────────────────────

const SUNO_BASE = "https://api.suno.ai";

async function generateSunoMusic(
  payload: SunoGenerateRequest,
  apiKey: string
): Promise<{ audio_url: string; video_url: string; title: string; duration: number }> {
  const response = await fetch(`${SUNO_BASE}/v2/generate`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      ...payload,
      wait_audio: true, // wait for generation to complete
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Suno API error ${response.status}: ${err}`);
  }

  const data = (await response.json()) as SunoGenerateResponse;

  // Suno returns an array of clips; use the first one
  const clip = data.clips?.[0];
  if (!clip) {
    throw new Error("Suno returned no clips.");
  }

  return {
    audio_url: clip.audio_url,
    video_url: clip.video_url ?? "",
    title: clip.title,
    duration: clip.duration ?? clip.metadata?.duration ?? 0,
  };
}

// ── Ambient music cache (in-memory per isolate) ───────────────────────────────

const ambientCache = new Map<string, { result: unknown; cachedAt: number }>();
const AMBIENT_CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

// ── Style presets ─────────────────────────────────────────────────────────────

const LITURGICAL_SEASON_PROMPTS: Record<string, { prompt: string; style: string; tags: string }> = {
  advent: {
    prompt:
      "Peaceful Advent hymn, waiting in joyful hope, purple and gold, O Come O Come Emmanuel mood, " +
      "contemplative, ancient Catholic chant blended with gentle orchestral",
    style: "gregorian chant orchestral blend",
    tags: "advent, Catholic, hymn, contemplative, orchestral",
  },
  christmas: {
    prompt:
      "Joyful Christmas hymn celebrating the birth of Jesus, choir of angels, warm and celebratory, " +
      "traditional Catholic Christmas carol energy, bells and strings",
    style: "traditional christmas choir orchestral",
    tags: "christmas, Catholic, carol, joyful, choir",
  },
  ordinary: {
    prompt:
      "Peaceful Catholic background music for ordinary time, green fields and daily faith, " +
      "gentle contemplative melody, piano and strings, uplifting without being dramatic",
    style: "contemporary Catholic ambient",
    tags: "ordinary time, Catholic, ambient, peaceful, piano",
  },
  lent: {
    prompt:
      "Solemn Lenten meditation, desert journey with Christ, sacrifice and hope, Miserere tone, " +
      "minor key, sparse instrumentation, profound and reflective",
    style: "gregorian chant solemn meditation",
    tags: "lent, Catholic, solemn, meditation, penitential",
  },
  easter: {
    prompt:
      "Triumphant Easter Alleluia, Christ is risen, joyful and victorious, full choir and orchestra, " +
      "golden light breaking through darkness, exultant praise",
    style: "triumphant choral orchestral",
    tags: "easter, Catholic, alleluia, triumphant, resurrection",
  },
  pentecost: {
    prompt:
      "Fiery Pentecost celebration, Holy Spirit descends, red and gold, Wind and flame, " +
      "vibrant and Spirit-filled, contemporary Catholic worship energy",
    style: "contemporary Catholic worship",
    tags: "pentecost, Catholic, Holy Spirit, vibrant, praise",
  },
};

// ── Route handlers ────────────────────────────────────────────────────────────

async function handleGenerate(request: Request, env: SunoEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
  const style = typeof body.style === "string" ? body.style : "contemporary Catholic";
  const title = typeof body.title === "string" ? body.title : "Catholic Hymn";
  const instrumental = typeof body.instrumental === "boolean" ? body.instrumental : false;

  if (!prompt) return jsonError("Field 'prompt' is required.");

  // Enrich prompt with Catholic context
  const enrichedPrompt =
    `Catholic sacred music for youth ages 8-18. ${prompt}. ` +
    `Appropriate for church and faith formation. No secular or inappropriate themes.`;

  try {
    const result = await generateSunoMusic(
      {
        prompt: enrichedPrompt,
        style,
        title: `Kingdom Come — ${title}`,
        instrumental,
        tags: "Catholic, sacred, faith, youth",
      },
      env.SUNO_API_KEY
    );
    return jsonOk(result);
  } catch (err) {
    console.error("Suno /music/generate error:", err);
    return jsonError("Music generation service temporarily unavailable.", 502);
  }
}

async function handleGenerateFromVerse(request: Request, env: SunoEnv): Promise<Response> {
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
    hymn: "Traditional Catholic hymn, four-part harmony, organ, reverent and uplifting",
    contemporary: "Contemporary Catholic worship, guitar and piano, modern praise, youth-friendly",
    kids: "Fun Catholic kids song, simple melody, joyful and bouncy, easy to sing along",
  };

  const prompt =
    `A ${styleDescriptions[style]} setting of this Bible verse: "${verseText}" (${verseRef}). ` +
    `The lyrics should closely follow the verse text. Sacred, Catholic, faith-filled.`;

  try {
    const result = await generateSunoMusic(
      {
        prompt,
        style: styleDescriptions[style],
        title: `${verseRef} — Sacred Hymn`,
        instrumental: false,
        tags: `Catholic, scripture, hymn, ${style}, ${verseRef}`,
      },
      env.SUNO_API_KEY
    );
    return jsonOk({ ...result, verseRef, verseText });
  } catch (err) {
    console.error("Suno /music/generate-from-verse error:", err);
    return jsonError("Hymn generation service temporarily unavailable.", 502);
  }
}

async function handleFeastDaySong(request: Request, env: SunoEnv): Promise<Response> {
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
    `A joyful Catholic feast day song celebrating ${saintName}${patronageText}, who lived in the ${era}. ` +
    `The song praises their holy life, virtues, and intercession. Uplifting, traditional Catholic hymn style, ` +
    `suitable for children and youth. Include references to their specific patronage and life story.`;

  try {
    const result = await generateSunoMusic(
      {
        prompt,
        style: "traditional Catholic feast day hymn",
        title: `Feast of ${saintName}`,
        instrumental: false,
        tags: `Catholic, saint, feast day, ${saintName}, hymn`,
      },
      env.SUNO_API_KEY
    );
    return jsonOk({ ...result, saintName, patronage, era });
  } catch (err) {
    console.error("Suno /music/feast-day-song error:", err);
    return jsonError("Feast day song generation temporarily unavailable.", 502);
  }
}

async function handleKingdomAmbient(season: string, env: SunoEnv): Promise<Response> {
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
    const result = await generateSunoMusic(
      {
        prompt: preset.prompt,
        style: preset.style,
        title: `Kingdom Come — ${season.charAt(0).toUpperCase() + season.slice(1)} Ambient`,
        instrumental: true, // ambient music is instrumental
        tags: preset.tags,
      },
      env.SUNO_API_KEY
    );

    const response = { ...result, season };
    ambientCache.set(season, { result: response, cachedAt: Date.now() });
    return jsonOk(response);
  } catch (err) {
    console.error(`Suno /music/kingdom-ambient/${season} error:`, err);
    return jsonError("Ambient music generation temporarily unavailable.", 502);
  }
}

// ── Main exported handler ─────────────────────────────────────────────────────

export async function handleSunoRequest(request: Request, env: SunoEnv): Promise<Response> {
  const url = new URL(request.url);
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

  // POST /music/quest-victory/:category (bonus endpoint)
  const questMatch = pathname.match(/^\/music\/quest-victory\/([^/]+)$/);
  if (questMatch && method === "POST") {
    const category = questMatch[1];
    const prompt =
      `Short triumphant Catholic victory jingle for completing a ${category} quest in a Catholic game for children. ` +
      `5-10 seconds, celebratory, sacred, uplifting.`;
    try {
      const result = await generateSunoMusic(
        {
          prompt,
          style: "short victory jingle, sacred, orchestral",
          title: `Victory — ${category}`,
          instrumental: true,
          tags: `Catholic, victory, jingle, ${category}`,
        },
        env.SUNO_API_KEY
      );
      return jsonOk({ ...result, questCategory: category });
    } catch {
      return jsonError("Victory jingle generation temporarily unavailable.", 502);
    }
  }

  return jsonError("Suno: route not found.", 404);
}
