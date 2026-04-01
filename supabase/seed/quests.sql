-- ============================================================
-- Seed: Quests (30+ quests across all categories)
-- ============================================================
-- Reward reference (holy_points / faith_coins / grace / blessings / xp):
--   Easy daily prayer:    50 / 5 / 2 / 0 / 20
--   Medium quest:        100 / 10 / 5 / 1 / 40
--   Hard quest:          200 / 20 / 10 / 2 / 80
--   Mass attendance:     150 / 10 / 5 / 1 / 50
--   Sacramental:         300 / 25 / 15 / 5 / 100
-- ============================================================

INSERT INTO public.quests (
    title, description, instructions, category, difficulty,
    verification_type, repeat_frequency,
    day_of_week, liturgical_season,
    min_age_group, min_level, required_building, required_building_level,
    holy_points_reward, faith_coins_reward, grace_reward, blessings_reward, xp_reward,
    icon_name, is_active, is_featured, sort_order
) VALUES

-- ============================================================
-- SECTION 1: DAILY PRAYER (7 quests — one per day of week)
-- day_of_week: 0=Sun, 1=Mon, ..., 6=Sat
-- ============================================================

(
    'Sunday Morning Prayer',
    'Begin the Lord''s Day with a prayer of praise and gratitude.',
    'Find a quiet place. Make the Sign of the Cross. Pray the Our Father, Hail Mary, and Glory Be. Then spend 3 minutes in silence thanking God for His blessings this week.',
    'prayer', 'easy', 'self_report', 'daily',
    0, NULL, 1, 1, 'chapel', 1,
    60, 5, 3, 0, 25,
    'prayer_sunrise', true, true, 1
),
(
    'Monday''s Morning Offering',
    'Offer your entire day to God as a living prayer.',
    'Pray the Morning Offering: "O Jesus, through the Immaculate Heart of Mary, I offer You my prayers, works, joys and sufferings of this day..." Reflect for 2 minutes on one intention for today.',
    'prayer', 'easy', 'self_report', 'daily',
    1, NULL, 1, 1, NULL, 1,
    50, 5, 2, 0, 20,
    'prayer_morning', true, false, 2
),
(
    'Tuesday''s Chaplet of Divine Mercy',
    'Pray the Chaplet of Divine Mercy for sinners and the dying.',
    'Using your rosary beads, pray the Chaplet of Divine Mercy. Begin with: "You expired, Jesus, but the source of life gushed forth for souls..." Complete all five decades.',
    'prayer', 'easy', 'self_report', 'daily',
    2, NULL, 1, 1, 'chapel', 1,
    60, 5, 5, 1, 25,
    'prayer_chaplet', true, false, 3
),
(
    'Wednesday''s Prayer for Vocations',
    'Pray for those discerning a call to priesthood or religious life.',
    'Spend 5 minutes in prayer for vocations. Pray: "Lord of the harvest, send forth laborers into Your harvest. Give us holy priests, deacons, and religious to shepherd Your people." Then pray one Our Father for this intention.',
    'prayer', 'easy', 'self_report', 'daily',
    3, NULL, 1, 1, NULL, 1,
    50, 5, 2, 0, 20,
    'prayer_vocations', true, false, 4
),
(
    'Thursday''s Eucharistic Adoration Prayer',
    'Spend time in spiritual adoration before the Blessed Sacrament.',
    'Even if you cannot visit a church, you can make a spiritual communion. Pray: "My Jesus, I believe that You are present in the Most Holy Sacrament. I love You above all things and I desire to receive You into my soul..." Spend 5 minutes in quiet contemplation.',
    'prayer', 'easy', 'self_report', 'daily',
    4, NULL, 1, 1, 'chapel', 1,
    70, 8, 4, 1, 30,
    'prayer_eucharist', true, false, 5
),
(
    'Friday''s Stations of the Cross',
    'Walk the Stations of the Cross meditating on Christ''s Passion.',
    'Pray all 14 stations. At each station: "We adore You, O Christ, and we praise You. Because by Your holy cross You have redeemed the world." Meditate briefly on each station''s mystery.',
    'prayer', 'medium', 'self_report', 'daily',
    5, NULL, 1, 2, NULL, 1,
    100, 10, 8, 2, 40,
    'prayer_stations', true, false, 6
),
(
    'Saturday''s Marian Consecration Prayer',
    'Consecrate yourself to Mary and pray the Memorare.',
    'Pray the Memorare: "Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to your protection, implored your help, or sought your intercession was left unaided..." Then spend 3 minutes asking for Mary''s intercession for your family.',
    'prayer', 'easy', 'self_report', 'daily',
    6, NULL, 1, 1, NULL, 1,
    55, 5, 3, 0, 22,
    'prayer_mary', true, false, 7
),

