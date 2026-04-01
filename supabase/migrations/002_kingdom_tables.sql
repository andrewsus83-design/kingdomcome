-- ============================================================
-- Migration 002: Kingdom & Buildings Tables
-- ============================================================

-- ============================================================
-- ENUM: building_type
-- ============================================================
DO $$ BEGIN
    CREATE TYPE public.building_type AS ENUM (
        'chapel',           -- prayer bonuses
        'scriptorium',      -- Bible study bonuses
        'monastery',        -- saint unlock bonuses
        'garden',           -- daily grace income
        'bell_tower',       -- streak multiplier
        'cathedral',        -- prestige, unlocks advanced quests
        'school',           -- quiz XP bonuses
        'workshop',         -- arts & crafts unlocks
        'parish_hall',      -- community / parish bonuses
        'oratory'           -- rosary bonuses
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- TABLE: kingdoms
-- ============================================================
CREATE TABLE public.kingdoms (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name        TEXT NOT NULL DEFAULT 'My Kingdom',
    level       SMALLINT NOT NULL DEFAULT 1 CHECK (level >= 1),
    land_size   SMALLINT NOT NULL DEFAULT 5 CHECK (land_size BETWEEN 5 AND 50),
    banner_url  TEXT,
    founded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kingdoms_user_id ON public.kingdoms (user_id);

-- ============================================================
-- TABLE: buildings
-- ============================================================
CREATE TABLE public.buildings (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kingdom_id              UUID NOT NULL REFERENCES public.kingdoms(id) ON DELETE CASCADE,
    building_type           public.building_type NOT NULL,

    -- Grid placement
    grid_x                  SMALLINT NOT NULL CHECK (grid_x >= 0),
    grid_y                  SMALLINT NOT NULL CHECK (grid_y >= 0),

    -- Building state
    level                   SMALLINT NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 10),
    is_under_construction   BOOLEAN NOT NULL DEFAULT false,
    construction_started_at TIMESTAMPTZ,
    construction_completes_at TIMESTAMPTZ,

    -- Appearance
    skin_id                 TEXT,

    -- Timestamps
    built_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    upgraded_at             TIMESTAMPTZ,

    -- Each grid cell in a kingdom can only hold one building
    CONSTRAINT uq_building_grid_position UNIQUE (kingdom_id, grid_x, grid_y)
);

CREATE INDEX idx_buildings_kingdom_id       ON public.buildings (kingdom_id);
CREATE INDEX idx_buildings_type             ON public.buildings (building_type);
CREATE INDEX idx_buildings_construction     ON public.buildings (construction_completes_at)
    WHERE is_under_construction = true;

-- ============================================================
-- FUNCTION: complete_building_construction
-- Marks a building as complete when its timer has passed
-- ============================================================
CREATE OR REPLACE FUNCTION public.complete_building_construction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- If the construction timestamp is set and now in the past, auto-complete
    IF NEW.construction_completes_at IS NOT NULL
       AND NEW.construction_completes_at <= NOW()
       AND NEW.is_under_construction = true
    THEN
        NEW.is_under_construction    := false;
        NEW.construction_started_at  := NULL;
        NEW.construction_completes_at := NULL;
        NEW.upgraded_at              := NOW();
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_building_construction_complete
    BEFORE UPDATE ON public.buildings
    FOR EACH ROW
    EXECUTE FUNCTION public.complete_building_construction();

-- ============================================================
-- FUNCTION: check_and_complete_constructions
-- Called periodically (e.g., via cron) to bulk-complete any
-- buildings whose timer has passed.
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_and_complete_constructions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE public.buildings
    SET
        is_under_construction     = false,
        construction_started_at   = NULL,
        construction_completes_at = NULL,
        upgraded_at               = NOW()
    WHERE
        is_under_construction = true
        AND construction_completes_at <= NOW();

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- ============================================================
-- FUNCTION: get_kingdom_building_level
-- Returns the level of a specific building type in a kingdom,
-- or 0 if it doesn't exist. Used by quest filtering.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_kingdom_building_level(
    p_user_id      UUID,
    p_building_type public.building_type
)
RETURNS SMALLINT
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(
        (SELECT b.level
         FROM public.buildings b
         JOIN public.kingdoms k ON k.id = b.kingdom_id
         WHERE k.user_id = p_user_id
           AND b.building_type = p_building_type
           AND b.is_under_construction = false
         ORDER BY b.level DESC
         LIMIT 1),
        0::SMALLINT
    );
$$;

-- ============================================================
-- Auto-create a kingdom when a user_profile is inserted
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_kingdom()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.kingdoms (user_id, name)
    VALUES (NEW.id, COALESCE(NEW.display_name, NEW.username, 'My Kingdom') || '''s Kingdom')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_create_kingdom_on_profile
    AFTER INSERT ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_kingdom();

COMMENT ON TABLE public.kingdoms IS
    'Each user owns exactly one kingdom. The kingdom grows with the player''s level.';
COMMENT ON TABLE public.buildings IS
    'Buildings placed on a kingdom grid. Each grid cell is unique per kingdom.';
