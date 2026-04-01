-- ============================================================
-- Migration 005: Bible Tables
-- ============================================================

-- ============================================================
-- TABLE: bible_books
-- ============================================================
CREATE TABLE public.bible_books (
    id              SERIAL PRIMARY KEY,
    abbrev          TEXT UNIQUE NOT NULL,   -- e.g. 'GEN', 'MT', 'JN'
    name            TEXT NOT NULL,          -- e.g. 'Genesis', 'Matthew'
    testament       TEXT NOT NULL CHECK (testament IN ('old', 'new')),
    book_order      SMALLINT NOT NULL,      -- canonical order (1-73 for Catholic canon)
    chapter_count   SMALLINT NOT NULL CHECK (chapter_count > 0),
    description     TEXT,

    CONSTRAINT uq_bible_books_order UNIQUE (book_order)
);

CREATE INDEX idx_bible_books_testament ON public.bible_books (testament);
CREATE INDEX idx_bible_books_order     ON public.bible_books (book_order);

-- ============================================================
-- TABLE: bible_verses
-- ID format: "GEN.1.1" (book_abbrev.chapter.verse)
-- ============================================================
CREATE TABLE public.bible_verses (
    id              TEXT PRIMARY KEY,           -- e.g. 'GEN.1.1'
    book_abbrev     TEXT NOT NULL REFERENCES public.bible_books(abbrev) ON DELETE CASCADE,
    chapter_num     SMALLINT NOT NULL CHECK (chapter_num > 0),
    verse_num       SMALLINT NOT NULL CHECK (verse_num > 0),
    verse_text      TEXT NOT NULL,              -- NABRE translation
    thematic_tags   TEXT[] NOT NULL DEFAULT '{}',
    is_verse_of_day_candidate BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT uq_bible_verse_ref UNIQUE (book_abbrev, chapter_num, verse_num)
);

CREATE INDEX idx_bible_verses_book_chapter  ON public.bible_verses (book_abbrev, chapter_num);
CREATE INDEX idx_bible_verses_tags          ON public.bible_verses USING GIN (thematic_tags);
CREATE INDEX idx_bible_verses_votd_candidate ON public.bible_verses (is_verse_of_day_candidate)
    WHERE is_verse_of_day_candidate = true;

-- ============================================================
-- TABLE: verse_of_day
-- ============================================================
CREATE TABLE public.verse_of_day (
    id                  SERIAL PRIMARY KEY,
    verse_id            TEXT NOT NULL REFERENCES public.bible_verses(id) ON DELETE CASCADE,
    scheduled_for       DATE NOT NULL UNIQUE,
    liturgical_context  TEXT,               -- brief note, e.g. "3rd Sunday of Advent"
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verse_of_day_scheduled ON public.verse_of_day (scheduled_for DESC);

-- ============================================================
-- TABLE: user_reading_progress
-- Tracks how far a user has read in each book
-- ============================================================
CREATE TABLE public.user_reading_progress (
    user_id             UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    book_abbrev         TEXT NOT NULL REFERENCES public.bible_books(abbrev) ON DELETE CASCADE,

    last_chapter_read   SMALLINT NOT NULL DEFAULT 1 CHECK (last_chapter_read > 0),
    last_verse_read     SMALLINT NOT NULL DEFAULT 1 CHECK (last_verse_read > 0),
    chapters_completed  SMALLINT NOT NULL DEFAULT 0,
    is_book_completed   BOOLEAN NOT NULL DEFAULT false,
    started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_read_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, book_abbrev)
);

CREATE INDEX idx_reading_progress_user  ON public.user_reading_progress (user_id);
CREATE INDEX idx_reading_progress_book  ON public.user_reading_progress (book_abbrev);

-- ============================================================
-- TABLE: user_verse_highlights
-- Allows users to highlight and annotate specific verses
-- ============================================================
CREATE TABLE public.user_verse_highlights (
    user_id         UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    verse_id        TEXT NOT NULL REFERENCES public.bible_verses(id) ON DELETE CASCADE,

    color           TEXT NOT NULL DEFAULT 'yellow'
                        CHECK (color IN ('yellow', 'green', 'blue', 'pink', 'orange', 'purple')),
    note            TEXT,                   -- user's personal reflection note
    is_favorite     BOOLEAN NOT NULL DEFAULT false,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, verse_id)
);

