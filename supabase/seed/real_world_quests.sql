-- ============================================================
-- Seed: Real World Quests (40 quests across 7 categories)
-- ============================================================

-- ============================================================
-- HOME LIFE (8 quests)
-- ============================================================

INSERT INTO public.real_world_quests
    (title, description, category, verification, holy_points_reward, faith_coins_reward, grace_reward,
     estimated_minutes, age_group_min, is_repeatable, repeat_frequency,
     icon_emoji, inspirational_quote, related_virtue, is_custom, sort_order)
VALUES

-- 1
(
    'Help Parents Cook Dinner',
    'Offer to help your parents prepare a meal tonight. Chop vegetables, stir pots, set the table — be a real helper in the kitchen!',
    'homeLife', 'parentValidate', 100, 0, 0,
    60, 1, true, 'weekly',
    '🍳',
    '"Whatever you do, work at it with all your heart, as working for the Lord." — Colossians 3:23',
    'Kindness', false, 10
),

-- 2
(
    'Clean Your Room Without Being Asked',
    'Tidy up your room all on your own — without anyone telling you to. Make your bed, put away toys, and organize your space.',
    'homeLife', 'photoScan', 75, 0, 0,
    30, 1, true, 'weekly',
    '🧹',
    '"Order is the first law of heaven." — St. Thomas Aquinas',
    'Responsibility', false, 20
),

-- 3
(
    'Set the Dinner Table',
    'Before dinner, set the table for your whole family — plates, cups, cutlery, and napkins for everyone!',
    'homeLife', 'parentValidate', 0, 50, 0,
    10, 1, true, 'daily',
    '🍽️',
    '"Serve one another humbly in love." — Galatians 5:13',
    'Helpfulness', false, 30
),

-- 4
(
    'Help with Laundry',
    'Help sort, fold, or put away laundry for the family. Service starts right at home!',
    'homeLife', 'parentValidate', 75, 0, 0,
    30, 1, true, 'weekly',
    '🧺',
    '"Let each of you look not only to his own interests, but also to the interests of others." — Philippians 2:4',
    'Service', false, 40
),

-- 5
(
    'Read a Physical Book for 30 Minutes',
    'Put down the screen and open a real book! Read for at least 30 minutes today — a story, a biography, or anything that grows your mind.',
    'homeLife', 'parentValidate', 60, 0, 0,
    30, 1, true, 'daily',
    '📚',
    '"The reading of good books is like a conversation with the finest men of past centuries." — René Descartes',
    'Wisdom', false, 50
),

-- 6
(
    'Help a Sibling with Homework',
    'Does your brother or sister need help? Sit down with them and help explain a problem or check their work.',
    'homeLife', 'parentValidate', 80, 0, 0,
    30, 2, true, 'weekly',
    '✏️',
    '"Charity begins at home." — St. Thomas Aquinas',
    'Charity', false, 60
),

-- 7
(
    'Make Your Bed Every Morning for a Week',
    'Every morning this week, make your bed before leaving your room. A small act of discipline becomes a great habit!',
    'homeLife', 'parentValidate', 200, 0, 0,
    5, 1, false, 'once',
    '🛏️',
    '"Do not neglect small daily practices. They are the foundation of great holiness." — St. Thérèse of Lisieux',
    'Discipline', false, 70
),

-- 8
(
    'Say Grace Before Every Meal Today',
    'Before every meal today — breakfast, lunch, and dinner — pause and say grace to thank God for your food.',
    'homeLife', 'honorSystem', 30, 0, 0,
    5, 1, true, 'daily',
    '🙏',
    '"Bless us, O Lord, and these Thy gifts which we are about to receive from Thy bounty." — Traditional Catholic Grace',
    'Gratitude', false, 80
);

-- ============================================================
-- SCHOOL LIFE (6 quests)
-- ============================================================

INSERT INTO public.real_world_quests
    (title, description, category, verification, holy_points_reward, faith_coins_reward, grace_reward,
     estimated_minutes, age_group_min, is_repeatable, repeat_frequency,
     icon_emoji, inspirational_quote, related_virtue, is_custom, sort_order)
VALUES

-- 9
(
    'Help a Classmate Who''s Struggling',
    'Notice a friend who doesn''t understand something in class today. Offer to help explain it or sit with them during study time.',
    'schoolLife', 'honorSystem', 80, 0, 0,
    20, 1, true, 'weekly',
    '🤝',
    '"No act of kindness, no matter how small, is ever wasted." — Aesop',
    'Compassion', false, 10
),

