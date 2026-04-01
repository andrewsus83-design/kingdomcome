-- ============================================================
-- Migration 003: Quest Tables
-- ============================================================

-- ============================================================
-- ENUMs
-- ============================================================
DO $$ BEGIN
    CREATE TYPE public.quest_category AS ENUM (
        'prayer',
        'rosary',
        'bible_reading',
        'good_deed',
        'mass_attendance',
        'confession',
        'quiz',
        'liturgical_event',
        'arts_crafts',
        'community'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.quest_difficulty AS ENUM (
        'easy',
        'medium',
        'hard',
        'heroic'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.verification_type AS ENUM (
        'self_report',       -- user taps complete
        'photo_proof',       -- user uploads image
        'quiz_completion',   -- linked quiz must be passed
        'location_check',    -- geofenced to parish
        'parent_confirm',    -- parent must approve
        'time_based'         -- must be open for X minutes
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.repeat_frequency AS ENUM (
        'once',
        'daily',
        'weekly',
        'monthly',
        'liturgical_season'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- TABLE: quests
-- ============================================================
CREATE TABLE public.quests (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title               TEXT NOT NULL,
    description         TEXT NOT NULL,
    instructions        TEXT,                   -- step-by-step guide
    category            public.quest_category NOT NULL,
    difficulty          public.quest_difficulty NOT NULL DEFAULT 'easy',
    verification_type   public.verification_type NOT NULL DEFAULT 'self_report',
    repeat_frequency    public.repeat_frequency NOT NULL DEFAULT 'daily',

    -- Seasonal / day constraints
    day_of_week         SMALLINT CHECK (day_of_week BETWEEN 0 AND 6), -- NULL = any day; 0=Sun
    liturgical_season   TEXT,                   -- 'advent','lent','easter','ordinary' or NULL
    available_from      DATE,
    available_until     DATE,

    -- Requirements
    min_age_group       SMALLINT NOT NULL DEFAULT 1 CHECK (min_age_group BETWEEN 1 AND 3),
    min_level           SMALLINT NOT NULL DEFAULT 1 CHECK (min_level >= 1),
    required_building   public.building_type,   -- NULL = no building req
    required_building_level SMALLINT DEFAULT 1,

    -- Linked quiz (when verification_type = 'quiz_completion')
    linked_quiz_id      UUID,                   -- FK added in 006

    -- Rewards
    holy_points_reward  INTEGER NOT NULL DEFAULT 10 CHECK (holy_points_reward >= 0),
    faith_coins_reward  INTEGER NOT NULL DEFAULT 0  CHECK (faith_coins_reward >= 0),
    grace_reward        INTEGER NOT NULL DEFAULT 0  CHECK (grace_reward >= 0),
    blessings_reward    INTEGER NOT NULL DEFAULT 0  CHECK (blessings_reward >= 0),
    xp_reward           INTEGER NOT NULL DEFAULT 5  CHECK (xp_reward >= 0),

    -- Metadata
    icon_name           TEXT,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    is_featured         BOOLEAN NOT NULL DEFAULT false,
    sort_order          INTEGER NOT NULL DEFAULT 0,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quests_category       ON public.quests (category);
CREATE INDEX idx_quests_difficulty     ON public.quests (difficulty);
CREATE INDEX idx_quests_is_active      ON public.quests (is_active) WHERE is_active = true;
CREATE INDEX idx_quests_liturgical     ON public.quests (liturgical_season) WHERE liturgical_season IS NOT NULL;
CREATE INDEX idx_quests_day_of_week    ON public.quests (day_of_week) WHERE day_of_week IS NOT NULL;

-- ============================================================
-- TABLE: quest_completions
-- ============================================================
CREATE TABLE public.quest_completions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    quest_id        UUID NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,

    -- What was actually awarded (may differ from base due to multipliers)
    holy_points_awarded INTEGER NOT NULL DEFAULT 0,
    faith_coins_awarded INTEGER NOT NULL DEFAULT 0,
    grace_awarded       INTEGER NOT NULL DEFAULT 0,
    blessings_awarded   INTEGER NOT NULL DEFAULT 0,
    xp_awarded          INTEGER NOT NULL DEFAULT 0,

    -- Multiplier applied (from active saint, streak, etc.)
    multiplier_applied  NUMERIC(4,2) NOT NULL DEFAULT 1.00,

    -- Proof
    proof_url       TEXT,
    notes           TEXT,

    -- Status
    verified        BOOLEAN NOT NULL DEFAULT false,
    verified_at     TIMESTAMPTZ,
    verified_by     UUID,                       -- NULL = auto-verified

    completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quest_completions_user_id     ON public.quest_completions (user_id);
CREATE INDEX idx_quest_completions_quest_id    ON public.quest_completions (quest_id);
CREATE INDEX idx_quest_completions_completed   ON public.quest_completions (user_id, completed_at DESC);

-- ============================================================
-- UNIQUE PARTIAL INDEX: prevent duplicate DAILY completions
-- A user can only complete a 'daily' quest once per calendar day.
-- ============================================================
CREATE UNIQUE INDEX uq_daily_quest_completion_per_day
    ON public.quest_completions (user_id, quest_id, (completed_at::DATE))
    WHERE (
        quest_id IN (
            SELECT id FROM public.quests WHERE repeat_frequency = 'daily'
        )
    );

-- ============================================================
-- FUNCTION: get_available_quests
-- Returns quests available to a given user, filtered by:
--   - active flag
--   - age_group requirement
--   - user's current level
--   - current day of week
--   - liturgical season (passed as parameter)
--   - required building (if any) present and complete in kingdom
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_available_quests(
    p_user_id  UUID,
    p_season   TEXT DEFAULT NULL
)
RETURNS TABLE (
    quest_id            UUID,
    title               TEXT,
    description         TEXT,
    instructions        TEXT,
    category            public.quest_category,
    difficulty          public.quest_difficulty,
    verification_type   public.verification_type,
    repeat_frequency    public.repeat_frequency,
    holy_points_reward  INTEGER,
    faith_coins_reward  INTEGER,
    grace_reward        INTEGER,
    blessings_reward    INTEGER,
    xp_reward           INTEGER,
    icon_name           TEXT,
    already_completed_today BOOLEAN,
    times_completed_total   BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_age_group     SMALLINT;
    v_level         SMALLINT;
    v_today_dow     SMALLINT;
BEGIN
    -- Get user stats
    SELECT age_group, current_level
    INTO v_age_group, v_level
    FROM public.user_profiles
    WHERE id = p_user_id;

    -- Current day of week (0=Sunday per PostgreSQL DOW)
    v_today_dow := EXTRACT(DOW FROM NOW())::SMALLINT;

    RETURN QUERY
    SELECT
        q.id                    AS quest_id,
        q.title,
        q.description,
        q.instructions,
        q.category,
        q.difficulty,
        q.verification_type,
        q.repeat_frequency,
        q.holy_points_reward,
        q.faith_coins_reward,
        q.grace_reward,
        q.blessings_reward,
        q.xp_reward,
        q.icon_name,
        -- Check if completed today (for daily quests)
        EXISTS (
            SELECT 1 FROM public.quest_completions qc
            WHERE qc.user_id  = p_user_id
              AND qc.quest_id = q.id
              AND qc.completed_at::DATE = CURRENT_DATE
        )                       AS already_completed_today,
        -- Total times completed
        (
            SELECT COUNT(*) FROM public.quest_completions qc
            WHERE qc.user_id  = p_user_id
              AND qc.quest_id = q.id
        )                       AS times_completed_total
    FROM public.quests q
    WHERE
        q.is_active = true

        -- Age group check
        AND (v_age_group IS NULL OR q.min_age_group <= v_age_group)

        -- Level check
        AND (v_level IS NULL OR q.min_level <= v_level)

        -- Day of week check (NULL means any day)
        AND (q.day_of_week IS NULL OR q.day_of_week = v_today_dow)

        -- Liturgical season check
        AND (
            q.liturgical_season IS NULL
            OR p_season IS NULL
            OR q.liturgical_season = p_season
        )

        -- Date range check
        AND (q.available_from  IS NULL OR q.available_from  <= CURRENT_DATE)
        AND (q.available_until IS NULL OR q.available_until >= CURRENT_DATE)

        -- Building requirement check
        AND (
            q.required_building IS NULL
            OR public.get_kingdom_building_level(p_user_id, q.required_building)
               >= COALESCE(q.required_building_level, 1)
        )

    ORDER BY q.sort_order ASC, q.category ASC, q.difficulty ASC;
END;
$$;

COMMENT ON TABLE public.quests IS
    'Master list of all quests available in the game.';
COMMENT ON TABLE public.quest_completions IS
    'Records each time a user completes a quest and the rewards granted.';
COMMENT ON FUNCTION public.get_available_quests IS
    'Returns quests filtered to what this specific user can currently see and do.';