-- ============================================================
-- SECTION 2: ROSARY (3 quests — Joyful, Sorrowful, Glorious)
-- ============================================================

(
    'Joyful Mysteries Rosary',
    'Pray the five Joyful Mysteries of the Holy Rosary.',
    'Pray 5 decades of the Rosary meditating on the Joyful Mysteries: 1) The Annunciation 2) The Visitation 3) The Nativity 4) The Presentation 5) Finding Jesus in the Temple. Use your physical or digital rosary beads.',
    'rosary', 'easy', 'self_report', 'daily',
    NULL, NULL, 1, 1, 'oratory', 1,
    80, 8, 5, 1, 35,
    'rosary_joyful', true, false, 10
),
(
    'Sorrowful Mysteries Rosary',
    'Pray the five Sorrowful Mysteries of the Holy Rosary.',
    'Pray 5 decades meditating on the Sorrowful Mysteries: 1) Agony in the Garden 2) Scourging at the Pillar 3) Crowning with Thorns 4) Carrying the Cross 5) The Crucifixion. Recommended on Tuesdays and Fridays.',
    'rosary', 'easy', 'self_report', 'daily',
    NULL, NULL, 1, 1, 'oratory', 1,
    80, 8, 5, 1, 35,
    'rosary_sorrowful', true, false, 11
),
(
    'Glorious Mysteries Rosary',
    'Pray the five Glorious Mysteries of the Holy Rosary.',
    'Pray 5 decades meditating on the Glorious Mysteries: 1) The Resurrection 2) The Ascension 3) Descent of the Holy Spirit 4) The Assumption 5) Mary''s Coronation. Recommended on Sundays and Wednesdays.',
    'rosary', 'easy', 'self_report', 'daily',
    NULL, NULL, 1, 1, 'oratory', 1,
    80, 8, 5, 1, 35,
    'rosary_glorious', true, false, 12
),

-- ============================================================
-- SECTION 3: BIBLE READING (5 quests)
-- ============================================================

(
    'Read the Gospel of the Day',
    'Read and reflect on today''s Gospel reading from the Mass.',
    'Look up today''s daily Mass readings (use the app''s Bible section or a missal). Read the Gospel passage. Spend 5 minutes asking: What is Jesus saying to me today? Write one thought in your notes.',
    'bible_reading', 'easy', 'self_report', 'daily',
    NULL, NULL, 1, 1, 'scriptorium', 1,
    75, 8, 4, 0, 30,
    'bible_gospel', true, true, 20
),
(
    'Read a Psalm',
    'Read one complete Psalm and pray it as your own prayer.',
    'Open to the Book of Psalms. Choose one Psalm (try Psalm 23, 27, or 91 if unsure). Read it slowly. Then read it again as your own personal prayer to God.',
    'bible_reading', 'easy', 'self_report', 'daily',
    NULL, NULL, 1, 1, NULL, 1,
    60, 6, 3, 0, 25,
    'bible_psalm', true, false, 21
),
(
    'New Testament Chapter',
    'Read one full chapter from the New Testament.',
    'Choose any book from the New Testament (e.g., Matthew, Mark, Luke, John, Acts, or the Letters). Read one complete chapter. After reading, note one thing that surprised, inspired, or challenged you.',
    'bible_reading', 'medium', 'self_report', 'daily',
    NULL, NULL, 1, 2, 'scriptorium', 1,
    90, 10, 5, 0, 40,
    'bible_new_testament', true, false, 22
),
(
    'Old Testament Story',
    'Read a narrative passage from the Old Testament.',
    'Choose a narrative section from the Old Testament — perhaps from Genesis, Exodus, the Books of Kings, or the story of Ruth. Read at least 10 verses. Identify how God is working in the story.',
    'bible_reading', 'medium', 'self_report', 'weekly',
    NULL, NULL, 2, 3, 'scriptorium', 2,
    120, 12, 6, 0, 50,
    'bible_old_testament', true, false, 23
),
(
    'Memorize a Scripture Verse',
    'Choose a Bible verse and memorize it completely.',
    'Select a verse (suggestions: John 3:16, Philippians 4:13, Proverbs 3:5-6, or any verse that speaks to you). Write it 5 times. Then recite it from memory. This verse is now yours forever!',
    'bible_reading', 'hard', 'self_report', 'weekly',
    NULL, NULL, 1, 3, NULL, 1,
    200, 20, 10, 2, 80,
    'bible_memorize', true, false, 24
),

