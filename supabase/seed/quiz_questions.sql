-- ============================================================
-- Seed: Quizzes and Quiz Questions (5 quizzes, 5-8 questions each)
-- ============================================================
-- NOTE: questions_correct references correct_index (0-based)
-- options array must have exactly 4 elements
-- ============================================================

-- ============================================================
-- QUIZ 1: Sacraments Basics (difficulty 1, age 1)
-- ============================================================

WITH quiz1 AS (
    INSERT INTO public.quizzes (
        title, description, category, difficulty, min_age_group,
        time_limit_seconds,
        holy_points_reward, faith_coins_reward, xp_reward,
        passing_score, icon_name, is_active, sort_order
    ) VALUES (
        'Sacraments Basics',
        'Test your knowledge of the Seven Sacraments of the Catholic Church.',
        'sacraments', 1, 1,
        300,  -- 5 minutes
        30, 5, 20,
        70, 'quiz_sacraments', true, 1
    )
    RETURNING id
)
INSERT INTO public.quiz_questions (quiz_id, question_text, options, correct_index, explanation, scripture_ref, sort_order)
SELECT q.id, v.question_text, v.options, v.correct_index, v.explanation, v.scripture_ref, v.sort_order
FROM quiz1 q,
(VALUES
    (
        'How many Sacraments are there in the Catholic Church?',
        ARRAY['Five', 'Six', 'Seven', 'Ten'],
        2,
        'The Catholic Church has Seven Sacraments: Baptism, Confirmation, Eucharist, Penance, Anointing of the Sick, Holy Orders, and Matrimony.',
        NULL,
        1
    ),
    (
        'Which Sacrament removes Original Sin and makes us children of God?',
        ARRAY['Confirmation', 'Baptism', 'Eucharist', 'Penance'],
        1,
        'Baptism is the first Sacrament and the gateway to all others. It removes Original Sin, makes us children of God, and members of the Church.',
        'John 3:5',
        2
    ),
    (
        'In which Sacrament do we receive the Body, Blood, Soul, and Divinity of Jesus Christ?',
        ARRAY['Baptism', 'Confirmation', 'The Holy Eucharist', 'Anointing of the Sick'],
        2,
        'The Eucharist is the "source and summit" of Catholic life. At Mass, the bread and wine truly become Jesus Christ — Body, Blood, Soul, and Divinity.',
        'John 6:51',
        3
    ),
    (
        'What is another name for the Sacrament of Penance?',
        ARRAY['Matrimony', 'Confirmation', 'Holy Orders', 'Reconciliation'],
        3,
        'The Sacrament of Penance is also called Reconciliation or Confession. In it, God forgives our sins through a priest.',
        'John 20:23',
        4
    ),
    (
        'Which Sacrament strengthens our faith and makes us "soldiers of Christ"?',
        ARRAY['Confirmation', 'Holy Orders', 'Baptism', 'Matrimony'],
        0,
        'Confirmation strengthens the gifts of the Holy Spirit given at Baptism and makes us more complete Christians, ready to witness and defend the faith.',
        'Acts 2:1-4',
        5
    ),
    (
        'The Sacrament of Holy Orders has how many degrees?',
        ARRAY['One', 'Two', 'Three', 'Four'],
        2,
        'Holy Orders has three degrees: Diaconate (deacon), Presbyterate (priest), and Episcopate (bishop). Each degree carries a different form of sacred ministry.',
        NULL,
        6
    ),
    (
        'Which Sacraments can only be received once?',
        ARRAY['Eucharist and Penance', 'Baptism, Confirmation, and Holy Orders', 'Matrimony and Anointing', 'All seven Sacraments'],
        1,
        'Baptism, Confirmation, and Holy Orders each leave a permanent spiritual mark (character) on the soul, so they can only be received once.',
        NULL,
        7
    )
) AS v(question_text, options, correct_index, explanation, scripture_ref, sort_order);


-- ============================================================
-- QUIZ 2: Saints of the Church (difficulty 1, age 1)
-- ============================================================

