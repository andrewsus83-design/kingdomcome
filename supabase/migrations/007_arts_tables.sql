-- ============================================================
-- Migration 007: Arts & Crafts Tables
-- ============================================================

-- ============================================================
-- ENUM: artwork_type
-- ============================================================
DO $$ BEGIN
    CREATE TYPE public.artwork_type AS ENUM (
        'drawing',
        'painting',
        'collage',
        'digital_art',
        'craft',
        'calligraphy',
        'icon_writing',
        'photography',
        'other'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- TABLE: artworks
-- User-created religious arts & crafts
-- ============================================================
CREATE TABLE public.artworks (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,

    title                   TEXT NOT NULL,
    description             TEXT,
    artwork_type            public.artwork_type NOT NULL DEFAULT 'drawing',

    -- Storage
    image_url               TEXT NOT NULL,
    thumbnail_url           TEXT,

    -- Inspiration / theme
    inspired_by_saint_id    UUID REFERENCES public.saints(id) ON DELETE SET NULL,
    inspired_by_verse_id    TEXT REFERENCES public.bible_verses(id) ON DELETE SET NULL,
    theme_tags              TEXT[] NOT NULL DEFAULT '{}',

    -- Quest link (artwork created as part of a quest)
    quest_completion_id     UUID REFERENCES public.quest_completions(id) ON DELETE SET NULL,

    -- Community visibility
    displayed_in_kingdom    BOOLEAN NOT NULL DEFAULT false,  -- show in user's public kingdom
    is_community_featured   BOOLEAN NOT NULL DEFAULT false,  -- admin-featured

    -- Moderation
    moderation_status       TEXT NOT NULL DEFAULT 'pending'
                                CHECK (moderation_status IN ('pending', 'approved', 'rejected')),
    moderated_at            TIMESTAMPTZ,
    moderated_by            UUID,                            -- admin user_id

    -- Engagement
    likes_count             INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_artworks_user_id           ON public.artworks (user_id);
CREATE INDEX idx_artworks_type              ON public.artworks (artwork_type);
CREATE INDEX idx_artworks_displayed         ON public.artworks (displayed_in_kingdom)
    WHERE displayed_in_kingdom = true;
CREATE INDEX idx_artworks_community         ON public.artworks (is_community_featured)
    WHERE is_community_featured = true;
CREATE INDEX idx_artworks_moderation        ON public.artworks (moderation_status);
CREATE INDEX idx_artworks_saint             ON public.artworks (inspired_by_saint_id)
    WHERE inspired_by_saint_id IS NOT NULL;
CREATE INDEX idx_artworks_created           ON public.artworks (created_at DESC);

-- ============================================================
-- FUNCTION: update_artworks_updated_at
-- Keeps updated_at fresh on modifications
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_artworks_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_artworks_updated_at
    BEFORE UPDATE ON public.artworks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_artworks_updated_at();

-- ============================================================
-- TABLE: artwork_likes
-- Tracks which users have liked which artworks (unique per user)
-- ============================================================
CREATE TABLE public.artwork_likes (
    artwork_id  UUID NOT NULL REFERENCES public.artworks(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    liked_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (artwork_id, user_id)
);

CREATE INDEX idx_artwork_likes_user ON public.artwork_likes (user_id);

-- ============================================================
-- FUNCTION: toggle_artwork_like
-- Atomically toggle a like and update the denormalized count
-- ============================================================
CREATE OR REPLACE FUNCTION public.toggle_artwork_like(
    p_user_id   UUID,
    p_artwork_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_liked BOOLEAN := false;
BEGIN
    -- Try to insert a like
    BEGIN
        INSERT INTO public.artwork_likes (artwork_id, user_id)
        VALUES (p_artwork_id, p_user_id);

        UPDATE public.artworks
        SET likes_count = likes_count + 1
        WHERE id = p_artwork_id;

        v_liked := true;
    EXCEPTION WHEN unique_violation THEN
        -- Already liked, so unlike
        DELETE FROM public.artwork_likes
        WHERE artwork_id = p_artwork_id AND user_id = p_user_id;

        UPDATE public.artworks
        SET likes_count = GREATEST(0, likes_count - 1)
        WHERE id = p_artwork_id;

        v_liked := false;
    END;

    RETURN jsonb_build_object('liked', v_liked);
END;
$$;

COMMENT ON TABLE public.artworks IS
    'User-created religious artwork and craft submissions.';
COMMENT ON TABLE public.artwork_likes IS
    'Tracks community likes on artworks (one per user per artwork).';