-- ============================================================
-- SECTION 4: GOOD DEEDS (5 quests)
-- ============================================================

(
    'Act of Kindness',
    'Perform a deliberate act of kindness for someone today.',
    'Do something kind for a person in your life — a family member, friend, classmate, or stranger. Ideas: help with chores without being asked, write an encouraging note, hold a door open, share your lunch, compliment someone sincerely. Report what you did!',
    'good_deed', 'easy', 'self_report', 'daily',
    NULL, NULL, 1, 1, NULL, 1,
    70, 7, 3, 1, 28,
    'deed_kindness', true, true, 30
),
(
    'Help at Home',
    'Help your family without being asked.',
    'Do at least two chores or helpful tasks at home without waiting to be told. Examples: wash the dishes, take out the trash, vacuum, help a younger sibling with homework, cook a meal, or tidy a shared space.',
    'good_deed', 'easy', 'self_report', 'daily',
    NULL, NULL, 1, 1, NULL, 1,
    60, 6, 2, 0, 25,
    'deed_home', true, false, 31
),
(
    'Pray for Someone Who Hurt You',
    'Practice forgiveness by praying for someone who has wronged you.',
    'Think of someone who has hurt you or that you find difficult. Pray for them by name: "Lord, I forgive [name] and ask you to bless them and bring them close to You." This can be hard — that''s what makes it heroic.',
    'good_deed', 'hard', 'self_report', 'weekly',
    NULL, NULL, 1, 1, NULL, 1,
    180, 15, 12, 3, 70,
    'deed_forgiveness', true, false, 32
),
(
    'Write a Thank-You Note',
    'Express gratitude in writing to someone who has helped you.',
    'Think of someone who has made a positive difference in your life — a parent, teacher, coach, friend, or priest. Write them a genuine thank-you note or message expressing what they mean to you. Send it or give it to them.',
    'good_deed', 'easy', 'photo_proof', 'weekly',
    NULL, NULL, 1, 1, NULL, 1,
    100, 10, 5, 1, 40,
    'deed_gratitude', true, false, 33
),
(
    'Volunteer or Serve',
    'Give your time to serve others in your community.',
    'Volunteer for at least 30 minutes. Ideas: help at a food pantry, clean up litter in your neighborhood, assist at a parish event, help an elderly neighbor, or tutor a younger student. Upload a photo of your service.',
    'good_deed', 'medium', 'photo_proof', 'weekly',
    NULL, NULL, 2, 5, NULL, 1,
    150, 15, 8, 2, 60,
    'deed_volunteer', true, false, 34
),

-- ============================================================
-- SECTION 5: MASS ATTENDANCE (2 quests)
-- ============================================================

(
    'Sunday Mass',
    'Attend the Sunday Eucharist — the source and summit of the Christian life.',
    'Attend Holy Mass at your parish (or any Catholic church) on Sunday. Participate fully: sing the hymns, respond to the prayers, receive Communion if prepared. After Mass, spend 5 minutes in thanksgiving.',
    'mass_attendance', 'easy', 'location_check', 'weekly',
    0, NULL, 1, 1, NULL, 1,
    150, 10, 5, 1, 50,
    'mass_sunday', true, true, 40
),
(
    'Weekday Mass',
    'Go above and beyond by attending a weekday Mass.',
    'Attend a daily Mass during the week (Monday-Saturday). Check your local parish schedule for Mass times. Attending weekday Mass is a beautiful way to deepen your relationship with the Eucharist.',
    'mass_attendance', 'medium', 'location_check', 'daily',
    NULL, NULL, 2, 5, NULL, 1,
    200, 15, 10, 2, 75,
    'mass_weekday', true, false, 41
),

-- ============================================================
-- SECTION 6: CONFESSION (2 quests)
-- ============================================================

(
    'Examination of Conscience',
    'Prepare for Confession with a thorough examination of conscience.',
    'Before going to Confession, spend 10-15 minutes examining your conscience. Use the Ten Commandments as a guide. Be honest about your sins. Write them down if it helps. Then say a sincere Act of Contrition.',
    'confession', 'easy', 'self_report', 'weekly',
    NULL, NULL, 2, 2, NULL, 1,
    100, 10, 8, 2, 40,
    'confession_examine', true, false, 50
),
(
    'Go to Confession',
    'Receive the Sacrament of Reconciliation and experience God''s mercy.',
    'Go to Confession at your parish. The steps: 1) Examination of conscience 2) Tell the priest your sins 3) Receive penance 4) Pray the Act of Contrition 5) Receive absolution. Remember: the priest is bound by the seal of confession. Welcome home!',
    'confession', 'hard', 'parent_confirm', 'monthly',
    NULL, NULL, 2, 3, NULL, 1,
    300, 25, 20, 5, 100,
    'confession_sacrament', true, true, 51
),