CREATE INDEX idx_verse_highlights_user      ON public.user_verse_highlights (user_id);
CREATE INDEX idx_verse_highlights_favorite  ON public.user_verse_highlights (user_id, is_favorite)
    WHERE is_favorite = true;

-- ============================================================
-- FUNCTION: get_verse_of_day
-- Returns today's verse, falling back to a random candidate
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_verse_of_day(p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    verse_id        TEXT,
    book_abbrev     TEXT,
    chapter_num     SMALLINT,
    verse_num       SMALLINT,
    verse_text      TEXT,
    thematic_tags   TEXT[],
    liturgical_context TEXT,
    book_name       TEXT,
    testament       TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        bv.id           AS verse_id,
        bv.book_abbrev,
        bv.chapter_num,
        bv.verse_num,
        bv.verse_text,
        bv.thematic_tags,
        vod.liturgical_context,
        bb.name         AS book_name,
        bb.testament
    FROM public.verse_of_day vod
    JOIN public.bible_verses bv ON bv.id = vod.verse_id
    JOIN public.bible_books  bb ON bb.abbrev = bv.book_abbrev
    WHERE vod.scheduled_for = p_date
    LIMIT 1;

    -- If nothing scheduled, return a random candidate verse
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            bv.id,
            bv.book_abbrev,
            bv.chapter_num,
            bv.verse_num,
            bv.verse_text,
            bv.thematic_tags,
            NULL::TEXT,
            bb.name,
            bb.testament
        FROM public.bible_verses bv
        JOIN public.bible_books  bb ON bb.abbrev = bv.book_abbrev
        WHERE bv.is_verse_of_day_candidate = true
        ORDER BY RANDOM()
        LIMIT 1;
    END IF;
END;
$$;

-- ============================================================
-- FUNCTION: update_reading_progress
-- Upserts user reading progress for a book
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_reading_progress(
    p_user_id       UUID,
    p_book_abbrev   TEXT,
    p_chapter       SMALLINT,
    p_verse         SMALLINT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_chapter_count SMALLINT;
BEGIN
    SELECT chapter_count INTO v_chapter_count
    FROM public.bible_books WHERE abbrev = p_book_abbrev;

    INSERT INTO public.user_reading_progress (
        user_id, book_abbrev, last_chapter_read, last_verse_read,
        chapters_completed, is_book_completed, started_at, last_read_at
    )
    VALUES (
        p_user_id, p_book_abbrev, p_chapter, p_verse,
        CASE WHEN p_chapter > 1 THEN p_chapter - 1 ELSE 0 END,
        (p_chapter >= v_chapter_count),
        NOW(), NOW()
    )
    ON CONFLICT (user_id, book_abbrev) DO UPDATE SET
        last_chapter_read  = GREATEST(EXCLUDED.last_chapter_read, user_reading_progress.last_chapter_read),
        last_verse_read    = CASE
                                WHEN EXCLUDED.last_chapter_read > user_reading_progress.last_chapter_read
                                THEN EXCLUDED.last_verse_read
                                ELSE GREATEST(EXCLUDED.last_verse_read, user_reading_progress.last_verse_read)
                             END,
        chapters_completed = GREATEST(
                                EXCLUDED.chapters_completed,
                                user_reading_progress.chapters_completed
                             ),
        is_book_completed  = (GREATEST(EXCLUDED.last_chapter_read, user_reading_progress.last_chapter_read) >= v_chapter_count),
        last_read_at       = NOW();
END;
$$;

COMMENT ON TABLE public.bible_books IS
    'Complete Catholic canon (73 books) metadata.';
COMMENT ON TABLE public.bible_verses IS
    'Full Bible text in NABRE translation, keyed by GEN.1.1 style IDs.';
COMMENT ON TABLE public.verse_of_day IS
    'Pre-scheduled daily verses, optionally tied to liturgical context.';
