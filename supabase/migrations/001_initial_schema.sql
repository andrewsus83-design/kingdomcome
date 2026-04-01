-- ============================================================
-- Migration 001: Initial Schema
-- Extensions, user_profiles, auto-profile creation trigger
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TABLE: user_profiles
-- ============================================================
CREATE TABLE public.user_profiles (
    id                      UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username                TEXT UNIQUE,
    display_name            TEXT,
    avatar_url              TEXT,
    -- age_group: 1 = child (8-11), 2 = teen (12-15), 3 = older teen (16-18)
    age_group               SMALLINT CHECK (age_group BETWEEN 1 AND 3),
    parental_consent_given  BOOLEAN NOT NULL DEFAULT false,
    parent_email            TEXT,
    parish_id               UUID,           -- FK added in 008 after parishes table exists

    -- Gamification resources
    total_holy_points       BIGINT NOT NULL DEFAULT 0,
    current_level           SMALLINT NOT NULL DEFAULT 1,
    level_xp                INTEGER NOT NULL DEFAULT 0,
    faith_coins             INTEGER NOT NULL DEFAULT 0,
    blessings               INTEGER NOT NULL DEFAULT 0,
    grace                   INTEGER NOT NULL DEFAULT 0,

    -- Streak tracking
    current_streak          INTEGER NOT NULL DEFAULT 0,
    longest_streak          INTEGER NOT NULL DEFAULT 0,
    last_activity_date      DATE,

    -- Active saint companion
    active_saint_id         UUID,           -- FK added in 004 after saints table exists

    -- Flexible preferences storage
    preferences             JSONB NOT NULL DEFAULT '{}',

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_user_profiles_username       ON public.user_profiles (username);
CREATE INDEX idx_user_profiles_parish_id      ON public.user_profiles (parish_id);
CREATE INDEX idx_user_profiles_total_holy_pts ON public.user_profiles (total_holy_points DESC);
CREATE INDEX idx_user_profiles_last_active    ON public.user_profiles (last_active_at DESC);

-- ============================================================
-- FUNCTION: handle_new_user
-- Auto-creates a user_profile row on auth.users INSERT
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_username TEXT;
BEGIN
    -- Derive an initial username from email or id
    v_username := COALESCE(
        NEW.raw_user_meta_data->>'username',
        SPLIT_PART(NEW.email, '@', 1) || '_' || SUBSTR(REPLACE(NEW.id::TEXT, '-', ''), 1, 6)
    );

    INSERT INTO public.user_profiles (
        id,
        username,
        display_name,
        avatar_url,
        age_group,
        parental_consent_given,
        parent_email,
        total_holy_points,
        current_level,
        level_xp,
        faith_coins,
        blessings,
        grace,
        current_streak,
        longest_streak,
        preferences,
        created_at,
        last_active_at
    ) VALUES (
        NEW.id,
        v_username,
        COALESCE(NEW.raw_user_meta_data->>'display_name', v_username),
        NEW.raw_user_meta_data->>'avatar_url',
        COALESCE((NEW.raw_user_meta_data->>'age_group')::SMALLINT, 2),
        COALESCE((NEW.raw_user_meta_data->>'parental_consent_given')::BOOLEAN, false),
        NEW.raw_user_meta_data->>'parent_email',
        0,  -- total_holy_points
        1,  -- current_level
        0,  -- level_xp
        50, -- faith_coins starter bonus
        0,  -- blessings
        0,  -- grace
        0,  -- current_streak
        0,  -- longest_streak
        '{"notifications_enabled": true, "daily_reminder_time": "08:00", "theme": "default"}'::JSONB,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- ============================================================
-- TRIGGER: on_auth_user_created
-- Fires after each new user is inserted into auth.users
-- ============================================================
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- FUNCTION: update_last_active
-- Keeps last_active_at fresh on any profile update
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_last_active()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.last_active_at := NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_user_profiles_last_active
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_active();

-- ============================================================
-- FUNCTION: get_level_threshold
-- Returns the total_holy_points needed to reach a given level.
-- Formula: level 1 = 0, level n = 100 * (n-1)^2 + 50 * (n-1)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_level_threshold(p_level SMALLINT)
RETURNS BIGINT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN p_level <= 1 THEN 0
        ELSE (100 * (p_level - 1)^2 + 50 * (p_level - 1))::BIGINT
    END;
$$;

COMMENT ON TABLE public.user_profiles IS
    'Core user profile table storing game state, resources, and preferences for every registered player.';
