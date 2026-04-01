-- ============================================================
-- achievements.sql seed — 40 achievements across 7 categories
-- ============================================================

INSERT INTO achievements (id, title, description, category, icon_asset_path, holy_points_reward, required_count, is_secret, share_image_template)
VALUES

-- ── PRAYER (6) ───────────────────────────────────────────────────────────────

('first_prayer',
 'First Steps',
 'Complete your first prayer quest. Every journey begins with a single prayer.',
 'prayer',
 'assets/images/achievements/prayer_1.png',
 20, 1, FALSE, 'share_first_prayer'),

('prayer_streak_7',
 'Prayer Warrior',
 'Pray 7 days in a row. A week of faithful prayer!',
 'prayer',
 'assets/images/achievements/prayer_2.png',
 50, 7, FALSE, 'share_streak_7'),

('prayer_streak_30',
 'Devoted Soul',
 'Pray 30 days in a row. A whole month of daily prayer!',
 'prayer',
 'assets/images/achievements/prayer_3.png',
 200, 30, FALSE, 'share_streak_30'),

('first_rosary',
 'Rosary Champion',
 'Complete your first full Rosary. Hail Mary, full of grace!',
 'prayer',
 'assets/images/achievements/rosary.png',
 40, 1, FALSE, 'share_rosary'),

('rosary_5',
 'Hail Mary Hero',
 'Complete 5 full Rosaries. You are a true devotee of Our Lady!',
 'prayer',
 'assets/images/achievements/rosary_5.png',
 100, 5, FALSE, NULL),

('mass_10',
 'Mass Goer',
 'Log attending Holy Mass 10 times. The Eucharist is the source and summit!',
 'prayer',
 'assets/images/achievements/mass.png',
 120, 10, FALSE, 'share_mass'),

-- ── KNOWLEDGE (6) ────────────────────────────────────────────────────────────

('first_quiz',
 'First Quiz',
 'Complete your first Bible quiz. Knowledge of Scripture is food for the soul.',
 'knowledge',
 'assets/images/achievements/quiz_1.png',
 15, 1, FALSE, NULL),

('quiz_master',
 'Quiz Master',
 'Score 100% on 10 different quizzes. You know your faith inside out!',
 'knowledge',
 'assets/images/achievements/quiz_master.png',
 150, 10, FALSE, 'share_quiz_master'),

('scripture_scholar',
 'Scripture Scholar',
 'Master 50 Bible verses in Scripture Builder. The Word of God dwells in you richly.',
 'knowledge',
 'assets/images/achievements/scripture.png',
 200, 50, FALSE, 'share_scripture'),

('saints_expert',
 'Saints Expert',
 'Learn about 20 different saints. These are your brothers and sisters in heaven!',
 'knowledge',
 'assets/images/achievements/saints.png',
 100, 20, FALSE, NULL),

('catechism_student',
 'Catechism Student',
 'Answer 100 Catholic doctrine questions correctly. You know the Catechism!',
 'knowledge',
 'assets/images/achievements/catechism.png',
 175, 100, FALSE, NULL),

('calendar_expert',
 'Liturgical Scholar',
 'Complete the Liturgy Calendar puzzle on Hard mode. You know the sacred year!',
 'knowledge',
 'assets/images/achievements/calendar.png',
 120, 1, FALSE, 'share_calendar'),

-- ── KINGDOM (5) ──────────────────────────────────────────────────────────────

('first_building',
 'Foundation Stone',
 'Build your first structure. Your kingdom for God begins!',
 'kingdom',
 'assets/images/achievements/build_1.png',
 25, 1, FALSE, NULL),

('level_5_cathedral',
 'Great Cathedral',
 'Upgrade your Cathedral to Level 5. A beacon of faith in your kingdom!',
 'kingdom',
 'assets/images/achievements/cathedral.png',
 300, 5, FALSE, 'share_cathedral'),

('kingdom_builder',
 'Master Builder',
 'Construct 10 buildings in your kingdom. Your city for God grows!',
 'kingdom',
 'assets/images/achievements/builder.png',
 200, 10, FALSE, NULL),

('full_kingdom',
 'Holy Kingdom',
 'Fill every grid space in your kingdom. A complete city for God!',
 'kingdom',
 'assets/images/achievements/kingdom.png',
 500, 1, FALSE, 'share_kingdom'),

('kingdom_level_10',
 'Kingdom Champion',
 'Reach Kingdom Level 10. Your faith has built something magnificent!',
 'kingdom',
 'assets/images/achievements/kingdom_10.png',
 400, 10, FALSE, 'share_kingdom_level'),

-- ── SOCIAL (5) ───────────────────────────────────────────────────────────────

('join_parish',
 'Parish Member',
 'Join your first parish group. You belong to the Body of Christ!',
 'social',
 'assets/images/achievements/parish.png',
 30, 1, FALSE, NULL),

('invite_friend',
 'Good Shepherd',
 'Invite a friend to Kingdom Come. Share the faith!',
 'social',
 'assets/images/achievements/invite.png',
 50, 1, FALSE, 'share_invite'),

('family_mission',
 'Family Blessing',
 'Complete 3 family missions together. A family that prays together stays together!',
 'social',
 'assets/images/achievements/family.png',
 100, 3, FALSE, NULL),

