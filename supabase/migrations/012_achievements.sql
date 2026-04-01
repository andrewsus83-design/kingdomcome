-- ============================================================
-- 012_achievements.sql
-- Achievement system for Kingdom Come
-- ============================================================

-- ── Achievement category enum ─────────────────────────────────────────────────

CREATE TYPE achievement_category AS ENUM (
  'prayer',
  'knowledge',
  'kingdom',
  'social',
  'virtue',
  'arts',
  'games'
);

-- ── achievements table ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS achievements (
  id                   TEXT PRIMARY KEY,
  title                TEXT NOT NULL,
  description          TEXT NOT NULL,
  category             achievement_category NOT NULL,
  icon_asset_path      TEXT NOT NULL DEFAULT 'assets/images/achievements/default.png',
  holy_points_reward   INTEGER NOT NULL DEFAULT 0 CHECK (holy_points_reward >= 0),
  required_count       INTEGER NOT NULL DEFAULT 1 CHECK (required_count >= 1),
  is_secret            BOOLEAN NOT NULL DEFAULT FALSE,
  share_image_template TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  achievements IS 'Master list of all achievements (seeded; not user-editable).';
COMMENT ON COLUMN achievements.is_secret IS 'Hidden until unlocked.';

-- ── user_achievements table ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_achievements (
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id   TEXT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  current_progress INTEGER NOT NULL DEFAULT 0 CHECK (current_progress >= 0),
  target_count     INTEGER NOT NULL DEFAULT 1 CHECK (target_count >= 1),
  is_completed     BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, achievement_id)
);

COMMENT ON TABLE user_achievements IS 'Per-user progress toward each achievement.';

CREATE INDEX IF NOT EXISTS idx_user_achievements_user
  ON user_achievements (user_id, is_completed);

CREATE INDEX IF NOT EXISTS idx_user_achievements_completed
  ON user_achievements (user_id, completed_at DESC)
  WHERE is_completed = TRUE;

-- ── Row Level Security ────────────────────────────────────────────────────────

ALTER TABLE achievements      ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Anyone can read achievements (non-secret ones are public; secret ones hidden in app logic)
CREATE POLICY "achievements_select_all"
  ON achievements FOR SELECT
  USING (TRUE);

-- Users read their own progress
CREATE POLICY "user_achievements_select_own"
  ON user_achievements FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert/update their own progress
CREATE POLICY "user_achievements_insert_own"
  ON user_achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_achievements_update_own"
  ON user_achievements FOR UPDATE
  USING (auth.uid() = user_id);

-- ── Updated_at trigger ────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$ BEGIN
  CREATE TRIGGER trg_user_achievements_updated_at
    BEFORE UPDATE ON user_achievements
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ── check_and_award_achievements function ─────────────────────────────────────

-- Called after quest completion, game session, artwork save, etc.
-- Increments progress counters and marks achievements complete when thresholds
-- are reached, then awards Holy Points.
CREATE OR REPLACE FUNCTION check_and_award_achievements(p_user_id UUID)
RETURNS TABLE (newly_completed_id TEXT, holy_points_awarded INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_achievement RECORD;
  v_user_ach    RECORD;
  v_newly_done  TEXT[] := '{}';
  v_total_hp    INTEGER := 0;
BEGIN
  -- Iterate all achievements
  FOR v_achievement IN SELECT * FROM achievements LOOP

    -- Upsert user_achievement row
    INSERT INTO user_achievements (user_id, achievement_id, current_progress, target_count)
    VALUES (p_user_id, v_achievement.id, 0, v_achievement.required_count)
    ON CONFLICT (user_id, achievement_id) DO NOTHING;

    -- Fetch current row
    SELECT * INTO v_user_ach
    FROM user_achievements
    WHERE user_id = p_user_id AND achievement_id = v_achievement.id;

    -- Skip already completed achievements
    IF v_user_ach.is_completed THEN
      CONTINUE;
    END IF;

    -- Recompute progress based on event counters (simplified: app calls with explicit deltas)
    -- In a full implementation this would query quest_completions, artworks, game_sessions, etc.
    -- For now, the function serves as the award gateway; callers update current_progress directly.

    -- Check if now complete
    IF v_user_ach.current_progress >= v_achievement.required_count THEN
      UPDATE user_achievements
      SET is_completed = TRUE, completed_at = NOW(), updated_at = NOW()
      WHERE user_id = p_user_id AND achievement_id = v_achievement.id;

      -- Award holy points
      PERFORM award_game_resources(p_user_id, v_achievement.holy_points_reward, 0, 0);

      v_newly_done := array_append(v_newly_done, v_achievement.id);
      v_total_hp   := v_total_hp + v_achievement.holy_points_reward;
    END IF;

  END LOOP;

  -- Return newly completed achievements
  RETURN QUERY
  SELECT unnest(v_newly_done) AS newly_completed_id, v_total_hp AS holy_points_awarded;
END;
$$;

COMMENT ON FUNCTION check_and_award_achievements IS
  'Checks all achievements for a user and marks complete + awards HP for newly finished ones.';

-- ── increment_achievement_progress function ────────────────────────────────────

-- Helper called by triggers or app code to increment a specific achievement counter.
CREATE OR REPLACE FUNCTION increment_achievement_progress(
  p_user_id        UUID,
  p_achievement_id TEXT,
  p_increment       INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_required INTEGER;
BEGIN
  SELECT required_count INTO v_required
  FROM achievements WHERE id = p_achievement_id;

  IF v_required IS NULL THEN RETURN; END IF;

  INSERT INTO user_achievements (user_id, achievement_id, current_progress, target_count)
  VALUES (p_user_id, p_achievement_id, p_increment, v_required)
  ON CONFLICT (user_id, achievement_id) DO UPDATE
    SET current_progress = LEAST(user_achievements.current_progress + p_increment, v_required),
        updated_at = NOW();

  -- Auto-complete if threshold reached
  UPDATE user_achievements
  SET is_completed = TRUE, completed_at = NOW(), updated_at = NOW()
  WHERE user_id = p_user_id
    AND achievement_id = p_achievement_id
    AND current_progress >= v_required
    AND NOT is_completed;
END;
$$;

COMMENT ON FUNCTION increment_achievement_progress IS
  'Safely increments a user achievement counter and auto-completes when the target is reached.';
