-- ============================================================
-- 011_game_tables.sql
-- Mini-game session tracking for Kingdom Come
-- ============================================================

-- ── Game type enum ────────────────────────────────────────────────────────────

CREATE TYPE game_type AS ENUM (
  'saintDefender',
  'scriptureBuilder',
  'rosaryRunner',
  'virtueForge',
  'bibleTrivialDuel',
  'liturgyCalendar'
);

-- ── game_sessions table ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS game_sessions (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  game_type          game_type NOT NULL,
  score              INTEGER NOT NULL DEFAULT 0 CHECK (score >= 0),
  max_score          INTEGER NOT NULL DEFAULT 0 CHECK (max_score >= 0),
  duration_seconds   INTEGER NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
  holy_points_earned INTEGER NOT NULL DEFAULT 0 CHECK (holy_points_earned >= 0),
  faith_coins_earned INTEGER NOT NULL DEFAULT 0 CHECK (faith_coins_earned >= 0),
  grace_earned       INTEGER NOT NULL DEFAULT 0 CHECK (grace_earned >= 0),
  meta_data          JSONB NOT NULL DEFAULT '{}',
  completed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  game_sessions IS 'Records each completed mini-game session.';
COMMENT ON COLUMN game_sessions.meta_data IS 'Game-specific extras: waves survived, verses completed, relics forged, etc.';

-- ── Indexes ───────────────────────────────────────────────────────────────────

-- Fast lookups: user's sessions filtered by game type
CREATE INDEX IF NOT EXISTS idx_game_sessions_user_game
  ON game_sessions (user_id, game_type, completed_at DESC);

-- Global leaderboard: top scores per game
CREATE INDEX IF NOT EXISTS idx_game_sessions_score
  ON game_sessions (game_type, score DESC);

-- ── High scores view ──────────────────────────────────────────────────────────

-- Returns each user's single best score per game type.
-- Used by the leaderboard queries.
CREATE OR REPLACE VIEW high_scores AS
SELECT DISTINCT ON (user_id, game_type)
  id,
  user_id,
  game_type,
  score,
  max_score,
  duration_seconds,
  holy_points_earned,
  faith_coins_earned,
  grace_earned,
  meta_data,
  completed_at
FROM game_sessions
ORDER BY user_id, game_type, score DESC, completed_at DESC;

COMMENT ON VIEW high_scores IS 'Best session per (user_id, game_type) pair for leaderboards.';

-- ── Parish leaderboard view ───────────────────────────────────────────────────

-- Joins high_scores with user_profiles to surface display info.
-- Requires parish_id from user_profiles (created in earlier migrations).
CREATE OR REPLACE VIEW parish_game_leaderboard AS
SELECT
  hs.user_id,
  up.display_name,
  up.avatar_url,
  up.parish_id,
  hs.game_type,
  hs.score AS high_score,
  hs.completed_at
FROM high_scores hs
JOIN user_profiles up ON up.id = hs.user_id;

COMMENT ON VIEW parish_game_leaderboard IS 'Per-parish leaderboard joining high scores with user profile data.';

-- ── Row Level Security ────────────────────────────────────────────────────────

ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;

-- Users can read their own sessions
CREATE POLICY "game_sessions_select_own"
  ON game_sessions FOR SELECT
  USING (auth.uid() = user_id);

-- Parish members can see each other's high scores for leaderboards
CREATE POLICY "game_sessions_select_parish"
  ON game_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM user_profiles viewer
      JOIN user_profiles subject ON subject.parish_id = viewer.parish_id
      WHERE viewer.id = auth.uid()
        AND subject.id = game_sessions.user_id
    )
  );

-- Users can insert their own sessions
CREATE POLICY "game_sessions_insert_own"
  ON game_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users cannot update or delete sessions (immutable audit log)
-- (No UPDATE or DELETE policies created)

-- ── RPC: award game resources ─────────────────────────────────────────────────

-- Called after saving a game session to credit resources.
CREATE OR REPLACE FUNCTION award_game_resources(
  p_user_id       UUID,
  p_holy_points   INTEGER DEFAULT 0,
  p_faith_coins   INTEGER DEFAULT 0,
  p_grace         INTEGER DEFAULT 0
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE kingdom_resources
  SET
    holy_points  = holy_points  + p_holy_points,
    faith_coins  = faith_coins  + p_faith_coins,
    grace        = grace        + p_grace,
    updated_at   = NOW()
  WHERE user_id = p_user_id;

  -- If no row exists yet (edge case), insert one
  IF NOT FOUND THEN
    INSERT INTO kingdom_resources (user_id, holy_points, faith_coins, grace)
    VALUES (p_user_id, p_holy_points, p_faith_coins, p_grace)
    ON CONFLICT (user_id) DO UPDATE
      SET
        holy_points = kingdom_resources.holy_points + EXCLUDED.holy_points,
        faith_coins = kingdom_resources.faith_coins + EXCLUDED.faith_coins,
        grace       = kingdom_resources.grace       + EXCLUDED.grace,
        updated_at  = NOW();
  END IF;
END;
$$;

COMMENT ON FUNCTION award_game_resources IS 'Credits Holy Points, FaithCoins, and Grace to a user after a game session.';