WITH quiz2 AS (
    INSERT INTO public.quizzes (
        title, description, category, difficulty, min_age_group,
        time_limit_seconds,
        holy_points_reward, faith_coins_reward, xp_reward,
        passing_score, icon_name, is_active, sort_order
    ) VALUES (
        'Saints of the Church',
        'How well do you know the great men and women who followed Christ?',
        'saints', 1, 1,
        300,
        30, 5, 20,
        70, 'quiz_saints', true, 2
    )
    RETURNING id
)
INSERT INTO public.quiz_questions (quiz_id, question_text, options, correct_index, explanation, scripture_ref, sort_order)
SELECT q.id, v.question_text, v.options, v.correct_index, v.explanation, v.scripture_ref, v.sort_order
FROM quiz2 q,
(VALUES
    (
        'St. Francis of Assisi is patron saint of what?',
        ARRAY['Libraries', 'The environment and animals', 'Sailors', 'Doctors'],
        1,
        'St. Francis is the patron of animals, the environment, and ecology. He famously preached to the birds and called all creatures his brothers and sisters.',
        NULL,
        1
    ),
    (
        'Who was St. Thérèse of Lisieux known as?',
        ARRAY['The Rose of Lima', 'The Little Flower', 'The Seraphic Doctor', 'The Apostle of the Gentiles'],
        1,
        'St. Thérèse is called "The Little Flower" because she compared herself to a little wildflower, not a great rose. She taught the "Little Way" of holiness through small daily actions.',
        NULL,
        2
    ),
    (
        'Blessed Carlo Acutis is known as "God''s Influencer" because:',
        ARRAY['He was a famous preacher', 'He used the internet to document Eucharistic miracles', 'He wrote many books', 'He was a singer'],
        1,
        'Carlo Acutis was a computer whiz who created a website cataloging Eucharistic miracles worldwide. He used modern technology for evangelization before dying of leukemia at age 15.',
        NULL,
        3
    ),
    (
        'What is St. Patrick best known for bringing to Ireland?',
        ARRAY['The Holy Grail', 'Christianity', 'The Bible''s first translation', 'The printing press'],
        1,
        'St. Patrick, a former slave, returned to Ireland as a missionary and converted the Irish people to Christianity in the 5th century.',
        NULL,
        4
    ),
    (
        'St. Thomas Aquinas is called the "Angelic Doctor." What does "Doctor" mean in Church titles?',
        ARRAY['Medical doctor', 'PhD holder', 'An outstanding teacher of the faith', 'A Church administrator'],
        2,
        '"Doctor of the Church" is a title given by the Pope to saints whose writings have been especially important for teaching and understanding the faith.',
        NULL,
        5
    ),
    (
        'Which saint wrote "The Interior Castle" about the soul''s journey to God?',
        ARRAY['St. Catherine of Siena', 'St. Clare of Assisi', 'St. Teresa of Ávila', 'St. Thérèse of Lisieux'],
        2,
        'St. Teresa of Ávila wrote "The Interior Castle," one of the greatest works of Christian mysticism, describing the soul as a beautiful diamond with seven interior dwelling places.',
        NULL,
        6
    )
) AS v(question_text, options, correct_index, explanation, scripture_ref, sort_order);


-- ============================================================
-- QUIZ 3: New Testament Stories (difficulty 2, age 2)
-- ============================================================

