-- ============================================================
-- Migration 004: Saints Tables
-- ============================================================

-- ============================================================
-- ENUM: saint_rarity
-- ============================================================
DO $$ BEGIN
    CREATE TYPE public.saint_rarity AS ENUM (
        'common',
        'uncommon',
        'rare',
        'epic',
        'legendary'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- TABLE: saints
-- ============================================================
CREATE TABLE public.saints (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug                TEXT UNIQUE NOT NULL,   -- e.g. 'francis-of-assisi'
    display_name        TEXT NOT NULL,
    short_bio           TEXT NOT NULL,
    full_bio            TEXT,
    feast_day           TEXT NOT NULL,          -- e.g. 'October 4'
    feast_day_month     SMALLINT CHECK (feast_day_month BETWEEN 1 AND 12),
    feast_day_day       SMALLINT CHECK (feast_day_day   BETWEEN 1 AND 31),
    era                 TEXT NOT NULL,          -- e.g. 'Medieval', 'Early Church'
    patronage           TEXT[],                 -- array of patronage titles
    rarity              public.saint_rarity NOT NULL DEFAULT 'common',

    -- Game unlock mechanics
    unlock_cost_holy_points INTEGER NOT NULL DEFAULT 500 CHECK (unlock_cost_holy_points >= 0),
    required_monastery_level SMALLINT NOT NULL DEFAULT 1 CHECK (required_monastery_level BETWEEN 1 AND 10),

    -- Abilities stored as JSONB for flexibility
    -- Schema: { "passive": {...}, "active": {...} }
    -- passive: { "type": "multiplier|bonus", "resource": "holy_points|faith_coins|grace|xp",
    --            "value": 1.25, "applies_to": "all|prayer|rosary|..." }
    -- active:  { "type": "multiplier|shield|double_rewards", "resource": "...",
    --            "value": 2.0, "duration_hours": 4, "cooldown_hours": 24 }
    abilities           JSONB NOT NULL DEFAULT '{}',

    -- Visual assets
    avatar_url          TEXT,
    card_art_url        TEXT,

    -- Metadata
    is_active           BOOLEAN NOT NULL DEFAULT true,
    sort_order          INTEGER NOT NULL DEFAULT 0,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_saints_rarity       ON public.saints (rarity);
CREATE INDEX idx_saints_feast_month  ON public.saints (feast_day_month, feast_day_day);
CREATE INDEX idx_saints_slug         ON public.saints (slug);

-- ============================================================
-- TABLE: user_saints
-- Tracks which saints a user has unlocked and their active state
-- ============================================================
CREATE TABLE public.user_saints (
    user_id             UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    saint_id            UUID NOT NULL REFERENCES public.saints(id) ON DELETE CASCADE,

    -- When was this saint unlocked
    unlocked_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Active ability tracking
    active_ability_started_at   TIMESTAMPTZ,
    active_ability_ends_at      TIMESTAMPTZ,
    active_ability_last_used_at TIMESTAMPTZ,

    -- Affection / bond level (increases with use)
    bond_level          SMALLINT NOT NULL DEFAULT 1 CHECK (bond_level BETWEEN 1 AND 5),
    total_activations   INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (user_id, saint_id)
);

CREATE INDEX idx_user_saints_user_id      ON public.user_saints (user_id);
CREATE INDEX idx_user_saints_active_until ON public.user_saints (active_ability_ends_at)
    WHERE active_ability_ends_at IS NOT NULL;

-- ============================================================
-- Now add the FK from user_profiles.active_saint_id -> saints.id
-- (could not add during 001 because saints table didn't exist yet)
-- ============================================================
ALTER TABLE public.user_profiles
    ADD CONSTRAINT fk_user_profiles_active_saint
    FOREIGN KEY (active_saint_id) REFERENCES public.saints(id) ON DELETE SET NULL;

-- ============================================================
-- FUNCTION: get_active_saint_multiplier
-- Returns the multiplier of the currently active saint ability
-- for the given user. Returns 1.0 if no active ability running.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_active_saint_multiplier(
    p_user_id UUID
)
RETURNS NUMERIC(4, 2)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_active_saint_id   UUID;
    v_ability_ends_at   TIMESTAMPTZ;
    v_ability_value     NUMERIC(4, 2);
BEGIN
    -- Get user's active saint
    SELECT active_saint_id INTO v_active_saint_id
    FROM public.user_profiles
    WHERE id = p_user_id;

    IF v_active_saint_id IS NULL THEN
        RETURN 1.00;
    END IF;

    -- Check if this user has the saint unlocked and ability is active
    SELECT us.active_ability_ends_at
    INTO v_ability_ends_at
    FROM public.user_saints us
    WHERE us.user_id  = p_user_id
      AND us.saint_id = v_active_saint_id;

    IF v_ability_ends_at IS NULL OR v_ability_ends_at <= NOW() THEN
        RETURN 1.00;
    END IF;

    -- Extract the multiplier value from the saint's active ability
    SELECT COALESCE(
        (s.abilities->'active'->>'value')::NUMERIC(4, 2),
        1.00
    )
    INTO v_ability_value
    FROM public.saints s
    WHERE s.id = v_active_saint_id;

    RETURN COALESCE(v_ability_value, 1.00);
END;
$$;

-- ============================================================
-- FUNCTION: activate_saint_ability
-- Activates a saint's active ability for the given user.
-- Checks cooldown before activating.
-- ============================================================
CREATE OR REPLACE FUNCTION public.activate_saint_ability(
    p_user_id   UUID,
    p_saint_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_saint             public.saints%ROWTYPE;
    v_user_saint        public.user_saints%ROWTYPE;
    v_duration_hours    NUMERIC;
    v_cooldown_hours    NUMERIC;
    v_ends_at           TIMESTAMPTZ;
    v_cooldown_ends_at  TIMESTAMPTZ;
BEGIN
    -- Load saint
    SELECT * INTO v_saint FROM public.saints WHERE id = p_saint_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'saint_not_found');
    END IF;

    -- Check user has this saint unlocked
    SELECT * INTO v_user_saint
    FROM public.user_saints
    WHERE user_id = p_user_id AND saint_id = p_saint_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'saint_not_unlocked');
    END IF;

    -- Extract cooldown and duration
    v_duration_hours := COALESCE((v_saint.abilities->'active'->>'duration_hours')::NUMERIC, 4);
    v_cooldown_hours := COALESCE((v_saint.abilities->'active'->>'cooldown_hours')::NUMERIC, 24);

    -- Check cooldown
    IF v_user_saint.active_ability_last_used_at IS NOT NULL THEN
        v_cooldown_ends_at := v_user_saint.active_ability_last_used_at + (v_cooldown_hours || ' hours')::INTERVAL;
        IF v_cooldown_ends_at > NOW() THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'on_cooldown',
                'cooldown_ends_at', v_cooldown_ends_at
            );
        END IF;
    END IF;

    v_ends_at := NOW() + (v_duration_hours || ' hours')::INTERVAL;

    -- Activate
    UPDATE public.user_saints
    SET
        active_ability_started_at   = NOW(),
        active_ability_ends_at      = v_ends_at,
        active_ability_last_used_at = NOW(),
        total_activations           = total_activations + 1
    WHERE user_id = p_user_id AND saint_id = p_saint_id;

    -- Set as active saint on profile
    UPDATE public.user_profiles
    SET active_saint_id = p_saint_id
    WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'ability_ends_at', v_ends_at,
        'duration_hours', v_duration_hours
    );
END;
$$;

COMMENT ON TABLE public.saints IS
    'Catalog of all Catholic saints available in the game as companions.';
COMMENT ON TABLE public.user_saints IS
    'Junction table tracking which saints each user has unlocked and their active ability state.';
