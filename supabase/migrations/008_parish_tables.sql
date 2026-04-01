-- ============================================================
-- Migration 008: Parish, Leaderboard & Streak Tables
-- ============================================================

-- ============================================================
-- TABLE: parishes
-- ============================================================
CREATE TABLE public.parishes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    city            TEXT,
    state_province  TEXT,
    country         TEXT NOT NULL DEFAULT 'US',
    diocese         TEXT,
    website_url     TEXT,

    -- Invite / join mechanism
    invite_code     TEXT UNIQUE NOT NULL DEFAULT UPPER(SUBSTR(REPLACE(gen_random_uuid()::TEXT, '-', ''), 1, 8)),

    -- Admin user (must be a user_profile id)
    admin_user_id   UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,

    -- Stats (denormalized for leaderboard performance)
    member_count    INTEGER NOT NULL DEFAULT 0 CHECK (member_count >= 0),
    total_holy_points_weekly BIGINT NOT NULL DEFAULT 0,
    total_holy_points_all_time BIGINT NOT NULL DEFAULT 0,

    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_parishes_invite_code ON public.parishes (invite_code);
CREATE INDEX idx_parishes_country     ON public.parishes (country);
CREATE INDEX idx_parishes_diocese     ON public.parishes (diocese) WHERE diocese IS NOT NULL;

-- ============================================================
-- Now wire in the FK from user_profiles.parish_id -> parishes
-- (couldn't add in 001 because parishes didn't exist yet)
-- ============================================================
ALTER TABLE public.user_profiles
    ADD CONSTRAINT fk_user_profiles_parish
    FOREIGN KEY (parish_id) REFERENCES public.parishes(id) ON DELETE SET NULL;

