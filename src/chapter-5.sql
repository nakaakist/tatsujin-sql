-- meetingsテーブル作成
CREATE TABLE meetings (
    meeting_id serial,
    person varchar(50),
    PRIMARY KEY(meeting_id, person)
);

INSERT INTO
    meetings (meeting_id, person)
VALUES
    (0, 'hoge'),
    (0, 'fuga'),
    (1, 'hoge'),
    (1, 'fuga'),
    (1, 'piyo'),
    (2, 'piyo');

-- 各会議の欠席者一覧を取得
SELECT
    DISTINCT m1.meeting_id,
    m2.person
FROM
    meetings m1
    CROSS JOIN meetings m2
WHERE
    NOT EXISTS (
        SELECT
            person
        FROM
            meetings m3
        WHERE
            m1.meeting_id = m3.meeting_id
            AND m2.person = m3.person
    );

-- test scoresテーブル作成
CREATE TABLE test_scores (
    student_id serial,
    subject varchar(50),
    score int NOT NULL,
    PRIMARY KEY (student_id, subject)
);

INSERT INTO
    test_scores (student_id, subject, score)
VALUES
    (0, 'math', 100),
    (0, 'science', 200),
    (1, 'math', 50),
    (1, 'japanese', 30),
    (1, 'history', 200),
    (2, 'math', 150),
    (2, 'japanese', 80),
    (3, 'math', 80),
    (3, 'japanese', 30);

-- 確認
SELECT
    *
FROM
    test_scores;

-- 全ての教科について50点以上とっている生徒
SELECT
    DISTINCT s1.student_id
FROM
    test_scores s1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            test_scores s2
        WHERE
            s1.student_id = s2.student_id
            AND s2.score < 50
    );

-- 算数80点以上、国語50点以上とっている生徒(なお、国語を受けていない生徒も含める)
SELECT
    DISTINCT s1.student_id
FROM
    test_scores s1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            test_scores s2
        WHERE
            s1.student_id = s2.student_id
            AND (
                (
                    s2.subject = 'math'
                    AND s2.score < 80
                )
                OR (
                    s2.subject = 'japanese'
                    AND s2.score < 50
                )
            )
    );

-- 算数80点以上、国語50点以上とっている生徒(なお、国語を受けていない生徒も含める)
-- case文を使ったパターン
SELECT
    DISTINCT s1.student_id
FROM
    test_scores s1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            test_scores s2
        WHERE
            s1.student_id = s2.student_id
            AND 1 = (
                CASE
                    WHEN (
                        s2.subject = 'math'
                        AND s2.score < 80
                    ) THEN 1
                    WHEN (
                        s2.subject = 'japanese'
                        AND s2.score < 50
                    ) THEN 1
                    ELSE 0
                END
            )
    );

-- 算数80点以上、国語50点以上とっている生徒(国語を受験していない生徒は除く)
-- case文を使ったパターン
SELECT
    student_id
FROM
    test_scores s1
WHERE
    subject IN ('math', 'japanese')
    AND NOT EXISTS (
        SELECT
            *
        FROM
            test_scores s2
        WHERE
            s1.student_id = s2.student_id
            AND 1 = (
                CASE
                    WHEN (
                        s2.subject = 'math'
                        AND s2.score < 80
                    ) THEN 1
                    WHEN (
                        s2.subject = 'japanese'
                        AND s2.score < 50
                    ) THEN 1
                    ELSE 0
                END
            )
    )
GROUP BY
    student_id
HAVING
    count(*) = 2;

-- projectsテーブル作成
CREATE TYPE step_status AS ENUM ('done', 'wait');

CREATE TABLE projects (
    project_id serial,
    step_number serial,
    step_status step_status NOT NULL,
    PRIMARY KEY (project_id, step_number)
);

INSERT INTO
    projects (project_id, step_number, step_status)
VALUES
    (0, 0, 'done'),
    (0, 1, 'wait'),
    (0, 2, 'wait'),
    (1, 0, 'wait'),
    (1, 1, 'wait'),
    (2, 0, 'done'),
    (2, 1, 'done'),
    (2, 2, 'wait'),
    (2, 3, 'wait'),
    (3, 0, 'done'),
    (3, 1, 'done'),
    (4, 0, 'done'),
    (4, 1, 'done'),
    (4, 2, 'done'),
    (4, 3, 'wait');

