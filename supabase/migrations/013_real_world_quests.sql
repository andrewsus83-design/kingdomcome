-- ============================================================
-- Migration 013: Real World Quest Board
-- ============================================================

-- ============================================================
-- ENUMs
-- ============================================================

DO $$ BEGIN
    CREATE TYPE public.real_world_category AS ENUM (
        'homeLife',
        'schoolLife',
        'community',
        'digitalFast',
        'characterBuilding',
        'family',
        'church'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.real_world_verification AS ENUM (
        'parentValidate',
        'photoScan',
        'appTimer',
        'honorSystem',
        'churchCheckin'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.real_world_repeat_frequency AS ENUM (
        'daily',
        'weekly',
        'once'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.real_world_completion_status AS ENUM (
        'pending_validation',
        'validated',
        'rejected'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- TABLE: real_world_quests
-- ============================================================

CREATE TABLE IF NOT EXISTS public.real_world_quests (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title                   TEXT NOT NULL,
    description             TEXT NOT NULL,
    category                public.real_world_category NOT NULL,
    verification            public.real_world_verification NOT NULL DEFAULT 'parentValidate',

    -- Rewards
    holy_points_reward      INTEGER NOT NULL DEFAULT 0  CHECK (holy_points_reward >= 0),
    faith_coins_reward      INTEGER NOT NULL DEFAULT 0  CHECK (faith_coins_reward >= 0),
    grace_reward            INTEGER NOT NULL DEFAULT 0  CHECK (grace_reward >= 0),

    -- Quest metadata
    estimated_minutes       INTEGER NOT NULL DEFAULT 30 CHECK (estimated_minutes > 0),
    age_group_min           SMALLINT NOT NULL DEFAULT 1 CHECK (age_group_min BETWEEN 1 AND 3),
    is_repeatable           BOOLEAN NOT NULL DEFAULT false,
    repeat_frequency        public.real_world_repeat_frequency NOT NULL DEFAULT 'once',

    -- Display
    icon_emoji              TEXT NOT NULL DEFAULT '⭐',
    inspirational_quote     TEXT NOT NULL DEFAULT '',
    related_virtue          TEXT NOT NULL DEFAULT '',

    -- Custom quest support
    is_custom               BOOLEAN NOT NULL DEFAULT false,
    created_by_parent_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

    -- Admin
    is_active               BOOLEAN NOT NULL DEFAULT true,
    sort_order              INTEGER NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rwq_category      ON public.real_world_quests (category);
CREATE INDEX IF NOT EXISTS idx_rwq_is_active     ON public.real_world_quests (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_rwq_is_custom     ON public.real_world_quests (is_custom, created_by_parent_id) WHERE is_custom = true;
CREATE INDEX IF NOT EXISTS idx_rwq_age_group     ON public.real_world_quests (age_group_min);

-- ============================================================
-- TABLE: real_world_completions
-- ============================================================

CREATE TABLE IF NOT EXISTS public.real_world_completions (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    quest_id                UUID NOT NULL REFERENCES public.real_world_quests(id) ON DELETE CASCADE,

    -- Status
    status                  public.real_world_completion_status NOT NULL DEFAULT 'pending_validation',

    -- Child's submission content
    child_note              TEXT,
    proof_photo_url         TEXT,

    -- Parent response
    parent_note             TEXT,
    validated_by_parent_id  UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,

    -- Timestamps
    completed_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    validated_at            TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_rwc_user_id       ON public.real_world_completions (user_id);
CREATE INDEX IF NOT EXISTS idx_rwc_quest_id      ON public.real_world_completions (quest_id);
CREATE INDEX IF NOT EXISTS idx_rwc_status        ON public.real_world_completions (status) WHERE status = 'pending_validation';
CREATE INDEX IF NOT EXISTS idx_rwc_user_status   ON public.real_world_completions (user_id, status, completed_at DESC);

-- Index for parent lookup: find all pending completions for children of a parent.
-- Uses a join through the parish family groups table.
CREATE INDEX IF NOT EXISTS idx_rwc_pending_completed ON public.real_world_completions (completed_at DESC)
    WHERE status = 'pending_validation';

-- ============================================================
-- RLS POLICIES
-- ============================================================

ALTER TABLE public.real_world_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.real_world_completions ENABLE ROW LEVEL SECURITY;

-- real_world_quests: anyone authenticated can read active quests
CREATE POLICY "Read active real world quests"
    ON public.real_world_quests
    FOR SELECT
    TO authenticated
    USING (
        is_active = true
        AND (
            is_custom = false
            OR created_by_parent_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.user_profiles p
                WHERE p.id = auth.uid()
                  AND p.parent_email IS NOT NULL
                  AND EXISTS (
                      SELECT 1 FROM public.user_profiles parent_p
                      WHERE parent_p.id = real_world_quests.created_by_parent_id
                        AND parent_p.id IN (
                            SELECT id FROM public.user_profiles
                            WHERE id = created_by_parent_id
                        )
                  )
            )
        )
    );

-- real_world_quests: parents can insert custom quests
CREATE POLICY "Parents can create custom quests"
    ON public.real_world_quests
    FOR INSERT
    TO authenticated
    WITH CHECK (
        is_custom = true
        AND created_by_parent_id = auth.uid()
    );

-- real_world_completions: users see their own completions
CREATE POLICY "Users see own completions"
    ON public.real_world_completions
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- real_world_completions: parents see children's completions
-- (children identified by matching parent_email in profiles)
CREATE POLICY "Parents see children completions"
    ON public.real_world_completions
    FOR SELECT
    TO authenticated
    USING (
        user_id IN (
            SELECT id FROM public.user_profiles
            WHERE parent_email = (
                SELECT email FROM auth.users WHERE id = auth.uid()
            )
        )
    );

-- real_world_completions: users can insert their own completions
CREATE POLICY "Users can submit completions"
    ON public.real_world_completions
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- real_world_completions: parents can update children's completions (validate/reject)
CREATE POLICY "Parents can validate or reject"
    ON public.real_world_completions
    FOR UPDATE
    TO authenticated
    USING (
        user_id IN (
            SELECT id FROM public.user_profiles
            WHERE parent_email = (
                SELECT email FROM auth.users WHERE id = auth.uid()
            )
        )
        AND status = 'pending_validation'
    )
    WITH CHECK (
        status IN ('validated', 'rejected')
    );

-- ============================================================
-- FUNCTION: get_pending_real_world_validations
-- Returns all completions pending validation for children of p_parent_id
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_pending_real_world_validations(
    p_parent_id UUID
)
RETURNS TABLE (
    id                      UUID,
    user_id                 UUID,
    quest_id                UUID,
    status                  TEXT,
    child_note              TEXT,
    proof_photo_url         TEXT,
    parent_note             TEXT,
    validated_by_parent_id  UUID,
    completed_at            TIMESTAMPTZ,
    validated_at            TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_parent_email TEXT;
BEGIN
    SELECT email INTO v_parent_email
    FROM auth.users
    WHERE id = p_parent_id;

    RETURN QUERY
    SELECT
        rwc.id,
        rwc.user_id,
        rwc.quest_id,
        rwc.status::TEXT,
        rwc.child_note,
        rwc.proof_photo_url,
        rwc.parent_note,
        rwc.validated_by_parent_id,
        rwc.completed_at,
        rwc.validated_at
    FROM public.real_world_completions rwc
    WHERE
        rwc.status = 'pending_validation'
        AND rwc.user_id IN (
            SELECT id FROM public.user_profiles
            WHERE parent_email = v_parent_email
        )
    ORDER BY rwc.completed_at ASC;
END;
$$;

-- ============================================================
-- FUNCTION: validate_real_world_quest
-- Validates a completion, awards resources to the child,
-- and sends a notification.
-- ============================================================

CREATE OR REPLACE FUNCTION public.validate_real_world_quest(
    p_completion_id UUID,
    p_parent_note   TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_completion    RECORD;
    v_quest         RECORD;
    v_parent_email  TEXT;
    v_parent_name   TEXT;
BEGIN
    -- Fetch completion and quest info
    SELECT rwc.*, rwq.holy_points_reward, rwq.faith_coins_reward, rwq.grace_reward, rwq.title
    INTO v_completion
    FROM public.real_world_completions rwc
    JOIN public.real_world_quests rwq ON rwq.id = rwc.quest_id
    WHERE rwc.id = p_completion_id
      AND rwc.status = 'pending_validation'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Completion not found or already processed: %', p_completion_id;
    END IF;

    -- Get parent info
    SELECT email, display_name INTO v_parent_email, v_parent_name
    FROM public.user_profiles
    WHERE id = auth.uid();

    -- Mark as validated
    UPDATE public.real_world_completions
    SET
        status                  = 'validated',
        validated_at            = NOW(),
        validated_by_parent_id  = auth.uid(),
        parent_note             = p_parent_note
    WHERE id = p_completion_id;

    -- Award holy points
    IF v_completion.holy_points_reward > 0 THEN
        UPDATE public.user_profiles
        SET total_holy_points = total_holy_points + v_completion.holy_points_reward
        WHERE id = v_completion.user_id;
    END IF;

    -- Award faith coins
    IF v_completion.faith_coins_reward > 0 THEN
        UPDATE public.user_profiles
        SET faith_coins = faith_coins + v_completion.faith_coins_reward
        WHERE id = v_completion.user_id;
    END IF;

    -- Award grace
    IF v_completion.grace_reward > 0 THEN
        UPDATE public.user_profiles
        SET grace = grace + v_completion.grace_reward
        WHERE id = v_completion.user_id;
    END IF;

    -- Insert notification for the child
    INSERT INTO public.notifications (user_id, title, body, notification_type, metadata)
    VALUES (
        v_completion.user_id,
        v_parent_name || ' approved your quest!',
        'Great job completing "' || v_completion.title || '"! '
            || COALESCE(p_parent_note, 'Keep up the good work!'),
        'quest_validated',
        jsonb_build_object(
            'completion_id', p_completion_id,
            'quest_id', v_completion.quest_id,
            'holy_points_reward', v_completion.holy_points_reward,
            'faith_coins_reward', v_completion.faith_coins_reward
        )
    );
END;
$$;

-- ============================================================
-- TRIGGER: update real_world_quests updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_real_world_quest_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_rwq_updated_at ON public.real_world_quests;
CREATE TRIGGER trg_rwq_updated_at
    BEFORE UPDATE ON public.real_world_quests
    FOR EACH ROW EXECUTE FUNCTION public.set_real_world_quest_updated_at();

-- ============================================================
-- TABLE: notifications (if not already exists)
-- Used by validate_real_world_quest to push child notifications
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title               TEXT NOT NULL,
    body                TEXT NOT NULL,
    notification_type   TEXT NOT NULL DEFAULT 'general',
    metadata            JSONB NOT NULL DEFAULT '{}',
    is_read             BOOLEAN NOT NULL DEFAULT false,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
    ON public.notifications (user_id, created_at DESC)
    WHERE is_read = false;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own notifications"
    ON public.notifications
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "System can insert notifications"
    ON public.notifications
    FOR INSERT
    TO authenticated
    WITH CHECK (true); -- controlled by SECURITY DEFINER function

COMMENT ON TABLE public.real_world_quests IS
    'Master list of real-world quests that children complete in daily life.';
COMMENT ON TABLE public.real_world_completions IS
    'Records each real-world quest completion, with parent validation workflow.';
COMMENT ON FUNCTION public.validate_real_world_quest IS
    'Validates a real-world quest completion, awards resources, and notifies the child.';
COMMENT ON FUNCTION public.get_pending_real_world_validations IS
    'Returns all pending completions for children associated with the given parent.';