-- ============================================================
-- TABLE: parish_members
-- ============================================================
CREATE TABLE public.parish_members (
    parish_id   UUID NOT NULL REFERENCES public.parishes(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,

    role        TEXT NOT NULL DEFAULT 'member'
                    CHECK (role IN ('member', 'moderator', 'admin')),

    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (parish_id, user_id)
);

CREATE INDEX idx_parish_members_user_id   ON public.parish_members (user_id);
CREATE INDEX idx_parish_members_parish_id ON public.parish_members (parish_id);

-- ============================================================
-- FUNCTION: update_parish_member_count
-- Keeps parishes.member_count in sync
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_parish_member_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.parishes
        SET member_count = member_count + 1
        WHERE id = NEW.parish_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.parishes
        SET member_count = GREATEST(0, member_count - 1)
        WHERE id = OLD.parish_id;
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER trg_parish_member_count
    AFTER INSERT OR DELETE ON public.parish_members
    FOR EACH ROW
    EXECUTE FUNCTION public.update_parish_member_count();

-- ============================================================
-- TABLE: parish_leaderboard_weekly
-- Pre-computed weekly leaderboard snapshot per parish
-- ============================================================
CREATE TABLE public.parish_leaderboard_weekly (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parish_id       UUID NOT NULL REFERENCES public.parishes(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    week_start      DATE NOT NULL,              -- Monday of the ISO week
    holy_points     BIGINT NOT NULL DEFAULT 0,
    quests_completed INTEGER NOT NULL DEFAULT 0,
    rank            INTEGER,

    CONSTRAINT uq_parish_leaderboard_weekly UNIQUE (parish_id, user_id, week_start)
);

CREATE INDEX idx_plw_parish_week   ON public.parish_leaderboard_weekly (parish_id, week_start DESC);
CREATE INDEX idx_plw_user          ON public.parish_leaderboard_weekly (user_id);

-- ============================================================
-- FUNCTION: refresh_parish_leaderboard
-- Rebuilds the weekly leaderboard for a given parish (or all).
-- Designed to be called from a cron job / edge function.
-- ============================================================
CREATE OR REPLACE FUNCTION public.refresh_parish_leaderboard(
    p_parish_id UUID  DEFAULT NULL,
    p_week_start DATE DEFAULT DATE_TRUNC('week', CURRENT_DATE)::DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_week_end  DATE := p_week_start + 6;
    v_count     INTEGER := 0;
BEGIN
    -- Insert / update weekly holy points per member
    WITH weekly_stats AS (
        SELECT
            pm.parish_id,
            pm.user_id,
            COALESCE(SUM(qc.holy_points_awarded), 0)    AS holy_points,
            COUNT(qc.id)                                 AS quests_completed
        FROM public.parish_members pm
        LEFT JOIN public.quest_completions qc
            ON  qc.user_id = pm.user_id
            AND qc.completed_at::DATE BETWEEN p_week_start AND v_week_end
        WHERE (p_parish_id IS NULL OR pm.parish_id = p_parish_id)
        GROUP BY pm.parish_id, pm.user_id
    ),
    ranked AS (
        SELECT
            ws.*,
            RANK() OVER (PARTITION BY ws.parish_id ORDER BY ws.holy_points DESC) AS rank
        FROM weekly_stats ws
    )
    INSERT INTO public.parish_leaderboard_weekly (
        parish_id, user_id, week_start, holy_points, quests_completed, rank
    )
    SELECT parish_id, user_id, p_week_start, holy_points, quests_completed, rank
    FROM ranked
    ON CONFLICT (parish_id, user_id, week_start) DO UPDATE SET
        holy_points       = EXCLUDED.holy_points,
        quests_completed  = EXCLUDED.quests_completed,
        rank              = EXCLUDED.rank;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- ============================================================
-- TABLE: user_streaks
-- Granular streak tracking per streak type
-- ============================================================
CREATE TABLE public.user_streaks (
    user_id             UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    streak_type         TEXT NOT NULL
                            CHECK (streak_type IN (
                                'daily_quest',
                                'prayer',
                                'bible_reading',
                                'rosary',
                                'mass'
                            )),
    current_streak      INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak      INTEGER NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
    last_completed_date DATE,
    streak_started_date DATE,
    total_completions   INTEGER NOT NULL DEFAULT 0 CHECK (total_completions >= 0),

    PRIMARY KEY (user_id, streak_type)
);

CREATE INDEX idx_user_streaks_user_id ON public.user_streaks (user_id);

-- ============================================================
-- FUNCTION: increment_streak
-- Safely increments a streak, handles gap detection,
-- updates longest_streak if needed.
-- ============================================================
CREATE OR REPLACE FUNCTION public.increment_streak(
    p_user_id       UUID,
    p_streak_type   TEXT,
    p_date          DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    new_streak      INTEGER,
    longest_streak  INTEGER,
    streak_broken   BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_last_date     DATE;
    v_current       INTEGER;
    v_longest       INTEGER;
    v_broken        BOOLEAN := false;
    v_new_streak    INTEGER;
BEGIN
    -- Upsert the row if it doesn't exist
    INSERT INTO public.user_streaks (user_id, streak_type, current_streak, longest_streak,
                                     last_completed_date, streak_started_date, total_completions)
    VALUES (p_user_id, p_streak_type, 0, 0, NULL, NULL, 0)
    ON CONFLICT (user_id, streak_type) DO NOTHING;

    SELECT us.current_streak, us.longest_streak, us.last_completed_date
    INTO   v_current, v_longest, v_last_date
    FROM   public.user_streaks us
    WHERE  us.user_id = p_user_id AND us.streak_type = p_streak_type
    FOR UPDATE;

    -- Already completed today
    IF v_last_date = p_date THEN
        RETURN QUERY SELECT v_current, v_longest, false;
        RETURN;
    END IF;

    -- Streak continues if yesterday was the last date
    IF v_last_date IS NULL OR v_last_date = p_date - 1 THEN
        v_new_streak := v_current + 1;
    ELSE
        -- Gap detected: reset streak
        v_broken     := true;
        v_new_streak := 1;
    END IF;

    UPDATE public.user_streaks SET
        current_streak      = v_new_streak,
        longest_streak      = GREATEST(v_longest, v_new_streak),
        last_completed_date = p_date,
        streak_started_date = CASE
                                WHEN v_broken OR streak_started_date IS NULL
                                THEN p_date
                                ELSE streak_started_date
                              END,
        total_completions   = total_completions + 1
    WHERE user_id = p_user_id AND streak_type = p_streak_type;

    -- Also update the denormalized fields on user_profiles for the main streak
    IF p_streak_type = 'daily_quest' THEN
        UPDATE public.user_profiles SET
            current_streak  = v_new_streak,
            longest_streak  = GREATEST(longest_streak, v_new_streak),
            last_activity_date = p_date
        WHERE id = p_user_id;
    END IF;

    RETURN QUERY SELECT v_new_streak, GREATEST(v_longest, v_new_streak), v_broken;
END;
$$;

COMMENT ON TABLE public.parishes IS
    'Catholic parishes that users can join for community leaderboards.';
COMMENT ON TABLE public.parish_members IS
    'Many-to-many: each user belongs to one parish; each parish has many members.';
COMMENT ON TABLE public.parish_leaderboard_weekly IS
    'Pre-computed weekly holy-point rankings per parish member.';
COMMENT ON TABLE public.user_streaks IS
    'Per-activity-type streak counters for each user.';
