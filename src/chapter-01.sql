-- populationsテーブル作成
CREATE TABLE populations (
    prefecture_id serial PRIMARY KEY,
    population int NOT NULL
);

INSERT INTO
    populations (prefecture_id, population)
VALUES
    (0, 100),
    (1, 200),
    (2, 400),
    (3, 500),
    (4, 300);

-- 地域ごとに集計
SELECT
    CASE
        prefecture_id
        WHEN 0 THEN '四国'
        WHEN 1 THEN '四国'
        WHEN 2 THEN '四国'
        WHEN 3 THEN '四国'
        WHEN 4 THEN '九州'
        ELSE 'その他'
    END AS district,
    SUM(population)
FROM
    populations
GROUP BY
    district;

-- 階級ごとに集計
SELECT
    CASE
        WHEN population < 200 THEN '少'
        ELSE '多'
    END AS pop_class,
    COUNT(prefecture_id) AS pref_count
FROM
    populations
GROUP BY
    pop_class;

-- population_with_sexsテーブル作成
CREATE TABLE population_with_sexs (
    prefecture_id serial,
    is_male boolean,
    population int NOT NULL,
    PRIMARY KEY(prefecture_id, is_male)
);

INSERT INTO
    population_with_sexs (prefecture_id, is_male, population)
VALUES
    (0, TRUE, 100),
    (0, FALSE, 100),
    (1, TRUE, 150),
    (1, FALSE, 80),
    (2, TRUE, 90),
    (2, FALSE, 120),
    (3, TRUE, 100),
    (3, FALSE, 200),
    (4, TRUE, 300),
    (4, FALSE, 300);

-- 男女の人口を集計
SELECT
    prefecture_id,
    SUM(
        CASE
            WHEN is_male THEN 0
            ELSE population
        END
    ) AS female_population,
    SUM(
        CASE
            WHEN is_male THEN population
            ELSE 0
        END
    ) AS male_population
FROM
    population_with_sexs
GROUP BY
    prefecture_id
ORDER BY
    prefecture_id;

-- 条件によってupdate条件を分岐
UPDATE
    populations
SET
    population = CASE
        WHEN population < 200 THEN 100
        ELSE 500
    END;

-- 確認
SELECT
    *
FROM
    populations;

-- 講座マスタテーブル作成
CREATE TABLE course_master (
    course_id serial PRIMARY KEY,
    course_name varchar (50) NOT NULL
);

INSERT INTO
    course_master (course_id, course_name)
VALUES
    (0, '数学'),
    (1, '物理'),
    (2, '化学');

CREATE TABLE open_courses (
    MONTH char (6),
    course_id serial,
    PRIMARY KEY (MONTH, course_id),
    FOREIGN KEY (course_id) REFERENCES course_master
);

INSERT INTO
    open_courses (MONTH, course_id)
VALUES
    ('202106', 0),
    ('202106', 1),
    ('202107', 2),
    ('202107', 0);

-- 確認
SELECT
    *
FROM
    course_master;

SELECT
    *
FROM
    open_courses;

-- クロス表作成
SELECT
    course_master.course_name,
    CASE
        WHEN MAX(
            CASE
                MONTH
                WHEN '202106' THEN 1
                ELSE 0
            END
        ) > 0 THEN '○'
        ELSE '×'
    END AS is_open_june,
    CASE
        WHEN MAX(
            CASE
                MONTH
                WHEN '202107' THEN 1
                ELSE 0
            END
        ) > 0 THEN '○'
        ELSE '×'
    END AS is_open_july
FROM
    course_master
    INNER JOIN open_courses ON course_master.course_id = open_courses.course_id
GROUP BY
    course_master.course_id
ORDER BY
    course_master.course_id;

-- student_clubsテーブル作成
CREATE TABLE student_clubs (
    std_id serial,
    club_id serial,
    club_name varchar (50) NOT NULL,
    is_main_club boolean NOT NULL,
    PRIMARY KEY (std_id, club_id)
);

INSERT INTO
    student_clubs (std_id, club_id, club_name, is_main_club)
VALUES
    (0, 0, '野球', TRUE),
    (0, 1, '物理', FALSE),
    (1, 0, '野球', FALSE),
    (2, 1, '物理', TRUE),
    (2, 2, 'サッカー', FALSE);

-- 確認
SELECT
    *
FROM
    student_clubs;

-- メインクラブか、唯一所属しているクラブを生徒ごとに抽出
SELECT
    std_id,
    CASE
        WHEN COUNT(std_id) = 1 THEN MAX(club_name)
        ELSE MAX(
            CASE
                WHEN is_main_club THEN club_name
                ELSE NULL
            END
        )
    END AS main_club
FROM
    student_clubs
GROUP BY
    std_id
ORDER BY
    std_id;

-- 演習問題
-- 1-1
CREATE TABLE greatests (
    id char(1) PRIMARY KEY,
    x int,
    y int,
    z int
);

INSERT INTO
    greatests (id, x, y, z)
VALUES
    ('A', 1, 3, 5),
    ('B', 7, 3, 2),
    ('C', 1, 1, 10);

SELECT
    id,
    CASE
        WHEN greatest_x_y > z THEN greatest_x_y
        ELSE z
    END AS greatest
FROM
    (
        SELECT
            id,
            z,
            CASE
                WHEN x > y THEN x
                ELSE y
            END AS greatest_x_y
        FROM
            greatests
    ) AS greatest_x_y;

-- 1-2
SELECT
    CASE
        WHEN is_male THEN '男'
        ELSE '女'
    END AS sex,
    sum(population) AS whole_country,
    sum(
        CASE
            WHEN prefecture_id = 0 THEN population
            ELSE 0
        END
    ) AS pref_0,
    sum(
        CASE
            WHEN prefecture_id IN (0, 1, 2, 3) THEN population
            ELSE 0
        END
    ) AS shikoku
FROM
    population_with_sexs
GROUP BY
    is_male;

-- 1-3
SELECT
    *
FROM
    greatests
ORDER BY
    (
        CASE
            id
            WHEN 'A' THEN 2
            WHEN 'B' THEN 1
            WHEN 'C' THEN 0
        END
    );