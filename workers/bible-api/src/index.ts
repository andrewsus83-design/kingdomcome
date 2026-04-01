/**
 * Kingdom Come — Bible API Cloudflare Worker
 *
 * Serves NABRE Bible content:
 *   GET /verse/:id             → single verse by ID
 *   GET /chapter/:book/:chapter → full chapter
 *   GET /verse-of-day          → today's featured verse
 *   GET /search?q=             → full-text search
 */

export interface Env {
  BIBLE_BUCKET: R2Bucket;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
}

// ── CORS ──────────────────────────────────────────────────────────────────────

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function jsonOk(data: unknown, extra?: Record<string, string>): Response {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS, ...(extra ?? {}) },
  });
}

function jsonError(message: string, status = 400): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

// ── R2 helpers ────────────────────────────────────────────────────────────────

async function r2Get<T>(bucket: R2Bucket, key: string): Promise<T | null> {
  const obj = await bucket.get(key);
  if (!obj) return null;
  const text = await obj.text();
  try {
    return JSON.parse(text) as T;
  } catch {
    return null;
  }
}

// ── Supabase REST helper ──────────────────────────────────────────────────────

async function supabaseQuery(
  env: Env,
  table: string,
  params: Record<string, string>
): Promise<unknown[]> {
  const qs = new URLSearchParams(params).toString();
  const url = `${env.SUPABASE_URL}/rest/v1/${table}?${qs}`;
  const res = await fetch(url, {
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) return [];
  return (await res.json()) as unknown[];
}

// ── Verse-of-day seed (deterministic from date) ───────────────────────────────

const FEATURED_VERSE_IDS: string[] = [
  "JN.3.16", "PS.23.1", "MT.6.9", "ROM.8.28", "PHP.4.13",
  "JER.29.11", "IS.40.31", "MT.11.28", "JN.14.6", "1COR.13.4",
  "GAL.5.22", "EPH.6.10", "HEB.11.1", "JAM.1.5", "1JN.4.8",
  "PS.119.105", "PROV.3.5", "MT.5.3", "LK.1.37", "ROM.12.2",
];

function verseOfDayId(): string {
  const now = new Date();
  const dayOfYear = Math.floor(
    (now.getTime() - new Date(now.getFullYear(), 0, 0).getTime()) / 86_400_000
  );
  return FEATURED_VERSE_IDS[dayOfYear % FEATURED_VERSE_IDS.length];
}

// ── Main handler ──────────────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }
    if (request.method !== "GET") {
      return jsonError("Method not allowed.", 405);
    }

    const url = new URL(request.url);
    const { pathname } = url;

    // GET /verse/:id
    const verseMatch = pathname.match(/^\/verse\/([^/]+)$/);
    if (verseMatch) {
      return handleVerse(verseMatch[1], env);
    }

    // GET /chapter/:book/:chapter
    const chapterMatch = pathname.match(/^\/chapter\/([^/]+)\/(\d+)$/);
    if (chapterMatch) {
      return handleChapter(chapterMatch[1], parseInt(chapterMatch[2], 10), env);
    }

    // GET /verse-of-day
    if (pathname === "/verse-of-day") {
      return handleVerseOfDay(env);
    }

    // GET /search
    if (pathname === "/search") {
      const q = url.searchParams.get("q") ?? "";
      return handleSearch(q, env);
    }

    return jsonError("Not found.", 404);
  },
};

// ── Route handlers ────────────────────────────────────────────────────────────

async function handleVerse(verseId: string, env: Env): Promise<Response> {
  // Try R2 first
  const r2Key = `verses/${verseId.toUpperCase()}.json`;
  const cached = await r2Get<unknown>(env.BIBLE_BUCKET, r2Key);
  if (cached) return jsonOk(cached, { "Cache-Control": "public, max-age=86400" });

  // Fall back to Supabase
  const rows = await supabaseQuery(env, "bible_verses", {
    id: `eq.${verseId.toUpperCase()}`,
    select: "id,book,book_abbrev,chapter,verse,text,translation",
    limit: "1",
  });

  if (!rows.length) return jsonError("Verse not found.", 404);
  return jsonOk(rows[0]);
}

async function handleChapter(
  bookAbbrev: string,
  chapterNum: number,
  env: Env
): Promise<Response> {
  const r2Key = `chapters/${bookAbbrev.toUpperCase()}/${chapterNum}.json`;
  const cached = await r2Get<unknown>(env.BIBLE_BUCKET, r2Key);
  if (cached) return jsonOk(cached, { "Cache-Control": "public, max-age=86400" });

  const rows = await supabaseQuery(env, "bible_verses", {
    book_abbrev: `eq.${bookAbbrev.toUpperCase()}`,
    chapter: `eq.${chapterNum}`,
    select: "id,book,book_abbrev,chapter,verse,text",
    order: "verse.asc",
  });

  if (!rows.length) return jsonError("Chapter not found.", 404);

  const chapter = {
    book_abbrev: bookAbbrev.toUpperCase(),
    chapter: chapterNum,
    verses: rows,
  };
  return jsonOk(chapter);
}

async function handleVerseOfDay(env: Env): Promise<Response> {
  const id = verseOfDayId();
  const r2Key = `verses/${id}.json`;
  const cached = await r2Get<unknown>(env.BIBLE_BUCKET, r2Key);
  if (cached) {
    return jsonOk({ verse: cached, date: new Date().toISOString().slice(0, 10) });
  }

  const rows = await supabaseQuery(env, "bible_verses", {
    id: `eq.${id}`,
    select: "id,book,book_abbrev,chapter,verse,text,translation",
    limit: "1",
  });

  if (!rows.length) {
    // Return a hardcoded fallback so the app never breaks
    return jsonOk({
      verse: {
        id: "JN.3.16",
        book: "John",
        book_abbrev: "JN",
        chapter: 3,
        verse: 16,
        text: "For God so loved the world that he gave his only Son, so that everyone who believes in him might not perish but might have eternal life.",
        translation: "NABRE",
      },
      date: new Date().toISOString().slice(0, 10),
    });
  }

  return jsonOk({ verse: rows[0], date: new Date().toISOString().slice(0, 10) });
}

async function handleSearch(query: string, env: Env): Promise<Response> {
  if (!query || query.trim().length < 2) {
    return jsonError("Search query must be at least 2 characters.", 400);
  }

  const sanitized = query.trim().slice(0, 100);

  // Full-text search via Supabase PostgREST
  const rows = await supabaseQuery(env, "bible_verses", {
    text: `fts.${encodeURIComponent(sanitized)}`,
    select: "id,book,book_abbrev,chapter,verse,text",
    limit: "20",
    order: "chapter.asc,verse.asc",
  });

  return jsonOk({ results: rows, query: sanitized, count: rows.length });
}
