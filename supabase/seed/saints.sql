-- ============================================================
-- Seed: Saints (20 saints with full data)
-- ============================================================
-- Abilities JSON schema reference:
--   passive: { type, resource, value, applies_to }
--   active:  { type, resource, value, duration_hours, cooldown_hours }
-- ============================================================

INSERT INTO public.saints (
    slug, display_name, short_bio, full_bio,
    feast_day, feast_day_month, feast_day_day,
    era, patronage, rarity,
    unlock_cost_holy_points, required_monastery_level,
    abilities, avatar_url
) VALUES

-- ── 1. St. Francis of Assisi ────────────────────────────────
(
    'francis-of-assisi',
    'St. Francis of Assisi',
    'Founder of the Franciscan order, patron of animals and the environment. Known for radical poverty and joy.',
    'Giovanni di Pietro di Bernardone was born in 1181 in Assisi, Italy. After a conversion experience, he renounced his wealthy family and founded the Order of Friars Minor. He received the stigmata in 1224, becoming the first recorded person to bear the wounds of Christ. He died in 1226 and was canonized in 1228.',
    'October 4', 10, 4,
    'Medieval',
    ARRAY['animals', 'environment', 'Italy', 'merchants', 'Franciscans'],
    'common',
    500, 1,
    '{
      "passive": {"type": "multiplier", "resource": "holy_points", "value": 1.15, "applies_to": "all"},
      "active":  {"type": "multiplier", "resource": "holy_points", "value": 1.5, "duration_hours": 4, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 2. St. Teresa of Ávila ──────────────────────────────────
(
    'teresa-of-avila',
    'St. Teresa of Ávila',
    'Doctor of the Church and mystic who reformed the Carmelite order. Author of "The Interior Castle."',
    'Teresa Sánchez de Cepeda Dávila y Ahumada was born in 1515 in Ávila, Spain. She experienced profound mystical visions and worked tirelessly to reform the Carmelite order. Her spiritual writings, including "The Interior Castle" and "The Way of Perfection," remain masterpieces of Christian mysticism. She was declared a Doctor of the Church in 1970.',
    'October 15', 10, 15,
    'Renaissance',
    ARRAY['Spain', 'headache sufferers', 'chess players', 'lacemakers'],
    'rare',
    1200, 3,
    '{
      "passive": {"type": "multiplier", "resource": "xp", "value": 1.25, "applies_to": "prayer"},
      "active":  {"type": "multiplier", "resource": "xp",  "value": 2.0, "duration_hours": 6, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 3. St. Dominic ──────────────────────────────────────────
(
    'dominic-de-guzman',
    'St. Dominic',
    'Founder of the Order of Preachers (Dominicans). Champion of the Rosary and defender of the faith.',
    'Domingo Félix de Guzmán was born around 1170 in Caleruega, Spain. He founded the Order of Preachers to combat heresy through preaching and education. He is credited with popularizing the Rosary as a powerful prayer tool. Known for his great charity and zeal for souls, he died in 1221 and was canonized in 1234.',
    'August 8', 8, 8,
    'Medieval',
    ARRAY['Dominican Republic', 'astronomers', 'falsely accused', 'preachers'],
    'uncommon',
    750, 2,
    '{
      "passive": {"type": "multiplier", "resource": "holy_points", "value": 1.3, "applies_to": "rosary"},
      "active":  {"type": "bonus",      "resource": "faith_coins", "value": 25,  "duration_hours": 8, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 4. St. Joan of Arc ──────────────────────────────────────
(
    'joan-of-arc',
    'St. Joan of Arc',
    'The Maid of Orléans. Led France to victory guided by heavenly voices. Martyr at age 19.',
    'Jeanne d''Arc was born around 1412 in Domrémy, France. At age 13, she began hearing voices she identified as St. Michael, St. Catherine, and St. Margaret. Following their guidance, she led French armies to crucial victories in the Hundred Years'' War. Captured by the English, she was tried for heresy and burned at the stake in 1431 at age 19. She was canonized in 1920.',
    'May 30', 5, 30,
    'Medieval',
    ARRAY['France', 'soldiers', 'prisoners', 'martyrs', 'people ridiculed for piety'],
    'epic',
    2500, 5,
    '{
      "passive": {"type": "multiplier", "resource": "holy_points", "value": 1.2, "applies_to": "good_deed"},
      "active":  {"type": "shield",     "resource": "streak",      "value": 1,   "duration_hours": 24, "cooldown_hours": 72, "description": "Protects your streak from breaking once"}
    }'::JSONB,
    NULL
),

-- ── 5. St. Thomas Aquinas ───────────────────────────────────
(
    'thomas-aquinas',
    'St. Thomas Aquinas',
    'Doctor Angelicus. Greatest theologian of the Church. Author of the Summa Theologiae.',
    'Thomas Aquinas was born around 1225 in Roccasecca, Italy. Against his family''s wishes, he joined the Dominican order and studied under St. Albert the Great. His masterwork, the Summa Theologiae, synthesized Christian theology with Aristotelian philosophy and remains foundational to Catholic thought. He died in 1274 and was declared a Doctor of the Church in 1567.',
    'January 28', 1, 28,
    'Medieval',
    ARRAY['students', 'scholars', 'universities', 'theologians', 'book sellers'],
    'rare',
    1500, 3,
    '{
      "passive": {"type": "multiplier", "resource": "xp", "value": 1.4, "applies_to": "quiz"},
      "active":  {"type": "multiplier", "resource": "xp", "value": 2.5, "duration_hours": 4, "cooldown_hours": 24, "description": "Double quiz XP for 4 hours"}
    }'::JSONB,
    NULL
),

-- ── 6. St. Clare of Assisi ──────────────────────────────────
(
    'clare-of-assisi',
    'St. Clare of Assisi',
    'Founder of the Poor Clares. Devoted friend of St. Francis. Patron of television and good weather.',
    'Chiara Offreduccio was born in 1194 in Assisi, Italy. Inspired by St. Francis''s preaching, she ran away from home at 18 to embrace religious life. Francis helped her establish the Order of Poor Ladies (Poor Clares). Known for her miracles, including repelling an enemy army with the Blessed Sacrament. She died in 1253 and was canonized in 1255.',
    'August 11', 8, 11,
    'Medieval',
    ARRAY['television', 'eye diseases', 'telegraphs', 'embroiderers', 'laundry workers'],
    'uncommon',
    700, 2,
    '{
      "passive": {"type": "multiplier", "resource": "grace", "value": 1.25, "applies_to": "all"},
      "active":  {"type": "bonus",      "resource": "grace", "value": 50,   "duration_hours": 6, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 7. St. John Bosco ───────────────────────────────────────
(
    'john-bosco',
    'St. John Bosco',
    'Don Bosco. Founded the Salesians. Devoted his life to educating poor and at-risk youth.',
    'Giovanni Melchiorre Bosco was born in 1815 in Becchi, Italy. Growing up in poverty, he understood the struggles of poor children. He founded the Salesian Society to care for orphaned and at-risk youth, using his "Preventive System" of education based on reason, religion, and kindness. He served thousands of boys in Turin and established schools, workshops, and oratories. He died in 1888.',
    'January 31', 1, 31,
    'Modern',
    ARRAY['youth', 'editors', 'publishers', 'magicians', 'apprentices'],
    'common',
    400, 1,
    '{
      "passive": {"type": "multiplier", "resource": "xp", "value": 1.2, "applies_to": "all"},
      "active":  {"type": "multiplier", "resource": "xp", "value": 1.75, "duration_hours": 8, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 8. St. Thérèse of Lisieux ───────────────────────────────
(
    'therese-of-lisieux',
    'St. Thérèse of Lisieux',
    'The Little Flower. Doctor of the Church. Her "Little Way" of spiritual childhood is beloved worldwide.',
    'Marie-Françoise-Thérèse Martin was born in 1873 in Alençon, France. She entered the Carmelite convent at 15 and died of tuberculosis at 24. Her spiritual autobiography, "Story of a Soul," revealed her "Little Way" — a path to holiness through small, hidden acts of love. She was declared a Doctor of the Church in 1997, one of only four women to hold this title.',
    'October 1', 10, 1,
    'Modern',
    ARRAY['missions', 'France', 'florists', 'pilots', 'AIDS sufferers'],
    'rare',
    1000, 2,
    '{
      "passive": {"type": "multiplier", "resource": "faith_coins", "value": 1.2, "applies_to": "all"},
      "active":  {"type": "double_rewards", "resource": "all",    "value": 2.0, "duration_hours": 3, "cooldown_hours": 24, "description": "All rewards doubled for 3 hours"}
    }'::JSONB,
    NULL
),

-- ── 9. St. Patrick ──────────────────────────────────────────
(
    'patrick-of-ireland',
    'St. Patrick',
    'Apostle of Ireland. Former slave who returned to evangelize Ireland. Drove the snakes from Ireland.',
    'Patricius was born around 387 AD in Roman Britain. At 16, he was kidnapped by Irish pirates and enslaved for six years. After escaping, he became a priest and eventually bishop, then returned to Ireland as a missionary. He used the shamrock to explain the Trinity and converted much of Ireland to Christianity. He died around 461 AD.',
    'March 17', 3, 17,
    'Early Church',
    ARRAY['Ireland', 'engineers', 'snakes', 'Nigeria', 'paralegals'],
    'uncommon',
    600, 1,
    '{
      "passive": {"type": "multiplier", "resource": "holy_points", "value": 1.2, "applies_to": "all"},
      "active":  {"type": "bonus",      "resource": "faith_coins", "value": 40,  "duration_hours": 4, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 10. St. Ignatius of Loyola ──────────────────────────────
(
    'ignatius-of-loyola',
    'St. Ignatius of Loyola',
    'Founder of the Jesuits. Author of the Spiritual Exercises. Soldier who became a soldier of Christ.',
    'Iñigo López de Loyola was born in 1491 in the Basque Country, Spain. A soldier wounded at the Battle of Pamplona, his long recovery prompted a spiritual conversion. He wrote the Spiritual Exercises, a systematic program of prayer and discernment, and founded the Society of Jesus (Jesuits) in 1540. The Jesuits became one of the most influential orders in the Church.',
    'July 31', 7, 31,
    'Renaissance',
    ARRAY['Jesuits', 'soldiers', 'spiritual directors', 'retreats'],
    'rare',
    1300, 3,
    '{
      "passive": {"type": "multiplier", "resource": "xp", "value": 1.25, "applies_to": "all"},
      "active":  {"type": "multiplier", "resource": "holy_points", "value": 1.8, "duration_hours": 6, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 11. St. Catherine of Siena ──────────────────────────────
(
    'catherine-of-siena',
    'St. Catherine of Siena',
    'Doctor of the Church. Mystic and reformer who convinced the Pope to return to Rome.',
    'Caterina di Jacopo di Benincasa was born in 1347 in Siena, Italy. A Dominican tertiary, she cared for the sick and poor while experiencing profound mystical visions. She boldly corresponded with kings and popes, successfully urging Pope Gregory XI to return the papacy from Avignon to Rome. She received the stigmata and was declared a Doctor of the Church in 1970.',
    'April 29', 4, 29,
    'Medieval',
    ARRAY['Italy', 'nurses', 'fire prevention', 'sexual temptation'],
    'epic',
    2000, 4,
    '{
      "passive": {"type": "multiplier", "resource": "grace", "value": 1.35, "applies_to": "prayer"},
      "active":  {"type": "bonus",      "resource": "blessings", "value": 15, "duration_hours": 8, "cooldown_hours": 48}
    }'::JSONB,
    NULL
),

-- ── 12. St. Peter the Apostle ───────────────────────────────
(
    'peter-apostle',
    'St. Peter',
    'Prince of the Apostles. First Pope. Fisherman called by Jesus to be a fisher of men.',
    'Simon bar Jonah was a fisherman from Bethsaida called by Jesus to be one of the Twelve Apostles. Jesus renamed him Peter ("rock") and declared he would build his Church upon him. Despite denying Christ three times before the crucifixion, Peter repented and became the bold leader of the early Church. He was martyred by crucifixion in Rome around 64-68 AD, requesting to be crucified upside down.',
    'June 29', 6, 29,
    'Early Church',
    ARRAY['popes', 'fishermen', 'net makers', 'shipbuilders', 'locksmiths'],
    'epic',
    2200, 4,
    '{
      "passive": {"type": "multiplier", "resource": "holy_points", "value": 1.3, "applies_to": "mass_attendance"},
      "active":  {"type": "multiplier", "resource": "holy_points", "value": 2.0, "duration_hours": 4, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 13. St. Paul the Apostle ────────────────────────────────
(
    'paul-apostle',
    'St. Paul',
    'Apostle to the Gentiles. Persecutor of Christians transformed into the Church''s greatest missionary.',
    'Saul of Tarsus was a Pharisee who zealously persecuted early Christians. Dramatically converted by a vision of the risen Christ on the road to Damascus, he became Paul, the greatest missionary of the early Church. His fourteen epistles form a large portion of the New Testament. He traveled throughout the Mediterranean world establishing churches before being martyred in Rome around 64-68 AD.',
    'June 29', 6, 29,
    'Early Church',
    ARRAY['missionaries', 'writers', 'theologians', 'tent makers', 'Greece'],
    'epic',
    2200, 4,
    '{
      "passive": {"type": "multiplier", "resource": "xp", "value": 1.3, "applies_to": "bible_reading"},
      "active":  {"type": "multiplier", "resource": "xp", "value": 2.5, "duration_hours": 4, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 14. Blessed Carlo Acutis ────────────────────────────────
(
    'carlo-acutis',
    'Blessed Carlo Acutis',
    'Modern teen who used the internet to spread devotion to the Eucharist. "God''s Influencer."',
    'Carlo Acutis was born on May 3, 1991 in London and raised in Milan, Italy. A gifted computer programmer, he used his skills to catalog Eucharistic miracles worldwide. He called the Eucharist "my highway to heaven" and received it daily. Diagnosed with leukemia at 15, he offered his suffering for the Pope and the Church. He died on October 12, 2006 and was beatified in 2020.',
    'October 12', 10, 12,
    'Contemporary',
    ARRAY['internet users', 'computer programmers', 'youth'],
    'legendary',
    5000, 7,
    '{
      "passive": {"type": "multiplier", "resource": "faith_coins", "value": 1.5, "applies_to": "all"},
      "active":  {"type": "double_rewards", "resource": "all", "value": 2.0, "duration_hours": 12, "cooldown_hours": 48, "description": "Doubles all rewards for 12 hours"}
    }'::JSONB,
    NULL
),

-- ── 15. St. Nicholas ────────────────────────────────────────
(
    'nicholas-of-myra',
    'St. Nicholas',
    'Bishop of Myra. Legendary gift-giver. Patron of children, sailors, and the poor.',
    'Nicholas was born around 280 AD in Patara, Lycia (modern Turkey). Inheriting great wealth, he used it to help the poor and needy, famously providing dowries for three impoverished sisters by tossing bags of gold through their window at night. As Bishop of Myra, he was known for miracles and generosity. His legend inspired the modern figure of Santa Claus. He died around 343 AD.',
    'December 6', 12, 6,
    'Early Church',
    ARRAY['children', 'sailors', 'merchants', 'the poor', 'Russia', 'Greece', 'bakers'],
    'uncommon',
    800, 2,
    '{
      "passive": {"type": "bonus", "resource": "faith_coins", "value": 5, "applies_to": "daily_login"},
      "active":  {"type": "bonus", "resource": "faith_coins", "value": 100, "duration_hours": 24, "cooldown_hours": 48, "description": "Grants 100 bonus Faith Coins"}
    }'::JSONB,
    NULL
),

-- ── 16. St. Monica ──────────────────────────────────────────
(
    'monica-of-hippo',
    'St. Monica',
    'Mother of St. Augustine. Spent decades in prayer for the conversion of her wayward son.',
    'Monica was born around 331 AD in Tagaste, North Africa (modern Algeria). She endured a difficult marriage but converted her husband Patricius shortly before his death. Her son Augustine lived a dissolute life for years, but Monica never ceased praying for his conversion. Her tears and prayers were rewarded when Augustine converted at age 32. She died in 387 AD shortly after witnessing her son''s baptism.',
    'August 27', 8, 27,
    'Early Church',
    ARRAY['mothers', 'wives', 'abuse victims', 'alcoholics'],
    'common',
    350, 1,
    '{
      "passive": {"type": "multiplier", "resource": "grace", "value": 1.2, "applies_to": "prayer"},
      "active":  {"type": "bonus",      "resource": "grace", "value": 30,  "duration_hours": 8, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 17. St. Augustine of Hippo ──────────────────────────────
(
    'augustine-of-hippo',
    'St. Augustine of Hippo',
    'Doctor of Grace. One of the greatest theologians in history. "Our heart is restless until it rests in Thee."',
    'Aurelius Augustinus Hipponensis was born in 354 AD in Tagaste, North Africa. After a youth of intellectual searching and moral struggles (famously praying "Lord, make me chaste, but not yet"), he was baptized by St. Ambrose in 387 AD. As Bishop of Hippo, he wrote the Confessions, City of God, and hundreds of other works that have shaped Western Christianity for 1,600 years.',
    'August 28', 8, 28,
    'Early Church',
    ARRAY['theologians', 'brewers', 'printers', 'sore eyes', 'North Africa'],
    'rare',
    1100, 2,
    '{
      "passive": {"type": "multiplier", "resource": "xp", "value": 1.3, "applies_to": "all"},
      "active":  {"type": "multiplier", "resource": "xp", "value": 2.0, "duration_hours": 6, "cooldown_hours": 24}
    }'::JSONB,
    NULL
),

-- ── 18. St. Maria Goretti ───────────────────────────────────
(
    'maria-goretti',
    'St. Maria Goretti',
    'Martyr of purity. At age 11, she chose death over dishonor. She forgave her attacker from her deathbed.',
    'Maria Teresa Goretti was born in 1890 in Corinaldo, Italy. The daughter of a poor farming family, she grew up devout and cheerful. At age 11, she was attacked by a neighbor and fatally stabbed when she resisted his advances. On her deathbed, she forgave him, saying she wanted him to be with her in heaven. Her attacker later repented and attended her canonization in 1950.',
    'July 6', 7, 6,
    'Modern',
    ARRAY['youth', 'girls', 'rape victims', 'purity', 'crime victims'],
    'uncommon',
    600, 1,
    '{
      "passive": {"type": "multiplier", "resource": "holy_points", "value": 1.15, "applies_to": "good_deed"},
      "active":  {"type": "shield",     "resource": "streak",      "value": 1,    "duration_hours": 24, "cooldown_hours": 48, "description": "Streak shield: protects from breaking"}
    }'::JSONB,
    NULL
),

-- ── 19. St. Joseph ──────────────────────────────────────────
(
    'joseph-of-nazareth',
    'St. Joseph',
    'Foster father of Jesus. Patron of the Universal Church, workers, and families.',
    'Joseph was a carpenter from Nazareth in Galilee, of the house of David. He was betrothed to Mary when he discovered her pregnancy. An angel appeared to him in a dream, reassuring him that her child was conceived by the Holy Spirit. He protected and provided for the Holy Family, fleeing to Egypt to escape Herod. He is the patron saint of the Universal Church, workers, and a happy death.',
    'March 19', 3, 19,
    'Biblical',
    ARRAY['fathers', 'workers', 'carpenters', 'engineers', 'dying people', 'Universal Church'],
    'epic',
    2800, 5,
    '{
      "passive": {"type": "multiplier", "resource": "holy_points", "value": 1.25, "applies_to": "all"},
      "active":  {"type": "multiplier", "resource": "all", "value": 1.5, "duration_hours": 8, "cooldown_hours": 24, "description": "All resources +50% for 8 hours"}
    }'::JSONB,
    NULL
),

-- ── 20. Blessed Virgin Mary ─────────────────────────────────
(
    'blessed-virgin-mary',
    'Blessed Virgin Mary',
    'Mother of God. Queen of Heaven. The greatest of all the saints, ever-virgin, conceived without sin.',
    'Mary of Nazareth is the Theotokos — the God-Bearer — the Mother of Jesus Christ, true God and true man. Conceived without original sin (the Immaculate Conception), she said her fiat ("Let it be done to me") at the Annunciation. She stood at the foot of the Cross and was present at Pentecost. She was assumed body and soul into heaven (the Assumption). She continues to intercede powerfully for all her children.',
    'August 15', 8, 15,
    'Biblical',
    ARRAY['mothers', 'virgins', 'all humanity', 'United States', 'France', 'Korea'],
    'legendary',
    10000, 10,
    '{
      "passive": {"type": "multiplier", "resource": "all", "value": 1.5, "applies_to": "all", "description": "All resources +50% passively"},
      "active":  {"type": "double_rewards", "resource": "all", "value": 3.0, "duration_hours": 12, "cooldown_hours": 72, "description": "Triple all rewards for 12 hours"}
    }'::JSONB,
    NULL
);