-- 確認
SELECT
    *
FROM
    projects;

-- 工程1まで完了、2以降は(あれば)未完了なプロジェクト
SELECT
    DISTINCT project_id
FROM
    projects p1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            projects p2
        WHERE
            p1.project_id = p2.project_id
            AND step_status <> (
                CASE
                    WHEN step_number <= 1 THEN step_status('done')
                    ELSE step_status('wait')
                END
            )
    );

-- havingを使って同じことをする(パフォーマンスやや悪)
SELECT
    project_id
FROM
    projects
GROUP BY
    project_id
HAVING
    count (*) = SUM(
        CASE
            WHEN step_number <= 1
            AND step_status = 'done' THEN 1
            WHEN step_number > 1
            AND step_status = 'wait' THEN 1
            ELSE 0
        END
    );

-- arrayテーブルを作成
CREATE TABLE array_table (
    array_key serial PRIMARY KEY,
    col1 int,
    col2 int
);

INSERT INTO
    array_table (array_key, col1, col2)
VALUES
    (0, 1, 1),
    (1, NULL, NULL),
    (2, 3, NULL),
    (3, 1, 9),
    (4, 9, NULL);

-- 確認
SELECT
    *
FROM
    array_table;

-- オール1の行を探す(postgresの仕様上、本文のクエリそのままだとエラー)
SELECT
    *
FROM
    array_table
WHERE
    1 = ALL (array [col1, col2]);

-- 少なくとも一つは9の行を探す
SELECT
    *
FROM
    array_table
WHERE
    9 = ANY (array [col1, col2]);

-- オールnullの行を探す
SELECT
    *
FROM
    array_table
WHERE
    coalesce(col1, col2) IS NULL;

-- 演習問題
-- 5-1
CREATE TABLE array_rows (
    array_key serial,
    i serial,
    val int,
    PRIMARY KEY(array_key, i)
);

INSERT INTO
    array_rows (array_key, i, val)
VALUES
    (0, 0, 1),
    (0, 1, 1),
    (1, 0, NULL),
    (1, 1, NULL),
    (2, 0, NULL),
    (2, 1, 9),
    (3, 0, 9),
    (3, 1, 9);

-- 確認
SELECT
    *
FROM
    array_rows;

-- 値がオール1のkeyを探す
SELECT
    DISTINCT array_key
FROM
    array_rows a1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            array_rows a2
        WHERE
            a1.array_key = a2.array_key
            AND coalesce(a2.val, 0) <> 1
    );

-- 別解1
SELECT
    DISTINCT array_key
FROM
    array_rows a1
WHERE
    1 = ALL (
        SELECT
            val
        FROM
            array_rows a2
        WHERE
            a1.array_key = a2.array_key
    );

-- 別解2
SELECT
    DISTINCT array_key
FROM
    array_rows
GROUP BY
    array_key
HAVING
    count(*) = sum(
        CASE
            val
            WHEN 1 THEN 1
            ELSE 0
        END
    );

-- 5-2
-- not existsよりもパフォーマンスがやや劣る
SELECT
    DISTINCT project_id
FROM
    projects p1
WHERE
    TRUE = ALL (
        SELECT
            step_status = (
                CASE
                    WHEN step_number <= 1 THEN step_status('done')
                    ELSE step_status('wait')
                END
            )
        FROM
            projects p2
        WHERE
            p1.project_id = p2.project_id
    );

-- 5-3
-- numbersテーブル作成
CREATE TABLE numbers (num serial PRIMARY KEY);

INSERT INTO
    numbers (num)
SELECT
    generate_series
FROM
    generate_series(1, 100);

-- 確認
SELECT
    *
FROM
    numbers;

-- 素数を抜きだし
SELECT
    num
FROM
    numbers n1
WHERE
    num > 1
    AND NOT EXISTS (
        SELECT
            *
        FROM
            numbers n2
        WHERE
            n2.num > 1
            AND n2.num <= sqrt(n1.num)
            AND n1.num % n2.num = 0
    );