-- 10
(
    'Don''t Gossip or Speak Badly About Anyone Today',
    'For a whole day, choose to speak only kindly about others. If you don''t have something good to say, stay silent.',
    'schoolLife', 'honorSystem', 60, 0, 0,
    480, 1, true, 'daily',
    '🤐',
    '"If you have nothing good to say, say nothing at all." — St. Francis de Sales',
    'Charity', false, 20
),

-- 11
(
    'Finish Homework Before Using Gadgets',
    'Today, complete all your homework assignments before picking up your phone, tablet, or gaming device.',
    'schoolLife', 'parentValidate', 0, 75, 0,
    60, 1, true, 'daily',
    '📖',
    '"Do first things first." — St. Ignatius of Loyola',
    'Discipline', false, 30
),

-- 12
(
    'Smile and Greet Someone You Don''t Know',
    'Today, smile and say hello to someone you don''t usually talk to — a new classmate, a teacher, or someone sitting alone.',
    'schoolLife', 'honorSystem', 40, 0, 0,
    5, 1, true, 'weekly',
    '😊',
    '"A warm smile is the universal language of kindness." — William Arthur Ward',
    'Friendliness', false, 40
),

-- 13
(
    'Stand Up for Someone Being Treated Unfairly',
    'If you see someone being bullied or treated unkindly today, speak up for them. Courage is choosing to do right.',
    'schoolLife', 'honorSystem', 100, 0, 0,
    10, 2, false, 'once',
    '🛡️',
    '"Injustice anywhere is a threat to justice everywhere." — Martin Luther King Jr.',
    'Justice', false, 50
),

-- 14
(
    'Share Your Lunch or Snack',
    'Today, share part of your lunch or snack with someone who needs it or would enjoy it. Give freely!',
    'schoolLife', 'honorSystem', 70, 0, 0,
    15, 1, true, 'weekly',
    '🍎',
    '"Give, and it will be given to you." — Luke 6:38',
    'Generosity', false, 60
);

-- ============================================================
-- COMMUNITY (6 quests)
-- ============================================================

INSERT INTO public.real_world_quests
    (title, description, category, verification, holy_points_reward, faith_coins_reward, grace_reward,
     estimated_minutes, age_group_min, is_repeatable, repeat_frequency,
     icon_emoji, inspirational_quote, related_virtue, is_custom, sort_order)
VALUES

-- 15
(
    'Visit Grandparents or Elderly Relatives',
    'Spend time with your grandparents or elderly relatives. Listen to their stories, bring them a treat, or simply sit and talk.',
    'community', 'photoScan', 150, 0, 0,
    90, 1, true, 'weekly',
    '👴',
    '"Rise in the presence of the aged, show respect for the elderly." — Leviticus 19:32',
    'Love', false, 10
),

-- 16
(
    'Donate Old Toys or Clothes',
    'Find toys, clothes, or books you no longer need and donate them to someone who could use them. Generosity makes room for grace.',
    'community', 'photoScan', 200, 0, 0,
    60, 1, false, 'once',
    '📦',
    '"Whoever has two tunics should share with the one who has none." — Luke 3:11',
    'Generosity', false, 20
),

-- 17
(
    'Help a Neighbor',
    'Do something helpful for a neighbor today — carry groceries, rake leaves, shovel snow, or just check in on them.',
    'community', 'parentValidate', 100, 0, 0,
    30, 1, true, 'weekly',
    '🏡',
    '"Love your neighbor as yourself." — Mark 12:31',
    'Service', false, 30
),

-- 18
(
    'Pick Up Litter in Your Neighborhood',
    'Take a bag and spend 20 minutes picking up litter near your home or school. We are called to be stewards of creation!',
    'community', 'photoScan', 80, 0, 0,
    20, 1, true, 'monthly',
    '🌍',
    '"The Earth is the Lord''s, and everything in it." — Psalm 24:1',
    'Stewardship', false, 40
),

-- 19
(
    'Write a Thank-You Note to a Teacher',
    'Write a real, handwritten note thanking a teacher for something they''ve done for you. Mail it or deliver it in person.',
    'community', 'honorSystem', 90, 0, 0,
    20, 2, false, 'once',
    '💌',
    '"Give thanks in all circumstances." — 1 Thessalonians 5:18',
    'Gratitude', false, 50
),

-- 20
(
    'Volunteer at a Church Event',
    'Sign up to help at a parish event, church cleanup, or faith community activity. Serve your Church family!',
    'community', 'churchCheckin', 200, 0, 0,
    120, 2, true, 'monthly',
    '⛪',
    '"Each one should use whatever gift he has received to serve others." — 1 Peter 4:10',
    'Service', false, 60
);

-- ============================================================
-- DIGITAL FAST (5 quests)
-- ============================================================