WITH quiz3 AS (
    INSERT INTO public.quizzes (
        title, description, category, difficulty, min_age_group,
        time_limit_seconds,
        holy_points_reward, faith_coins_reward, xp_reward,
        passing_score, icon_name, is_active, sort_order
    ) VALUES (
        'New Testament Stories',
        'Explore the Gospels, Acts, and the Letters of the New Testament.',
        'bible', 2, 2,
        420,
        50, 8, 35,
        70, 'quiz_bible', true, 3
    )
    RETURNING id
)
INSERT INTO public.quiz_questions (quiz_id, question_text, options, correct_index, explanation, scripture_ref, sort_order)
SELECT q.id, v.question_text, v.options, v.correct_index, v.explanation, v.scripture_ref, v.sort_order
FROM quiz3 q,
(VALUES
    (
        'What did Jesus say when his disciples asked him how to pray?',
        ARRAY['He gave them a long speech', 'He taught them the Our Father (Lord''s Prayer)', 'He told them to pray in silence only', 'He said prayer was not necessary'],
        1,
        'Jesus taught his disciples the Our Father (Matthew 6:9-13 and Luke 11:2-4), the perfect model of Christian prayer.',
        'Matthew 6:9-13',
        1
    ),
    (
        'In the Parable of the Prodigal Son, what did the father do when his son returned?',
        ARRAY['Sent him away', 'Made him a servant', 'Ran to meet him and threw a feast', 'Lectured him for an hour'],
        2,
        'The father saw his returning son "while he was still a long way off" and ran to embrace him — a beautiful image of God''s mercy for repentant sinners.',
        'Luke 15:20',
        2
    ),
    (
        'How many loaves and fish did Jesus use to feed the 5,000?',
        ARRAY['10 loaves and 2 fish', '5 loaves and 2 fish', '7 loaves and 3 fish', '2 loaves and 5 fish'],
        1,
        'Jesus took five barley loaves and two fish from a young boy, blessed them, and fed over 5,000 people — with 12 baskets of fragments left over.',
        'John 6:9-13',
        3
    ),
    (
        'What happened at Pentecost?',
        ARRAY['Jesus was born', 'Jesus ascended to heaven', 'The Holy Spirit descended on the Apostles', 'The Last Supper took place'],
        2,
        'At Pentecost, fifty days after Easter, the Holy Spirit descended on Mary and the Apostles as tongues of fire. This is called the "birthday of the Church."',
        'Acts 2:1-4',
        4
    ),
    (
        'What does "the Resurrection" mean in the Christian faith?',
        ARRAY['Jesus rising spiritually in our hearts', 'Jesus truly rising from the dead in body and soul', 'A symbolic story about hope', 'Jesus appearing as a ghost'],
        1,
        'The Resurrection is the cornerstone of Christian faith: Jesus literally rose from the dead, conquering sin and death. As Paul writes: "If Christ has not been raised, your faith is in vain." (1 Cor 15:17)',
        '1 Corinthians 15:14',
        5
    ),
    (
        'Who wrote the most letters (epistles) in the New Testament?',
        ARRAY['St. Peter', 'St. John', 'St. Paul', 'St. James'],
        2,
        'St. Paul wrote 13-14 epistles (letters) in the New Testament, from Romans to Philemon, making him the most prolific writer in the New Testament.',
        NULL,
        6
    ),
    (
        'In John''s Gospel, Jesus says "I am the Way, the Truth, and the Life." To whom was he speaking?',
        ARRAY['Mary Magdalene', 'Peter', 'Thomas the Apostle', 'The crowd in the temple'],
        2,
        'Jesus spoke these words to Thomas at the Last Supper (John 14:6), after Thomas asked how they could know the way to where Jesus was going.',
        'John 14:6',
        7
    )
) AS v(question_text, options, correct_index, explanation, scripture_ref, sort_order);


-- ============================================================
-- QUIZ 4: Catholic Liturgy (difficulty 2, age 2)
-- ============================================================