-- ============================================================
-- SECTION 7: QUIZ QUESTS (3 quests)
-- ============================================================

(
    'Sacraments Quiz Challenge',
    'Test your knowledge of the Seven Sacraments.',
    'Complete the "Sacraments Basics" quiz with a score of 70% or higher. Take your time and read each question carefully!',
    'quiz', 'easy', 'quiz_completion', 'weekly',
    NULL, NULL, 1, 1, 'school', 1,
    80, 8, 3, 0, 35,
    'quiz_sacraments', true, false, 60
),
(
    'Saints of the Church Quiz',
    'How well do you know your Catholic saints?',
    'Complete the "Saints of the Church" quiz with a passing score. Read the explanations for any questions you miss — learning from mistakes earns wisdom!',
    'quiz', 'easy', 'quiz_completion', 'weekly',
    NULL, NULL, 1, 1, 'school', 1,
    80, 8, 3, 0, 35,
    'quiz_saints', true, false, 61
),
(
    'Church History Master',
    'Demonstrate advanced knowledge of Church history.',
    'Complete the "Church History" quiz (difficulty level 3). This is a challenging quiz — pray to the Holy Spirit for wisdom before you begin!',
    'quiz', 'hard', 'quiz_completion', 'weekly',
    NULL, NULL, 3, 8, 'school', 2,
    250, 22, 12, 3, 90,
    'quiz_church_history', true, false, 62
),

-- ============================================================
-- SECTION 8: LITURGICAL SEASON QUESTS (3 quests)
-- ============================================================

(
    'Advent: Light an Advent Candle',
    'Participate in the Advent wreath tradition as your family prepares for Christmas.',
    'Light one of the candles on your Advent wreath (or make a simple Advent wreath). Read the Advent candle prayer for the week. Spend 3 minutes thinking about how you will prepare your heart for Jesus this Advent.',
    'liturgical_event', 'easy', 'photo_proof', 'weekly',
    NULL, 'advent', 1, 1, NULL, 1,
    120, 12, 6, 1, 50,
    'advent_candle', true, false, 70
),
(
    'Lent: Fasting & Abstinence',
    'Observe the Lenten discipline of fasting or abstaining from meat.',
    'On a Friday of Lent, abstain from meat. Or choose a personal fast (e.g., no sweets, no screens for an hour). Offer this sacrifice for a specific intention. Remember: "When you fast, do not look gloomy like the hypocrites" (Matthew 6:16).',
    'liturgical_event', 'medium', 'self_report', 'weekly',
    NULL, 'lent', 2, 2, NULL, 1,
    150, 12, 10, 3, 60,
    'lent_fast', true, false, 71
),
(
    'Easter Vigil: Renew Your Baptismal Promises',
    'Renew the promises made at your Baptism during the Easter Season.',
    'At any point during the Easter Season (from Easter Sunday to Pentecost Sunday), pray the Baptismal Promises: renounce Satan and all his works, and renew your faith in the Triune God. Optionally, sprinkle yourself with holy water as a reminder of your Baptism.',
    'liturgical_event', 'easy', 'self_report', 'once',
    NULL, 'easter', 1, 1, NULL, 1,
    200, 18, 12, 3, 80,
    'easter_baptism', true, false, 72
),

-- ============================================================
-- SECTION 9: ARTS & CRAFTS (2 quests)
-- ============================================================

(
    'Draw a Saint',
    'Create a drawing or painting of your favorite saint.',
    'Choose a Catholic saint you admire. Create a drawing, painting, or digital artwork depicting them. Try to capture something meaningful about their story or character. Upload your artwork when finished!',
    'arts_crafts', 'easy', 'photo_proof', 'weekly',
    NULL, NULL, 1, 1, 'workshop', 1,
    120, 12, 5, 1, 50,
    'arts_saint', true, false, 80
),
(
    'Illuminate a Scripture Verse',
    'Create illuminated calligraphy of a Bible verse.',
    'Choose a Bible verse that inspires you. Write it in your best handwriting or calligraphy, decorating the borders with illustrations inspired by Catholic art (vines, flowers, geometric patterns, angels). Take a photo and submit!',
    'arts_crafts', 'medium', 'photo_proof', 'weekly',
    NULL, NULL, 1, 3, 'workshop', 2,
    150, 15, 7, 1, 60,
    'arts_calligraphy', true, false, 81
);
