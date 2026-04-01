/**
 * Kingdom Come — Audio Module (ElevenLabs TTS + MusicGen via Modal.com)
 *
 * Endpoints handled:
 *   POST /audio/narrate-verse    → ElevenLabs TTS for a Bible verse
 *   POST /audio/narrate-story    → ElevenLabs TTS for Bible story panel text
 *   POST /audio/saint-voice      → Saint narrator voice via ElevenLabs
 *   POST /music/ambient          → Ambient music via MusicGen on Modal.com
 *   POST /music/victory-jingle   → Short victory music via MusicGen on Modal.com
 */

export interface AudioEnv {
  ELEVENLABS_API_KEY: string;
  MODAL_API_KEY: string;
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

// ── ElevenLabs constants ──────────────────────────────────────────────────────

const ELEVENLABS_BASE = "https://api.elevenlabs.io";

// Saint → ElevenLabs voice ID map
// Each saint has a voice that matches their character.
const SAINT_VOICE_IDS: Record<string, string> = {
  "St. Francis":        "21m00Tcm4TlvDq8ikWAM", // warm, gentle
  "St. Joan of Arc":    "AZnzlk1XvdvUeBnXmlld", // strong, confident
  "St. Therese":        "EXAVITQu4vr4xnSDxMaL", // soft, young
  "St. Thomas Aquinas": "ErXwobaYiN019PkySvjV", // scholarly, calm
  "St. Dominic":        "VR6AewLTigWG4xSOukaG", // preacher, resonant
};

const DEFAULT_VOICE_ID = "pNInz6obpgDQGcFmaJgB"; // neutral, clear

function resolveVoiceId(saintName?: string): string {
  if (!saintName) return DEFAULT_VOICE_ID;
  return SAINT_VOICE_IDS[saintName] ?? DEFAULT_VOICE_ID;
}

// ── ElevenLabs TTS wrapper ────────────────────────────────────────────────────

interface ElevenLabsTtsResult {
  audioUrl: string;
  durationSeconds: number;
}

async function callElevenLabsTts(
  text: string,
  voiceId: string,
  apiKey: string
): Promise<ElevenLabsTtsResult> {
  const response = await fetch(
    `${ELEVENLABS_BASE}/v1/text-to-speech/${voiceId}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "xi-api-key": apiKey,
      },
      body: JSON.stringify({
        text,
        model_id: "eleven_turbo_v2",
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.75,
          style: 0.0,
          use_speaker_boost: true,
        },
      }),
    }
  );

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`ElevenLabs API error ${response.status}: ${err}`);
  }

  // ElevenLabs returns raw audio bytes; we convert to a data URI so the
  // Flutter client can play it directly without a separate storage step.
  const audioBuffer = await response.arrayBuffer();
  const base64 = btoa(
    String.fromCharCode(...new Uint8Array(audioBuffer))
  );
  const audioUrl = `data:audio/mpeg;base64,${base64}`;

  // Estimate duration: ~150 words/min, average 5 chars/word
  const wordCount = text.trim().split(/\s+/).length;
  const durationSeconds = Math.ceil((wordCount / 150) * 60);

  return { audioUrl, durationSeconds };
}

// ── MusicGen (Modal.com) wrapper ──────────────────────────────────────────────

interface MusicGenResult {
  audioUrl: string;
  durationSeconds: number;
  prompt: string;
}

async function callMusicGen(
  prompt: string,
  durationSeconds: number,
  apiKey: string
): Promise<MusicGenResult> {
  const response = await fetch(
    "https://modal-labs--kingdom-come-musicgen.modal.run/generate",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        prompt,
        duration: durationSeconds,
        model: "facebook/musicgen-medium",
        top_k: 250,
        top_p: 0.0,
        temperature: 1.0,
        cfg_coef: 3.0,
      }),
    }
  );

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`MusicGen Modal error ${response.status}: ${err}`);
  }

  const data = (await response.json()) as { audio_url?: string; url?: string };
  const audioUrl = data.audio_url ?? data.url ?? "";
  if (!audioUrl) throw new Error("MusicGen returned no audio URL.");

  return { audioUrl, durationSeconds, prompt };
}

// ── Liturgical season prompt map ──────────────────────────────────────────────

const SEASON_PROMPTS: Record<string, string> = {
  advent:    "Gregorian chant advent liturgical Catholic peaceful ambient, contemplative waiting, O Come O Come Emmanuel",
  christmas: "Gregorian chant christmas liturgical Catholic joyful ambient, bells and strings, Gloria in Excelsis Deo",
  ordinary:  "Gregorian chant ordinary time liturgical Catholic peaceful ambient, gentle contemplative melody, daily faith",
  lent:      "Gregorian chant lent liturgical Catholic solemn ambient, Miserere, desert journey, penitential reflection",
  easter:    "Gregorian chant easter liturgical Catholic triumphant ambient, Alleluia, resurrection joy, full and bright",
  pentecost: "Gregorian chant pentecost liturgical Catholic vibrant ambient, Holy Spirit, wind and fire, Spirit-filled praise",
};

// ── Route handlers ────────────────────────────────────────────────────────────

async function handleNarrateVerse(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const text = typeof body.text === "string" ? body.text.trim() : "";
  const verseRef = typeof body.verseRef === "string" ? body.verseRef.trim() : "";
  const voiceId =
    typeof body.voiceId === "string"
      ? body.voiceId.trim()
      : typeof body.saintNarratorId === "string"
      ? resolveVoiceId(body.saintNarratorId as string)
      : DEFAULT_VOICE_ID;

  if (!text) return jsonError("Field 'text' is required.");
  if (!verseRef) return jsonError("Field 'verseRef' is required.");

  // Wrap in a clean reading style preamble
  const narrationText = `${verseRef}. ${text}`;

  try {
    const result = await callElevenLabsTts(narrationText, voiceId, env.ELEVENLABS_API_KEY);
    return jsonOk({ ...result, verseRef });
  } catch (err) {
    console.error("ElevenLabs /audio/narrate-verse error:", err);
    return jsonError("Voice narration service temporarily unavailable.", 502);
  }
}

async function handleNarrateStory(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const text = typeof body.text === "string" ? body.text.trim() : "";
  const saintNarratorId = typeof body.saintNarratorId === "string" ? body.saintNarratorId.trim() : "";

  if (!text) return jsonError("Field 'text' is required.");

  const voiceId = resolveVoiceId(saintNarratorId || undefined);

  try {
    const result = await callElevenLabsTts(text, voiceId, env.ELEVENLABS_API_KEY);
    return jsonOk({ ...result, saintNarratorId: saintNarratorId || null });
  } catch (err) {
    console.error("ElevenLabs /audio/narrate-story error:", err);
    return jsonError("Story narration service temporarily unavailable.", 502);
  }
}

async function handleSaintVoice(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const saintName = typeof body.saintName === "string" ? body.saintName.trim() : "";
  const text = typeof body.text === "string" ? body.text.trim() : "";

  if (!saintName) return jsonError("Field 'saintName' is required.");
  if (!text) return jsonError("Field 'text' is required.");

  const voiceId = resolveVoiceId(saintName);

  try {
    const result = await callElevenLabsTts(text, voiceId, env.ELEVENLABS_API_KEY);
    return jsonOk({ ...result, saintName, voiceId });
  } catch (err) {
    console.error("ElevenLabs /audio/saint-voice error:", err);
    return jsonError("Saint voice narration temporarily unavailable.", 502);
  }
}

async function handleAmbientMusic(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const season = typeof body.season === "string" ? body.season.trim().toLowerCase() : "";
  const duration = typeof body.duration === "number" ? Math.min(body.duration, 300) : 60;

  const validSeasons = Object.keys(SEASON_PROMPTS);
  if (!season || !validSeasons.includes(season)) {
    return jsonError(`Field 'season' must be one of: ${validSeasons.join(", ")}.`);
  }

  const prompt = SEASON_PROMPTS[season];

  try {
    const result = await callMusicGen(prompt, duration, env.MODAL_API_KEY);
    return jsonOk({ ...result, season });
  } catch (err) {
    console.error("MusicGen /music/ambient error:", err);
    return jsonError("Ambient music generation temporarily unavailable.", 502);
  }
}

async function handleVictoryJingle(request: Request, env: AudioEnv): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError("Invalid JSON body.");
  }

  const questCategory = typeof body.questCategory === "string" ? body.questCategory.trim() : "";
  if (!questCategory) return jsonError("Field 'questCategory' is required.");

  const prompt =
    `Short triumphant Catholic victory jingle for completing a ${questCategory} quest, ` +
    `sacred orchestral fanfare, 5 seconds, celebratory and uplifting, Gregorian chant influence`;

  try {
    const result = await callMusicGen(prompt, 5, env.MODAL_API_KEY);
    return jsonOk({ ...result, questCategory });
  } catch (err) {
    console.error("MusicGen /music/victory-jingle error:", err);
    return jsonError("Victory jingle generation temporarily unavailable.", 502);
  }
}

// ── Main exported handler ─────────────────────────────────────────────────────

export async function handleAudioRequest(request: Request, env: AudioEnv): Promise<Response> {
  const { pathname, method } = request;

  // POST /audio/narrate-verse
  if (pathname === "/audio/narrate-verse" && method === "POST") {
    return handleNarrateVerse(request, env);
  }

  // POST /audio/narrate-story
  if (pathname === "/audio/narrate-story" && method === "POST") {
    return handleNarrateStory(request, env);
  }

  // POST /audio/saint-voice
  if (pathname === "/audio/saint-voice" && method === "POST") {
    return handleSaintVoice(request, env);
  }

  // POST /music/ambient
  if (pathname === "/music/ambient" && method === "POST") {
    return handleAmbientMusic(request, env);
  }

  // POST /music/victory-jingle
  if (pathname === "/music/victory-jingle" && method === "POST") {
    return handleVictoryJingle(request, env);
  }

  return jsonError("Audio: route not found.", 404);
}