WITH quiz4 AS (
    INSERT INTO public.quizzes (
        title, description, category, difficulty, min_age_group,
        time_limit_seconds,
        holy_points_reward, faith_coins_reward, xp_reward,
        passing_score, icon_name, is_active, sort_order
    ) VALUES (
        'Catholic Liturgy',
        'Learn about the Mass, the liturgical year, and Catholic worship.',
        'liturgy', 2, 2,
        420,
        50, 8, 35,
        70, 'quiz_liturgy', true, 4
    )
    RETURNING id
)
INSERT INTO public.quiz_questions (quiz_id, question_text, options, correct_index, explanation, scripture_ref, sort_order)
SELECT q.id, v.question_text, v.options, v.correct_index, v.explanation, v.scripture_ref, v.sort_order
FROM quiz4 q,
(VALUES
    (
        'What are the four main parts of the Mass in order?',
        ARRAY[
            'Opening Rite, Liturgy of the Word, Liturgy of the Eucharist, Concluding Rite',
            'Readings, Consecration, Communion, Blessing',
            'Welcome, Homily, Offertory, Dismissal',
            'Prayer, Confession, Communion, Blessing'
        ],
        0,
        'The Mass has four main parts: the Introductory Rites, Liturgy of the Word (readings and homily), Liturgy of the Eucharist (Offertory through Communion), and Concluding Rites.',
        NULL,
        1
    ),
    (
        'What color do priests wear during Ordinary Time?',
        ARRAY['Red', 'Purple', 'White', 'Green'],
        3,
        'Green vestments are worn during Ordinary Time, symbolizing hope and the growth of the Christian life. Different liturgical seasons have different colors.',
        NULL,
        2
    ),
    (
        'How many liturgical seasons are in the Catholic Church''s year?',
        ARRAY['Three', 'Four', 'Five', 'Six'],
        2,
        'There are five liturgical seasons: Advent, Christmas, Lent, Easter, and Ordinary Time (which actually occurs twice — before Lent and after Pentecost).',
        NULL,
        3
    ),
    (
        'What is the Consecration?',
        ARRAY[
            'A blessing said at the end of Mass',
            'The moment when bread and wine become the Body and Blood of Christ',
            'A prayer before receiving Communion',
            'The reading of the Gospel'
        ],
        1,
        'At the Consecration, through the words of the priest ("This is my Body...This is the chalice of my Blood..."), the bread and wine truly become the Body and Blood of Christ.',
        'Matthew 26:26-28',
        4
    ),
    (
        'What is the Kyrie Eleison?',
        ARRAY[
            'A prayer from the Book of Psalms',
            'A Greek phrase meaning "Lord, have mercy"',
            'The name of the opening hymn',
            'A Latin blessing'
        ],
        1,
        '"Kyrie Eleison" is Greek for "Lord, have mercy." It is one of the oldest prayers in the liturgy and is prayed at the beginning of Mass.',
        NULL,
        5
    ),
    (
        'When does the liturgical year begin?',
        ARRAY['January 1', 'Easter Sunday', 'The First Sunday of Advent', 'December 25'],
        2,
        'The Catholic liturgical year begins on the First Sunday of Advent, which falls in late November or early December — four Sundays before Christmas.',
        NULL,
        6
    ),
    (
        'What is transubstantiation?',
        ARRAY[
            'A type of baptism',
            'The change of bread and wine into the Body and Blood of Christ',
            'A feast day in June',
            'The translation of the Bible'
        ],
        1,
        'Transubstantiation is the Catholic teaching that at Mass, the entire substance of the bread and wine is changed into the Body and Blood of Christ, while only the appearances (accidents) of bread and wine remain.',
        NULL,
        7
    )
) AS v(question_text, options, correct_index, explanation, scripture_ref, sort_order);


-- ============================================================
-- QUIZ 5: Church History (difficulty 3, age 3)
-- ============================================================