INSERT INTO public.real_world_quests
    (title, description, category, verification, holy_points_reward, faith_coins_reward, grace_reward,
     estimated_minutes, age_group_min, is_repeatable, repeat_frequency,
     icon_emoji, inspirational_quote, related_virtue, is_custom, sort_order)
VALUES

-- 21
(
    'Gadget-Free Meal',
    'Enjoy a full meal with your family without any screens — no phones, tablets, or TV during dinner. Be fully present!',
    'digitalFast', 'appTimer', 0, 50, 0,
    30, 1, true, 'daily',
    '🍽️',
    '"Be still, and know that I am God." — Psalm 46:10',
    'Temperance', false, 10
),

-- 22
(
    '2-Hour Screen Break',
    'Go two full hours without any screen time. Go outside, draw, pray, read, or talk to your family. Rediscover the non-digital world!',
    'digitalFast', 'appTimer', 100, 0, 0,
    120, 1, true, 'daily',
    '🌿',
    '"Silence is the language of God; everything else is a poor translation." — Rumi',
    'Temperance', false, 20
),

-- 23
(
    'Morning Prayer Before Social Media',
    'Tomorrow morning, open Kingdom Come and say your morning prayer BEFORE checking any social media or messages.',
    'digitalFast', 'honorSystem', 40, 0, 0,
    10, 2, true, 'daily',
    '🌅',
    '"In the morning, O Lord, You hear my voice; in the morning I lay my requests before You." — Psalm 5:3',
    'Piety', false, 30
),

-- 24
(
    'Screen-Free Bedtime Hour',
    'For one full hour before you go to sleep, put away all screens. Pray, journal, or read a physical book instead.',
    'digitalFast', 'parentValidate', 30, 0, 0,
    60, 1, true, 'daily',
    '🌙',
    '"Rest in the Lord and wait patiently for Him." — Psalm 37:7',
    'Temperance', false, 40
),

-- 25
(
    'Digital Sabbath — Full Day Challenge',
    'For one full day (Sundays are perfect!), abstain from all entertainment screens and social media. Spend the day with God, family, and nature.',
    'digitalFast', 'parentValidate', 500, 0, 50,
    480, 2, true, 'weekly',
    '✝️',
    '"Remember the Sabbath day by keeping it holy." — Exodus 20:8',
    'Temperance', false, 50
);

-- ============================================================
-- CHARACTER BUILDING (8 quests)
-- ============================================================

INSERT INTO public.real_world_quests
    (title, description, category, verification, holy_points_reward, faith_coins_reward, grace_reward,
     estimated_minutes, age_group_min, is_repeatable, repeat_frequency,
     icon_emoji, inspirational_quote, related_virtue, is_custom, sort_order)
VALUES

-- 26
(
    'Write 3 Things You''re Grateful For',
    'Take a journal or piece of paper and write down three things you are truly grateful for today. Be specific and heartfelt.',
    'characterBuilding', 'honorSystem', 40, 0, 0,
    10, 1, true, 'daily',
    '📔',
    '"Gratitude is not only the greatest of virtues, but the parent of all others." — Cicero',
    'Gratitude', false, 10
),

-- 27
(
    'Apologize to Someone You Hurt',
    'Think of someone you may have hurt — through words or actions. Go to them and sincerely apologize. True courage takes humility.',
    'characterBuilding', 'honorSystem', 100, 0, 0,
    15, 1, false, 'once',
    '💔',
    '"If you are offering your gift at the altar and there remember that your brother has something against you... first be reconciled to your brother." — Matthew 5:23-24',
    'Humility', false, 20
),

-- 28
(
    'Forgive Someone Who Hurt You',
    'Is there someone you are still angry with? Today, in your heart, choose to forgive them. You don''t have to feel it — just choose it.',
    'characterBuilding', 'honorSystem', 120, 0, 10,
    15, 2, false, 'once',
    '🕊️',
    '"Forgive, and you will be forgiven." — Luke 6:37',
    'Forgiveness', false, 30
),

-- 29
(
    'Do Something Kind Without Telling Anyone',
    'Do a kind deed today — but don''t tell anyone about it. Not even your parents. This is between you and God.',
    'characterBuilding', 'honorSystem', 80, 0, 0,
    20, 1, true, 'weekly',
    '🌸',
    '"When you do a charitable deed, do not let your left hand know what your right hand is doing." — Matthew 6:3',
    'Humility', false, 40
),

-- 30
(
    'Control Your Anger — Count to 10 Before Reacting',
    'Today, whenever you feel frustrated or angry, pause and count slowly to 10 before reacting. Practice this at least once today.',
    'characterBuilding', 'honorSystem', 50, 0, 0,
    5, 1, true, 'daily',
    '😤',
    '"Be quick to listen, slow to speak and slow to become angry." — James 1:19',
    'Patience', false, 50
),