('class_top',
 'Class Leader',
 'Reach #1 on your class leaderboard. You lead by faith!',
 'social',
 'assets/images/achievements/class_top.png',
 150, 1, FALSE, 'share_top'),

('parish_top_10',
 'Parish Star',
 'Reach the top 10 in your parish leaderboard.',
 'social',
 'assets/images/achievements/parish_star.png',
 80, 1, FALSE, NULL),

-- ── VIRTUE (6) ───────────────────────────────────────────────────────────────

('good_deed_10',
 'Virtue Hero',
 'Complete 10 Good Deed quests. Love your neighbour as yourself!',
 'virtue',
 'assets/images/achievements/virtue.png',
 100, 10, FALSE, 'share_virtue'),

('confession_5',
 'Reconciled Soul',
 'Complete 5 Confession quests. Receive God''s mercy again and again!',
 'virtue',
 'assets/images/achievements/confession.png',
 75, 5, FALSE, NULL),

('fasting_quest',
 'Fasting Champion',
 'Complete 3 Fasting quests. Fasting opens the heart to God.',
 'virtue',
 'assets/images/achievements/fasting.png',
 60, 3, FALSE, NULL),

('first_virtue_relic',
 'Relic Forger',
 'Forge your first saint relic in Virtue Forge. Virtue bears holy fruit!',
 'virtue',
 'assets/images/achievements/relic.png',
 80, 1, FALSE, NULL),

('all_relics',
 'Saint''s Treasury',
 'Discover all 15 relics in the Virtue Forge. You have mastered virtue!',
 'virtue',
 'assets/images/achievements/treasury.png',
 500, 15, TRUE, 'share_treasury'),

('almsgiving',
 'Generous Heart',
 'Complete 5 Almsgiving quests. The cheerful giver God loves!',
 'virtue',
 'assets/images/achievements/almsgiving.png',
 60, 5, FALSE, NULL),

-- ── ARTS (6) ─────────────────────────────────────────────────────────────────

('first_artwork',
 'Art Creator',
 'Create your first artwork. Beauty glorifies God!',
 'arts',
 'assets/images/achievements/art_1.png',
 25, 1, FALSE, NULL),

('artworks_10',
 'Sacred Artist',
 'Create 10 artworks. Your creativity honors the Creator!',
 'arts',
 'assets/images/achievements/art_10.png',
 100, 10, FALSE, 'share_artist'),

('ai_art',
 'AI Illuminator',
 'Generate your first AI artwork. Technology at the service of beauty!',
 'arts',
 'assets/images/achievements/ai_art.png',
 50, 1, FALSE, NULL),

('stained_glass',
 'Glassmaker',
 'Complete all 3 stained glass templates. Light and color for God''s glory!',
 'arts',
 'assets/images/achievements/glass.png',
 75, 3, FALSE, NULL),

('kingdom_display',
 'Gallery Owner',
 'Display 5 artworks in your kingdom. Your kingdom is beautiful!',
 'arts',
 'assets/images/achievements/gallery.png',
 80, 5, FALSE, NULL),

('hymn_generated',
 'Hymn Composer',
 'Generate your first AI hymn. Sing a new song to the Lord!',
 'arts',
 'assets/images/achievements/hymn.png',
 40, 1, FALSE, NULL),

-- ── GAMES (6) ────────────────────────────────────────────────────────────────

('first_game',
 'Game On!',
 'Play your first mini-game. Let the holy games begin!',
 'games',
 'assets/images/achievements/game_1.png',
 20, 1, FALSE, NULL),

('game_high_score',
 'High Scorer',
 'Achieve a personal best score in any game. Excellence in all things!',
 'games',
 'assets/images/achievements/high_score.png',
 50, 1, FALSE, NULL),

('daily_game_7',
 'Daily Challenger',
 'Complete the daily game challenge 7 days in a row. Faithful in little things!',
 'games',
 'assets/images/achievements/daily_game.png',
 100, 7, FALSE, 'share_daily_game'),

('all_games',
 'Game Master',
 'Play all 6 mini-games at least once. A player of many virtues!',
 'games',
 'assets/images/achievements/game_master.png',
 150, 6, FALSE, 'share_game_master'),

('full_rosary_runner',
 'Rosary Complete!',
 'Collect all 50 beads in a single Rosary Runner game. The full Rosary prayed!',
 'games',
 'assets/images/achievements/rosary_runner.png',
 75, 1, FALSE, 'share_rosary_runner'),

('saint_defender_wave15',
 'Virtue Defender',
 'Survive all 15 waves across 3 levels in Saint Defender. Vices defeated!',
 'games',
 'assets/images/achievements/defender.png',
 250, 15, TRUE, 'share_defender'),

('trivia_streak_5',
 'Bible Expert',
 'Win 5 Bible Trivia Duels in a row without losing. Unbeatable knowledge!',
 'games',
 'assets/images/achievements/trivia.png',
 200, 5, TRUE, 'share_trivia')

ON CONFLICT (id) DO UPDATE SET
  title                = EXCLUDED.title,
  description          = EXCLUDED.description,
  category             = EXCLUDED.category,
  holy_points_reward   = EXCLUDED.holy_points_reward,
  required_count       = EXCLUDED.required_count,
  is_secret            = EXCLUDED.is_secret,
  share_image_template = EXCLUDED.share_image_template;