WITH quiz5 AS (
    INSERT INTO public.quizzes (
        title, description, category, difficulty, min_age_group,
        time_limit_seconds,
        holy_points_reward, faith_coins_reward, xp_reward,
        passing_score, icon_name, is_active, sort_order
    ) VALUES (
        'Church History',
        'An advanced journey through 2,000 years of Catholic history.',
        'church_history', 3, 3,
        600,
        100, 15, 60,
        70, 'quiz_history', true, 5
    )
    RETURNING id
)
INSERT INTO public.quiz_questions (quiz_id, question_text, options, correct_index, explanation, scripture_ref, sort_order)
SELECT q.id, v.question_text, v.options, v.correct_index, v.explanation, v.scripture_ref, v.sort_order
FROM quiz5 q,
(VALUES
    (
        'What was the Edict of Milan (313 AD)?',
        ARRAY[
            'A declaration of war on Persia',
            'An edict granting religious tolerance to Christians throughout the Roman Empire',
            'A law forcing all Romans to become Christian',
            'A theological decree about the Trinity'
        ],
        1,
        'Emperor Constantine and Licinius issued the Edict of Milan in 313 AD, granting religious tolerance to Christians and ending the Roman persecution of the Church.',
        NULL,
        1
    ),
    (
        'What was defined at the First Council of Nicaea (325 AD)?',
        ARRAY[
            'The canon of Scripture',
            'The Pope''s infallibility',
            'The divinity of Jesus Christ against Arianism',
            'The date of Easter'
        ],
        2,
        'The Council of Nicaea defined that Jesus Christ is "consubstantial" (one in being) with the Father, refuting Arianism. The Nicene Creed we pray at Mass came from this council.',
        NULL,
        2
    ),
    (
        'The Great Schism of 1054 separated the Catholic Church from which group?',
        ARRAY['Lutherans', 'Anglicans', 'Eastern Orthodox', 'Calvinists'],
        2,
        'The Great Schism of 1054 split Christianity between the Western Catholic Church (centered in Rome) and the Eastern Orthodox Church (centered in Constantinople).',
        NULL,
        3
    ),
    (
        'What sparked the Protestant Reformation in 1517?',
        ARRAY[
            'A peasant revolt in France',
            'Martin Luther''s Ninety-Five Theses on indulgences',
            'The sacking of Rome',
            'A new Pope''s election'
        ],
        1,
        'Martin Luther nailed his Ninety-Five Theses to the church door in Wittenberg in 1517, criticizing the sale of indulgences. This is traditionally regarded as the start of the Protestant Reformation.',
        NULL,
        4
    ),
    (
        'What was the Council of Trent (1545-1563) a response to?',
        ARRAY[
            'The Crusades',
            'Persecution of Christians in Japan',
            'The Protestant Reformation — it reaffirmed and clarified Catholic doctrine',
            'The discovery of the Americas'
        ],
        2,
        'The Council of Trent was the Catholic response to the Protestant Reformation. It clarified Catholic doctrine on Scripture, Tradition, the Sacraments, justification, and more, launching the Counter-Reformation.',
        NULL,
        5
    ),
    (
        'What dogma was defined by Pope Pius IX in 1854?',
        ARRAY[
            'Papal Infallibility',
            'The Assumption of Mary',
            'The Immaculate Conception of Mary',
            'Purgatory'
        ],
        2,
        'The Immaculate Conception — that Mary was conceived without original sin — was defined as dogma on December 8, 1854 by Pope Pius IX in the bull "Ineffabilis Deus."',
        NULL,
        6
    ),
    (
        'What was the significance of the Second Vatican Council (1962-1965)?',
        ARRAY[
            'It changed the Church''s teachings on morality',
            'It opened a major period of renewal and updated how the Church engages with the modern world',
            'It elected a new Pope',
            'It was primarily about the Crusades'
        ],
        1,
        'Vatican II (called by Pope John XXIII) was a major pastoral council that renewed the Church''s liturgy, emphasized the role of the laity, promoted ecumenism, and reflected on the Church''s mission in the modern world.',
        NULL,
        7
    ),
    (
        'Who was the first non-Italian Pope in 455 years, elected in 1978?',
        ARRAY['Pope Benedict XVI', 'Pope Francis', 'Pope John Paul II', 'Pope Paul VI'],
        2,
        'Pope John Paul II (Karol Wojtyła of Poland) was elected in 1978, breaking a 455-year streak of Italian popes. He became one of the most influential popes in history.',
        NULL,
        8
    )
) AS v(question_text, options, correct_index, explanation, scripture_ref, sort_order);
