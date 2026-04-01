-- ============================================================
-- Migration 006: Quiz Tables
-- ============================================================

-- ============================================================
-- ENUM: quiz_category
-- ============================================================
DO $$ BEGIN
    CREATE TYPE public.quiz_category AS ENUM (
        'sacraments',
        'saints',
        'bible',
        'liturgy',
        'church_history',
        'moral_theology',
        'prayers',
        'general'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- TABLE: quizzes
-- ============================================================
CREATE TABLE public.quizzes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           TEXT NOT NULL,
    description     TEXT,
    category        public.quiz_category NOT NULL,
    difficulty      SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 3),
    min_age_group   SMALLINT NOT NULL DEFAULT 1 CHECK (min_age_group BETWEEN 1 AND 3),

    -- Timing
    time_limit_seconds INTEGER CHECK (time_limit_seconds > 0),   -- NULL = untimed

    -- Rewards for completion
    holy_points_reward  INTEGER NOT NULL DEFAULT 20 CHECK (holy_points_reward >= 0),
    faith_coins_reward  INTEGER NOT NULL DEFAULT 5  CHECK (faith_coins_reward >= 0),
    xp_reward           INTEGER NOT NULL DEFAULT 15 CHECK (xp_reward >= 0),

    -- Passing threshold (percentage 0-100)
    passing_score   SMALLINT NOT NULL DEFAULT 70 CHECK (passing_score BETWEEN 0 AND 100),

    -- Metadata
    icon_name       TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INTEGER NOT NULL DEFAULT 0,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quizzes_category   ON public.quizzes (category);
CREATE INDEX idx_quizzes_difficulty ON public.quizzes (difficulty);
CREATE INDEX idx_quizzes_age_group  ON public.quizzes (min_age_group);
CREATE INDEX idx_quizzes_is_active  ON public.quizzes (is_active) WHERE is_active = true;

-- ============================================================
-- TABLE: quiz_questions
-- ============================================================
CREATE TABLE public.quiz_questions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id         UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
    question_text   TEXT NOT NULL,

    -- Exactly 4 answer options (indices 0-3)
    options         TEXT[] NOT NULL,
    CONSTRAINT chk_quiz_options_count CHECK (array_length(options, 1) = 4),

    -- Index of the correct answer (0-3)
    correct_index   SMALLINT NOT NULL CHECK (correct_index BETWEEN 0 AND 3),

    -- Optional explanation shown after answering
    explanation     TEXT,

    -- Optional scripture reference
    scripture_ref   TEXT,           -- e.g. 'John 3:16'

    -- Ordering
    sort_order      INTEGER NOT NULL DEFAULT 0,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quiz_questions_quiz_id    ON public.quiz_questions (quiz_id);
CREATE INDEX idx_quiz_questions_sort       ON public.quiz_questions (quiz_id, sort_order);

-- ============================================================
-- TABLE: quiz_attempts
-- ============================================================
CREATE TABLE public.quiz_attempts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    quiz_id         UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,

    -- Answers: array of chosen option indices, ordered by question sort_order
    answers_given   SMALLINT[] NOT NULL DEFAULT '{}',

    -- Score
    questions_total SMALLINT NOT NULL DEFAULT 0,
    questions_correct SMALLINT NOT NULL DEFAULT 0,
    score_percent   SMALLINT NOT NULL DEFAULT 0 CHECK (score_percent BETWEEN 0 AND 100),
    passed          BOOLEAN NOT NULL DEFAULT false,

    -- Timing
    time_taken_seconds INTEGER,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,

    -- Rewards actually granted (only if passed)
    holy_points_awarded INTEGER NOT NULL DEFAULT 0,
    faith_coins_awarded INTEGER NOT NULL DEFAULT 0,
    xp_awarded          INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_quiz_attempts_user_id  ON public.quiz_attempts (user_id);
CREATE INDEX idx_quiz_attempts_quiz_id  ON public.quiz_attempts (quiz_id);
CREATE INDEX idx_quiz_attempts_passed   ON public.quiz_attempts (user_id, quiz_id, passed);
CREATE INDEX idx_quiz_attempts_date     ON public.quiz_attempts (user_id, completed_at DESC);

-- ============================================================
-- FK from quests.linked_quiz_id -> quizzes.id
-- (couldn't add in 003 because quizzes table didn't exist yet)
-- ============================================================
ALTER TABLE public.quests
    ADD CONSTRAINT fk_quests_linked_quiz
    FOREIGN KEY (linked_quiz_id) REFERENCES public.quizzes(id) ON DELETE SET NULL;

-- ============================================================
-- VIEW: quiz_stats
-- Aggregate statistics per quiz
-- ============================================================
CREATE OR REPLACE VIEW public.quiz_stats AS
SELECT
    qa.quiz_id,
    COUNT(*)                                        AS attempt_count,
    ROUND(AVG(qa.score_percent), 1)                 AS avg_score,
    ROUND(AVG(qa.time_taken_seconds), 0)            AS avg_time_seconds,
    COUNT(*) FILTER (WHERE qa.passed = true)        AS pass_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE qa.passed = true) / NULLIF(COUNT(*), 0),
        1
    )                                               AS pass_rate_percent
FROM public.quiz_attempts qa
WHERE qa.completed_at IS NOT NULL
GROUP BY qa.quiz_id;

COMMENT ON TABLE  public.quizzes         IS 'Catalog of all available Catholic knowledge quizzes.';
COMMENT ON TABLE  public.quiz_questions  IS 'Individual questions belonging to a quiz, with 4 multiple-choice options.';
COMMENT ON TABLE  public.quiz_attempts   IS 'A record of each time a user attempts a quiz.';
COMMENT ON VIEW   public.quiz_stats      IS 'Aggregate performance statistics per quiz.';
