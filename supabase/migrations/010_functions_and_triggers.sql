-- ============================================================
-- Migration 010: Critical Atomic Database Functions
-- ============================================================

-- ============================================================
-- FUNCTION: award_resources
-- Atomically adds resources to a user's profile.
-- ============================================================
CREATE OR REPLACE FUNCTION public.award_resources(
    p_user_id       UUID,
    p_holy_points   INT DEFAULT 0,
    p_faith_coins   INT DEFAULT 0,
    p_grace         INT DEFAULT 0,
    p_blessings     INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result public.user_profiles%ROWTYPE;
BEGIN
    UPDATE public.user_profiles SET
        total_holy_points = total_holy_points + GREATEST(0, p_holy_points),
        faith_coins       = faith_coins       + GREATEST(0, p_faith_coins),
        grace             = grace             + GREATEST(0, p_grace),
        blessings         = blessings         + GREATEST(0, p_blessings)
    WHERE id = p_user_id
    RETURNING * INTO v_result;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    RETURN jsonb_build_object(
        'success',          true,
        'total_holy_points', v_result.total_holy_points,
        'faith_coins',       v_result.faith_coins,
        'grace',             v_result.grace,
        'blessings',         v_result.blessings
    );
END;
$$;

-- ============================================================
-- FUNCTION: spend_resources
-- Validates sufficient balance, then atomically deducts.
-- Returns success/failure JSON.
-- ============================================================
CREATE OR REPLACE FUNCTION public.spend_resources(
    p_user_id       UUID,
    p_faith_coins   INT DEFAULT 0,
    p_holy_points   INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_coins     INT;
    v_current_points    BIGINT;
    v_result            public.user_profiles%ROWTYPE;
BEGIN
    -- Lock the row and read current balances
    SELECT faith_coins, total_holy_points
    INTO v_current_coins, v_current_points
    FROM public.user_profiles
    WHERE id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    -- Validate balances
    IF p_faith_coins > 0 AND v_current_coins < p_faith_coins THEN
        RETURN jsonb_build_object(
            'success',           false,
            'error',             'insufficient_faith_coins',
            'have',              v_current_coins,
            'need',              p_faith_coins
        );
    END IF;

    IF p_holy_points > 0 AND v_current_points < p_holy_points THEN
        RETURN jsonb_build_object(
            'success',     false,
            'error',       'insufficient_holy_points',
            'have',        v_current_points,
            'need',        p_holy_points
        );
    END IF;

    -- Deduct
    UPDATE public.user_profiles SET
        faith_coins       = faith_coins       - GREATEST(0, p_faith_coins),
        total_holy_points = total_holy_points - GREATEST(0, p_holy_points)
    WHERE id = p_user_id
    RETURNING * INTO v_result;

    RETURN jsonb_build_object(
        'success',           true,
        'faith_coins',       v_result.faith_coins,
        'total_holy_points', v_result.total_holy_points
    );
END;
$$;

-- ============================================================
-- FUNCTION: check_and_apply_level_up
-- Given a user's updated total_holy_points, checks whether they
-- should level up and applies it. Returns new level info.
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_and_apply_level_up(
    p_user_id UUID
)
RETURNS TABLE (
    leveled_up      BOOLEAN,
    new_level       SMALLINT,
    current_xp      INTEGER,
    xp_to_next      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_level     SMALLINT;
    v_total_points      BIGINT;
    v_new_level         SMALLINT;
    v_leveled_up        BOOLEAN := false;
    v_next_threshold    BIGINT;
BEGIN
    SELECT current_level, total_holy_points
    INTO v_current_level, v_total_points
    FROM public.user_profiles
    WHERE id = p_user_id
    FOR UPDATE;

    v_new_level := v_current_level;

    -- Keep checking upward (handles multiple level-ups from large rewards)
    LOOP
        v_next_threshold := public.get_level_threshold((v_new_level + 1)::SMALLINT);
        EXIT WHEN v_total_points < v_next_threshold OR v_new_level >= 100;
        v_new_level  := v_new_level + 1;
        v_leveled_up := true;
    END LOOP;

    IF v_leveled_up THEN
        UPDATE public.user_profiles SET
            current_level = v_new_level,
            level_xp      = (v_total_points - public.get_level_threshold(v_new_level))::INTEGER
        WHERE id = p_user_id;
    END IF;

    RETURN QUERY SELECT
        v_leveled_up,
        v_new_level,
        (v_total_points - public.get_level_threshold(v_new_level))::INTEGER,
        public.get_level_threshold((v_new_level + 1)::SMALLINT)
            - public.get_level_threshold(v_new_level);
END;
$$;

-- ============================================================
-- FUNCTION: complete_quest_atomic
-- The core game transaction. All or nothing.
--
-- Steps:
--   1. Validate quest exists and is active
--   2. Check for duplicate daily completion
--   3. Get active saint multiplier
--   4. Calculate actual rewards
--   5. INSERT quest_completion
--   6. UPDATE user_profiles resources
--   7. UPDATE user_streaks
--   8. Check for level up
--   9. Return structured result
-- ============================================================
CREATE OR REPLACE FUNCTION public.complete_quest_atomic(
    p_user_id   UUID,
    p_quest_id  UUID,
    p_proof_url TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_quest             public.quests%ROWTYPE;
    v_user              public.user_profiles%ROWTYPE;
    v_multiplier        NUMERIC(4, 2) := 1.00;
    v_streak_type       TEXT;

    -- Calculated rewards
    v_hp_reward         INTEGER;
    v_fc_reward         INTEGER;
    v_grace_reward      INTEGER;
    v_bless_reward      INTEGER;
    v_xp_reward         INTEGER;

    -- Results
    v_completion_id     UUID;
    v_leveled_up        BOOLEAN := false;
    v_new_level         SMALLINT;
    v_new_streak        INTEGER;
    v_longest_streak    INTEGER;
    v_streak_broken     BOOLEAN;
    v_xp_to_next        BIGINT;
    v_current_xp        INTEGER;
BEGIN
    -- ── 1. Load quest ────────────────────────────────────────
    SELECT * INTO v_quest
    FROM public.quests
    WHERE id = p_quest_id AND is_active = true;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'quest_not_found_or_inactive');
    END IF;

    -- ── 2. Lock user row ─────────────────────────────────────
    SELECT * INTO v_user
    FROM public.user_profiles
    WHERE id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    -- Age group check
    IF v_user.age_group IS NOT NULL AND v_quest.min_age_group > v_user.age_group THEN
        RETURN jsonb_build_object('success', false, 'error', 'age_group_insufficient');
    END IF;

    -- Level check
    IF v_quest.min_level > v_user.current_level THEN
        RETURN jsonb_build_object(
            'success', false,
            'error',   'level_insufficient',
            'required', v_quest.min_level,
            'current',  v_user.current_level
        );
    END IF;

    -- ── 3. Duplicate daily check ─────────────────────────────
    IF v_quest.repeat_frequency = 'daily' THEN
        IF EXISTS (
            SELECT 1 FROM public.quest_completions
            WHERE user_id    = p_user_id
              AND quest_id   = p_quest_id
              AND completed_at::DATE = CURRENT_DATE
        ) THEN
            RETURN jsonb_build_object('success', false, 'error', 'already_completed_today');
        END IF;
    ELSIF v_quest.repeat_frequency = 'weekly' THEN
        IF EXISTS (
            SELECT 1 FROM public.quest_completions
            WHERE user_id    = p_user_id
              AND quest_id   = p_quest_id
              AND completed_at >= DATE_TRUNC('week', NOW())
        ) THEN
            RETURN jsonb_build_object('success', false, 'error', 'already_completed_this_week');
        END IF;
    ELSIF v_quest.repeat_frequency = 'once' THEN
        IF EXISTS (
            SELECT 1 FROM public.quest_completions
            WHERE user_id  = p_user_id
              AND quest_id = p_quest_id
        ) THEN
            RETURN jsonb_build_object('success', false, 'error', 'already_completed');
        END IF;
    END IF;

    -- ── 4. Saint multiplier ──────────────────────────────────
    v_multiplier := public.get_active_saint_multiplier(p_user_id);

    -- ── 5. Calculate rewards ─────────────────────────────────
    v_hp_reward    := ROUND(v_quest.holy_points_reward * v_multiplier)::INTEGER;
    v_fc_reward    := ROUND(v_quest.faith_coins_reward * v_multiplier)::INTEGER;
    v_grace_reward := ROUND(v_quest.grace_reward       * v_multiplier)::INTEGER;
    v_bless_reward := v_quest.blessings_reward;     -- blessings are not multiplied
    v_xp_reward    := ROUND(v_quest.xp_reward         * v_multiplier)::INTEGER;

    -- ── 6. Insert quest completion ───────────────────────────
    INSERT INTO public.quest_completions (
        user_id, quest_id,
        holy_points_awarded, faith_coins_awarded,
        grace_awarded, blessings_awarded, xp_awarded,
        multiplier_applied, proof_url,
        verified, completed_at
    ) VALUES (
        p_user_id, p_quest_id,
        v_hp_reward, v_fc_reward,
        v_grace_reward, v_bless_reward, v_xp_reward,
        v_multiplier, p_proof_url,
        -- Auto-verify non-photo quests; photo/parent quests need review
        (v_quest.verification_type NOT IN ('photo_proof', 'parent_confirm')),
        NOW()
    )
    RETURNING id INTO v_completion_id;

    -- ── 7. Update user resources ─────────────────────────────
    UPDATE public.user_profiles SET
        total_holy_points = total_holy_points + v_hp_reward,
        faith_coins       = faith_coins       + v_fc_reward,
        grace             = grace             + v_grace_reward,
        blessings         = blessings         + v_bless_reward,
        level_xp          = level_xp          + v_xp_reward,
        last_activity_date = CURRENT_DATE
    WHERE id = p_user_id;

    -- ── 8. Update streak ─────────────────────────────────────
    -- Map quest category to streak type
    v_streak_type := CASE v_quest.category
        WHEN 'prayer'         THEN 'prayer'
        WHEN 'rosary'         THEN 'rosary'
        WHEN 'bible_reading'  THEN 'bible_reading'
        WHEN 'mass_attendance' THEN 'mass'
        ELSE 'daily_quest'
    END;

    SELECT new_streak, longest_streak, streak_broken
    INTO v_new_streak, v_longest_streak, v_streak_broken
    FROM public.increment_streak(p_user_id, v_streak_type, CURRENT_DATE);

    -- Also always tick daily_quest streak (unless it was the streak type just updated)
    IF v_streak_type <> 'daily_quest' THEN
        PERFORM public.increment_streak(p_user_id, 'daily_quest', CURRENT_DATE);
    END IF;

    -- ── 9. Level up check ────────────────────────────────────
    SELECT leveled_up, new_level, current_xp, xp_to_next
    INTO v_leveled_up, v_new_level, v_current_xp, v_xp_to_next
    FROM public.check_and_apply_level_up(p_user_id);

    -- ── 10. Return result ────────────────────────────────────
    RETURN jsonb_build_object(
        'success',          true,
        'completion_id',    v_completion_id,
        'rewards_granted', jsonb_build_object(
            'holy_points',  v_hp_reward,
            'faith_coins',  v_fc_reward,
            'grace',        v_grace_reward,
            'blessings',    v_bless_reward,
            'xp',           v_xp_reward,
            'multiplier',   v_multiplier
        ),
        'new_totals', jsonb_build_object(
            'total_holy_points', (SELECT total_holy_points FROM public.user_profiles WHERE id = p_user_id),
            'faith_coins',       (SELECT faith_coins       FROM public.user_profiles WHERE id = p_user_id),
            'grace',             (SELECT grace             FROM public.user_profiles WHERE id = p_user_id),
            'blessings',         (SELECT blessings         FROM public.user_profiles WHERE id = p_user_id)
        ),
        'leveled_up',       v_leveled_up,
        'new_level',        v_new_level,
        'current_xp',       v_current_xp,
        'xp_to_next_level', v_xp_to_next,
        'streak_updated', jsonb_build_object(
            'streak_type',   v_streak_type,
            'new_streak',    v_new_streak,
            'longest',       v_longest_streak,
            'streak_broken', v_streak_broken
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error',   'unexpected_error',
            'detail',  SQLERRM
        );
END;
$$;

-- ============================================================
-- FUNCTION: unlock_saint_atomic
-- Checks monastery level, holy_points balance,
-- deducts cost, and inserts user_saints.
-- ============================================================
CREATE OR REPLACE FUNCTION public.unlock_saint_atomic(
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
    v_user              public.user_profiles%ROWTYPE;
    v_monastery_level   SMALLINT;
BEGIN
    -- Load saint
    SELECT * INTO v_saint FROM public.saints WHERE id = p_saint_id AND is_active = true;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'saint_not_found');
    END IF;

    -- Lock user
    SELECT * INTO v_user FROM public.user_profiles WHERE id = p_user_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    -- Check already unlocked
    IF EXISTS (SELECT 1 FROM public.user_saints WHERE user_id = p_user_id AND saint_id = p_saint_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'already_unlocked');
    END IF;

    -- Check monastery level
    v_monastery_level := public.get_kingdom_building_level(p_user_id, 'monastery'::public.building_type);
    IF v_monastery_level < v_saint.required_monastery_level THEN
        RETURN jsonb_build_object(
            'success',          false,
            'error',            'monastery_level_insufficient',
            'required_level',   v_saint.required_monastery_level,
            'current_level',    v_monastery_level
        );
    END IF;

    -- Check holy_points balance
    IF v_user.total_holy_points < v_saint.unlock_cost_holy_points THEN
        RETURN jsonb_build_object(
            'success', false,
            'error',   'insufficient_holy_points',
            'have',    v_user.total_holy_points,
            'need',    v_saint.unlock_cost_holy_points
        );
    END IF;

    -- Deduct cost
    UPDATE public.user_profiles SET
        total_holy_points = total_holy_points - v_saint.unlock_cost_holy_points
    WHERE id = p_user_id;

    -- Insert user_saints record
    INSERT INTO public.user_saints (user_id, saint_id)
    VALUES (p_user_id, p_saint_id);

    RETURN jsonb_build_object(
        'success',           true,
        'saint_id',          p_saint_id,
        'saint_name',        v_saint.display_name,
        'cost_paid',         v_saint.unlock_cost_holy_points,
        'holy_points_remaining',
            (SELECT total_holy_points FROM public.user_profiles WHERE id = p_user_id)
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error',   'unexpected_error',
            'detail',  SQLERRM
        );
END;
$$;

-- ============================================================
-- FUNCTION: submit_quiz_attempt
-- Records a completed quiz, calculates score, awards resources.
-- ============================================================
CREATE OR REPLACE FUNCTION public.submit_quiz_attempt(
    p_user_id           UUID,
    p_quiz_id           UUID,
    p_answers_given     SMALLINT[],
    p_time_taken_secs   INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_quiz              public.quizzes%ROWTYPE;
    v_questions         public.quiz_questions[];
    v_q                 public.quiz_questions;
    v_total             SMALLINT := 0;
    v_correct           SMALLINT := 0;
    v_score_pct         SMALLINT;
    v_passed            BOOLEAN;
    v_attempt_id        UUID;
    v_hp_award          INTEGER := 0;
    v_fc_award          INTEGER := 0;
    v_xp_award          INTEGER := 0;
    v_idx               INTEGER := 1;
BEGIN
    SELECT * INTO v_quiz FROM public.quizzes WHERE id = p_quiz_id AND is_active = true;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'quiz_not_found');
    END IF;

    -- Load ordered questions
    SELECT ARRAY_AGG(q ORDER BY q.sort_order ASC)
    INTO v_questions
    FROM public.quiz_questions q
    WHERE q.quiz_id = p_quiz_id;

    v_total := COALESCE(array_length(v_questions, 1), 0);

    IF v_total = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'no_questions');
    END IF;

    -- Grade answers
    FOREACH v_q IN ARRAY v_questions LOOP
        IF v_idx <= array_length(p_answers_given, 1) THEN
            IF p_answers_given[v_idx] = v_q.correct_index THEN
                v_correct := v_correct + 1;
            END IF;
        END IF;
        v_idx := v_idx + 1;
    END LOOP;

    v_score_pct := ROUND(100.0 * v_correct / v_total)::SMALLINT;
    v_passed    := v_score_pct >= v_quiz.passing_score;

    -- Only award if passed
    IF v_passed THEN
        v_hp_award := v_quiz.holy_points_reward;
        v_fc_award := v_quiz.faith_coins_reward;
        v_xp_award := v_quiz.xp_reward;

        PERFORM public.award_resources(p_user_id, v_hp_award, v_fc_award, 0, 0);

        UPDATE public.user_profiles SET
            level_xp          = level_xp + v_xp_award,
            last_activity_date = CURRENT_DATE
        WHERE id = p_user_id;
    END IF;

    INSERT INTO public.quiz_attempts (
        user_id, quiz_id,
        answers_given, questions_total, questions_correct,
        score_percent, passed, time_taken_seconds,
        started_at, completed_at,
        holy_points_awarded, faith_coins_awarded, xp_awarded
    ) VALUES (
        p_user_id, p_quiz_id,
        p_answers_given, v_total, v_correct,
        v_score_pct, v_passed, p_time_taken_secs,
        NOW() - COALESCE(p_time_taken_secs, 0) * '1 second'::INTERVAL,
        NOW(),
        v_hp_award, v_fc_award, v_xp_award
    )
    RETURNING id INTO v_attempt_id;

    RETURN jsonb_build_object(
        'success',          true,
        'attempt_id',       v_attempt_id,
        'score_percent',    v_score_pct,
        'questions_total',  v_total,
        'questions_correct', v_correct,
        'passed',           v_passed,
        'rewards', jsonb_build_object(
            'holy_points', v_hp_award,
            'faith_coins', v_fc_award,
            'xp',          v_xp_award
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', 'unexpected_error', 'detail', SQLERRM);
END;
$$;

-- ============================================================
-- GRANT execute permissions to authenticated role
-- (service_role has full bypass; edge functions use service_role)
-- ============================================================
GRANT EXECUTE ON FUNCTION public.complete_quest_atomic  TO service_role;
GRANT EXECUTE ON FUNCTION public.award_resources        TO service_role;
GRANT EXECUTE ON FUNCTION public.spend_resources        TO service_role;
GRANT EXECUTE ON FUNCTION public.unlock_saint_atomic    TO service_role;
GRANT EXECUTE ON FUNCTION public.submit_quiz_attempt    TO service_role;
GRANT EXECUTE ON FUNCTION public.activate_saint_ability TO service_role;
GRANT EXECUTE ON FUNCTION public.get_available_quests   TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_verse_of_day       TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_active_saint_multiplier TO service_role;
GRANT EXECUTE ON FUNCTION public.increment_streak       TO service_role;
GRANT EXECUTE ON FUNCTION public.refresh_parish_leaderboard TO service_role;
GRANT EXECUTE ON FUNCTION public.toggle_artwork_like    TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_reading_progress TO authenticated, service_role;

COMMENT ON FUNCTION public.complete_quest_atomic IS
    'Single-transaction quest completion: validates, awards, streaks, levels. Called only via edge function with service_role.';
COMMENT ON FUNCTION public.award_resources IS
    'Atomically adds resources. Always use this instead of raw UPDATEs to avoid race conditions.';
COMMENT ON FUNCTION public.spend_resources IS
    'Validates and atomically deducts resources. Returns error JSON if balance insufficient.';
COMMENT ON FUNCTION public.unlock_saint_atomic IS
    'Validates monastery level and holy_points balance, then unlocks saint in a single transaction.';
