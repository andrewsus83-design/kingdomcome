-- ============================================================
-- Migration 009: Row Level Security Policies
-- ============================================================

-- ============================================================
-- Helper: anon / authenticated check
-- ============================================================

-- ============================================================
-- Enable RLS on all user-facing tables
-- ============================================================
ALTER TABLE public.user_profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kingdoms                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buildings                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quest_completions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saints                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_saints               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bible_books               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bible_verses              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verse_of_day              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reading_progress     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_verse_highlights     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artworks                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artwork_likes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parishes                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parish_members            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parish_leaderboard_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks              ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- user_profiles
-- ============================================================
CREATE POLICY "user_profiles_select_own"
    ON public.user_profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "user_profiles_update_own"
    ON public.user_profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Service role bypass (edge functions use service role)
CREATE POLICY "user_profiles_service_role_all"
    ON public.user_profiles FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- kingdoms
-- ============================================================
CREATE POLICY "kingdoms_select_own"
    ON public.kingdoms FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "kingdoms_update_own"
    ON public.kingdoms FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "kingdoms_insert_own"
    ON public.kingdoms FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "kingdoms_service_role_all"
    ON public.kingdoms FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- buildings
-- ============================================================
CREATE POLICY "buildings_select_own"
    ON public.buildings FOR SELECT
    TO authenticated
    USING (
        kingdom_id IN (
            SELECT id FROM public.kingdoms WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "buildings_insert_own"
    ON public.buildings FOR INSERT
    TO authenticated
    WITH CHECK (
        kingdom_id IN (
            SELECT id FROM public.kingdoms WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "buildings_update_own"
    ON public.buildings FOR UPDATE
    TO authenticated
    USING (
        kingdom_id IN (
            SELECT id FROM public.kingdoms WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "buildings_delete_own"
    ON public.buildings FOR DELETE
    TO authenticated
    USING (
        kingdom_id IN (
            SELECT id FROM public.kingdoms WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "buildings_service_role_all"
    ON public.buildings FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- quests (PUBLIC READ)
-- ============================================================
CREATE POLICY "quests_public_select"
    ON public.quests FOR SELECT
    TO anon, authenticated
    USING (is_active = true);

CREATE POLICY "quests_service_role_all"
    ON public.quests FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- quest_completions
-- INSERT is restricted to service_role (edge function only)
-- Users can only read their own completions
-- ============================================================
CREATE POLICY "quest_completions_select_own"
    ON public.quest_completions FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "quest_completions_service_role_all"
    ON public.quest_completions FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- saints (PUBLIC READ)
-- ============================================================
CREATE POLICY "saints_public_select"
    ON public.saints FOR SELECT
    TO anon, authenticated
    USING (is_active = true);

CREATE POLICY "saints_service_role_all"
    ON public.saints FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- user_saints
-- ============================================================
CREATE POLICY "user_saints_select_own"
    ON public.user_saints FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "user_saints_update_own"
    ON public.user_saints FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_saints_service_role_all"
    ON public.user_saints FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- bible_books (PUBLIC READ)
-- ============================================================
CREATE POLICY "bible_books_public_select"
    ON public.bible_books FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "bible_books_service_role_all"
    ON public.bible_books FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- bible_verses (PUBLIC READ)
-- ============================================================
CREATE POLICY "bible_verses_public_select"
    ON public.bible_verses FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "bible_verses_service_role_all"
    ON public.bible_verses FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- verse_of_day (PUBLIC READ)
-- ============================================================
CREATE POLICY "verse_of_day_public_select"
    ON public.verse_of_day FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "verse_of_day_service_role_all"
    ON public.verse_of_day FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- user_reading_progress
-- ============================================================
CREATE POLICY "reading_progress_select_own"
    ON public.user_reading_progress FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "reading_progress_insert_own"
    ON public.user_reading_progress FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "reading_progress_update_own"
    ON public.user_reading_progress FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "reading_progress_service_role_all"
    ON public.user_reading_progress FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- user_verse_highlights
-- ============================================================
CREATE POLICY "highlights_select_own"
    ON public.user_verse_highlights FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "highlights_insert_own"
    ON public.user_verse_highlights FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "highlights_update_own"
    ON public.user_verse_highlights FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "highlights_delete_own"
    ON public.user_verse_highlights FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "highlights_service_role_all"
    ON public.user_verse_highlights FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- quizzes (PUBLIC READ for active quizzes)
-- ============================================================
CREATE POLICY "quizzes_public_select"
    ON public.quizzes FOR SELECT
    TO anon, authenticated
    USING (is_active = true);

CREATE POLICY "quizzes_service_role_all"
    ON public.quizzes FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- quiz_questions (PUBLIC READ, questions visible with quiz)
-- ============================================================
CREATE POLICY "quiz_questions_public_select"
    ON public.quiz_questions FOR SELECT
    TO anon, authenticated
    USING (
        quiz_id IN (SELECT id FROM public.quizzes WHERE is_active = true)
    );

CREATE POLICY "quiz_questions_service_role_all"
    ON public.quiz_questions FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- quiz_attempts
-- ============================================================
CREATE POLICY "quiz_attempts_select_own"
    ON public.quiz_attempts FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "quiz_attempts_insert_own"
    ON public.quiz_attempts FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "quiz_attempts_update_own"
    ON public.quiz_attempts FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "quiz_attempts_service_role_all"
    ON public.quiz_attempts FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- artworks
-- Own artworks: full CRUD
-- Other users: can see if displayed_in_kingdom = true AND approved
-- ============================================================
CREATE POLICY "artworks_select_own"
    ON public.artworks FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "artworks_select_public"
    ON public.artworks FOR SELECT
    TO authenticated
    USING (
        displayed_in_kingdom = true
        AND moderation_status = 'approved'
    );

CREATE POLICY "artworks_insert_own"
    ON public.artworks FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "artworks_update_own"
    ON public.artworks FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "artworks_delete_own"
    ON public.artworks FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "artworks_service_role_all"
    ON public.artworks FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- artwork_likes
-- ============================================================
CREATE POLICY "artwork_likes_select"
    ON public.artwork_likes FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "artwork_likes_insert_own"
    ON public.artwork_likes FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "artwork_likes_delete_own"
    ON public.artwork_likes FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "artwork_likes_service_role_all"
    ON public.artwork_likes FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- parishes
-- Members can read their parish; admins can update
-- ============================================================
CREATE POLICY "parishes_select_member"
    ON public.parishes FOR SELECT
    TO authenticated
    USING (
        id IN (
            SELECT parish_id FROM public.parish_members
            WHERE user_id = auth.uid()
        )
        OR is_active = true  -- allow discovery by invite code lookup
    );

CREATE POLICY "parishes_update_admin"
    ON public.parishes FOR UPDATE
    TO authenticated
    USING (admin_user_id = auth.uid())
    WITH CHECK (admin_user_id = auth.uid());

CREATE POLICY "parishes_insert_authenticated"
    ON public.parishes FOR INSERT
    TO authenticated
    WITH CHECK (admin_user_id = auth.uid());

CREATE POLICY "parishes_service_role_all"
    ON public.parishes FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- parish_members
-- ============================================================
CREATE POLICY "parish_members_select_own_parish"
    ON public.parish_members FOR SELECT
    TO authenticated
    USING (
        parish_id IN (
            SELECT parish_id FROM public.parish_members
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "parish_members_insert_own"
    ON public.parish_members FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "parish_members_delete_own"
    ON public.parish_members FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "parish_members_service_role_all"
    ON public.parish_members FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- parish_leaderboard_weekly
-- ============================================================
CREATE POLICY "plw_select_parish_members"
    ON public.parish_leaderboard_weekly FOR SELECT
    TO authenticated
    USING (
        parish_id IN (
            SELECT parish_id FROM public.parish_members
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "plw_service_role_all"
    ON public.parish_leaderboard_weekly FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- user_streaks
-- ============================================================
CREATE POLICY "user_streaks_select_own"
    ON public.user_streaks FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "user_streaks_service_role_all"
    ON public.user_streaks FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