-- 31
(
    'Compliment 3 People Sincerely',
    'Give three genuine, heartfelt compliments today. Not empty flattery — find something real and good to say about three people.',
    'characterBuilding', 'honorSystem', 60, 0, 0,
    15, 1, true, 'weekly',
    '💛',
    '"Therefore encourage one another and build each other up." — 1 Thessalonians 5:11',
    'Charity', false, 60
),

-- 32
(
    'Pray for Someone You Find Difficult',
    'Think of someone who is hard to love or get along with. Spend 3 minutes sincerely praying for their wellbeing and happiness.',
    'characterBuilding', 'honorSystem', 70, 0, 10,
    10, 1, true, 'weekly',
    '🙏',
    '"Pray for those who mistreat you." — Luke 6:28',
    'Love', false, 70
),

-- 33
(
    'Keep a Promise You Made',
    'Did you make a promise recently? Today, make sure you follow through on it — even if it''s inconvenient. Your word matters.',
    'characterBuilding', 'parentValidate', 90, 0, 0,
    30, 2, false, 'once',
    '🤞',
    '"Simply let your Yes be Yes, and your No be No." — Matthew 5:37',
    'Integrity', false, 80
);

-- ============================================================
-- FAMILY (4 quests)
-- ============================================================

INSERT INTO public.real_world_quests
    (title, description, category, verification, holy_points_reward, faith_coins_reward, grace_reward,
     estimated_minutes, age_group_min, is_repeatable, repeat_frequency,
     icon_emoji, inspirational_quote, related_virtue, is_custom, sort_order)
VALUES

-- 34
(
    'Family Dinner Without Gadgets',
    'Have dinner with your family tonight with zero screens at the table — no phones, no tablets, no TV in the background. Just family.',
    'family', 'parentValidate', 100, 0, 0,
    45, 1, true, 'daily',
    '👨‍👩‍👧',
    '"The family that prays together, stays together." — Venerable Patrick Peyton',
    'Family', false, 10
),

-- 35
(
    'Play a Board Game with Family',
    'Suggest a board game, card game, or any non-screen game and play it together with your family tonight.',
    'family', 'photoScan', 80, 0, 0,
    60, 1, true, 'weekly',
    '🎲',
    '"Joy is the infallible sign of the presence of God." — Pierre Teilhard de Chardin',
    'Joy', false, 20
),

-- 36
(
    'Tell Each Family Member One Thing You Love About Them',
    'Look each family member in the eyes today and tell them one specific thing you genuinely love or appreciate about them.',
    'family', 'honorSystem', 90, 0, 0,
    15, 1, true, 'weekly',
    '❤️',
    '"Love one another as I have loved you." — John 15:12',
    'Love', false, 30
),

-- 37
(
    'Pray the Rosary Together as a Family',
    'Lead or participate in praying the Rosary with your whole family. All five decades, or even one decade, counts!',
    'family', 'parentValidate', 200, 0, 30,
    30, 1, true, 'weekly',
    '📿',
    '"The Rosary is the most excellent form of prayer and the most efficacious means of attaining eternal life." — Pope Leo XIII',
    'Piety', false, 40
);

-- ============================================================
-- CHURCH (3 quests)
-- ============================================================

INSERT INTO public.real_world_quests
    (title, description, category, verification, holy_points_reward, faith_coins_reward, grace_reward,
     estimated_minutes, age_group_min, is_repeatable, repeat_frequency,
     icon_emoji, inspirational_quote, related_virtue, is_custom, sort_order)
VALUES

-- 38
(
    'Attend Sunday Mass',
    'Attend Sunday Mass at your parish this week. Participate fully — sing, respond, and receive the Eucharist with an open heart.',
    'church', 'parentValidate', 200, 0, 20,
    60, 1, true, 'weekly',
    '⛪',
    '"I was glad when they said to me, ''Let us go to the house of the Lord.''" — Psalm 122:1',
    'Piety', false, 10
),

-- 39
(
    'Participate in Parish Youth Group',
    'Attend a meeting, activity, or event organized by your parish youth group. Grow in faith together with other young Catholics!',
    'church', 'parentValidate', 150, 0, 0,
    90, 2, true, 'weekly',
    '👥',
    '"Where two or three gather in my name, there am I with them." — Matthew 18:20',
    'Community', false, 20
),

-- 40
(
    'Help with Church Decoration or Event',
    'Volunteer to help set up, decorate, or clean up for a church event, Mass, or parish activity. Serve the house of God!',
    'church', 'photoScan', 175, 0, 0,
    120, 2, true, 'monthly',
    '🌺',
    '"Zeal for your house consumes me." — Psalm 69:9',
    'Service', false, 30
);
