-- seqsテーブル作成
CREATE TABLE seqs (
    seq serial PRIMARY KEY,
    name varchar (50) NOT NULL
);

INSERT INTO
    seqs (seq, name)
VALUES
    (0, 'hoge'),
    (1, 'fuga'),
    (3, 'piyo'),
    (4, 'hogera');

-- 確認
SELECT
    *
FROM
    seqs;

-- 歯抜けを探す
WITH seqs_with_prev AS (
    SELECT
        seq,
        min(seq) over w AS prev_seq,
        name
    FROM
        seqs window w AS (
            ORDER BY
                seq ROWS BETWEEN 1 preceding
                AND 1 preceding
        )
)
SELECT
    *
FROM
    seqs_with_prev
WHERE
    seq - prev_seq <> 1;

-- 歯抜けを探す(あるかどうかだけ)
SELECT
    CASE
        WHEN max(seq) - min(seq) > count(*) - 1 THEN '歯抜けあり'
        ELSE '歯抜けなし'
    END
FROM
    seqs;

-- 歯抜けを探す(having使用)
SELECT
    '歯抜けあり' AS gap
FROM
    seqs
HAVING
    max(seq) - min(seq) > count(*) - 1;

-- 歯抜けの最小値を探す
SELECT
    min(seq + 1)
FROM
    seqs s1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            seqs s2
        WHERE
            s1.seq + 1 = s2.seq
    );

-- 歯抜けを探す(テーブル空のときにも対応)
SELECT
    CASE
        WHEN count(*) = 0 THEN '空テーブル'
        WHEN max(seq) - min(seq) > count(*) - 1 THEN '歯抜けあり'
        ELSE '歯抜けなし'
    END
FROM
    seqs;

-- 歯抜けの最小値を探す(初期値が0と想定し、0から始まらない場合は歯抜けとみなす)
SELECT
    CASE
        WHEN min(seq) > 0 THEN 0
        ELSE (
            SELECT
                min(seq + 1)
            FROM
                seqs s1
            WHERE
                NOT EXISTS (
                    SELECT
                        *
                    FROM
                        seqs s2
                    WHERE
                        s1.seq + 1 = s2.seq
                )
        )
    END
FROM
    seqs;

-- graduatesテーブル作成
CREATE TABLE graduates (
    student_id serial PRIMARY KEY,
    income int NOT NULL
);

INSERT INTO
    graduates (student_id, income)
VALUES
    (0, 400000),
    (1, 30000),
    (2, 20000),
    (3, 20000),
    (4, 15000),
    (5, 10000),
    (6, 10000);

-- 確認
SELECT
    *
FROM
    graduates;

-- 最頻値を求める
SELECT
    income,
    count(*)
FROM
    graduates
GROUP BY
    income
HAVING
    count(*) >= ALL (
        SELECT
            count(*)
        FROM
            graduates
        GROUP BY
            income
    );

-- 最頻値を求める(max関数利用)
SELECT
    income,
    count(*)
FROM
    graduates
GROUP BY
    income
HAVING
    count(*) = (
        SELECT
            max(cnt)
        FROM
            (
                SELECT
                    count(*) AS cnt
                FROM
                    graduates
                GROUP BY
                    income
            ) AS tmp
    );

-- student_reportsテーブル作成
CREATE TABLE student_reports (
    student_id serial PRIMARY KEY,
    department varchar(50) NOT NULL,
    submit_date date
);

INSERT INTO
    student_reports (student_id, department, submit_date)
VALUES
    (0, 'science', '2021-01-01'),
    (1, 'science', '2021-01-02'),
    (2, 'literature', NULL),
    (3, 'literature', '2021-01-01'),
    (4, 'economics', NULL),
    (5, 'economics', '2021-01-03'),
    (6, 'engineering', '2021-01-01');

-- 確認
SELECT
    *
FROM
    student_reports;

-- 所属学生がすべて提出済みの学部を求める
SELECT
    department
FROM
    student_reports
GROUP BY
    department
HAVING
    count(*) = sum(
        CASE
            WHEN submit_date IS NULL THEN 0
            ELSE 1
        END
    );

-- 所属学生がすべて提出済みの学部を求める(countの特性を利用)
SELECT
    department
FROM
    student_reports
GROUP BY
    department
HAVING
    count(*) = count(submit_date);

-- 所属学生がすべて提出済みの学部を求める(existsを利用)
SELECT
    DISTINCT department
FROM
    student_reports r1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            student_reports r2
        WHERE
            r1.department = r2.department
            AND r2.submit_date IS NULL
    );

-- test_resultsテーブル作成
CREATE TABLE test_results (
    student_id serial PRIMARY KEY,
    class char(1) NOT NULL,
    is_male boolean NOT NULL,
    score int NOT NULL
);

INSERT INTO
    test_results (student_id, class, is_male, score)
VALUES
    (0, 'A', TRUE, 100),
    (1, 'A', FALSE, 100),
    (2, 'A', TRUE, 30),
    (3, 'B', TRUE, 100),
    (4, 'B', FALSE, 100),
    (5, 'B', TRUE, 92),
    (6, 'B', TRUE, 100),
    (7, 'C', FALSE, 20),
    (8, 'C', FALSE, 80);

-- 確認
SELECT
    *
FROM
    test_results;

-- クラスの75%以上の生徒が80点以上のクラス
SELECT
    class
FROM
    test_results
GROUP BY
    class
HAVING
    count(*) * 0.75 <= SUM(
        CASE
            WHEN score >= 80 THEN 1
            ELSE 0
        END
    );

-- 50点以上をとった生徒のうち、男の方が女より多いクラス
SELECT
    class
FROM
    test_results
GROUP BY
    class
HAVING
    0 < sum(
        CASE
            WHEN score >= 50
            AND is_male THEN 1
            WHEN score >= 50
            AND NOT is_male THEN -1
            ELSE 0
        END
    );

-- 女子の平均点が、男子の平均点より高いクラス
SELECT
    class
FROM
    test_results
GROUP BY
    class
HAVING
    avg(
        CASE
            WHEN NOT is_male THEN score
            ELSE NULL
        END
    ) > avg(
        CASE
            WHEN is_male THEN score
            ELSE NULL
        END
    );

-- teamsテーブル作成
CREATE TYPE member_status AS ENUM ('ready', 'out', 'rest');

CREATE TABLE teams (
    member_id serial PRIMARY KEY,
    team_id serial NOT NULL,
    member_status member_status NOT NULL
);

INSERT INTO
    teams (member_id, team_id, member_status)
VALUES
    (0, 0, 'ready'),
    (1, 0, 'out'),
    (2, 0, 'ready'),
    (3, 1, 'ready'),
    (4, 1, 'ready'),
    (5, 2, 'rest'),
    (6, 3, 'ready');

-- 確認
SELECT
    *
FROM
    teams;

-- メンバー全員がreadyのチーム
SELECT
    DISTINCT team_id
FROM
    teams t1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            teams t2
        WHERE
            t1.team_id = t2.team_id
            AND t2.member_status <> member_status('ready')
    );

-- メンバー全員がreadyのチーム(having利用)
SELECT
    team_id
FROM
    teams
GROUP BY
    team_id
HAVING
    count(*) = sum(
        CASE
            member_status
            WHEN 'ready' THEN 1
            ELSE 0
        END
    );

-- 全員readyかそうでないかをカラムにする
SELECT
    team_id,
    CASE
        (
            max(member_status) = 'ready'
            AND min(member_status) = 'ready'
        )
        WHEN TRUE THEN 'everyone ready'
        ELSE 'not everyone ready'
    END AS team_status
FROM
    teams
GROUP BY
    team_id;

-- 同じstatusの人がいるチーム
SELECT
    team_id
FROM
    teams
GROUP BY
    team_id
HAVING
    count(*) > count(DISTINCT member_status);

-- 同じstatusの人がいるチームを、かぶっているstatsuまで含めて表示
SELECT
    team_id,
    member_id,
    member_status
FROM
    teams t1
WHERE
    EXISTS (
        SELECT
            t2.member_status
        FROM
            teams t2
        WHERE
            t1.team_id = t2.team_id
            AND t1.member_status = t2.member_status
            AND t1.member_id <> t2.member_id
    );

-- items, shop_itemsテーブル作成
CREATE TABLE items (
    item_id serial PRIMARY KEY,
    item_name varchar(50) UNIQUE NOT NULL
);

CREATE TABLE shop_items (
    shop_id serial,
    item_id serial,
    PRIMARY KEY (shop_id, item_id)
);

INSERT INTO
    items (item_id, item_name)
VALUES
    (0, 'ビール'),
    (1, 'おむつ'),
    (2, '自転車');

INSERT INTO
    shop_items (shop_id, item_id)
VALUES
    (0, 0),
    (0, 1),
    (1, 0),
    (1, 1),
    (1, 2),
    (1, 3),
    (2, 0),
    (2, 3),
    (3, 0),
    (3, 1),
    (3, 2);

-- 確認
SELECT
    *
FROM
    items;

SELECT
    *
FROM
    shop_items;

-- itemsテーブルの商品を全て揃えている店舗
SELECT
    shop_id
FROM
    shop_items
    INNER JOIN items ON shop_items.item_id = items.item_id
GROUP BY
    shop_id
HAVING
    count(*) = (
        SELECT
            count(*)
        FROM
            items
    );

-- itemsテーブルの商品を全て揃えており、かつitemsテーブル以外の商品を売っていない店舗
SELECT
    shop_id
FROM
    shop_items
    LEFT OUTER JOIN items ON shop_items.item_id = items.item_id
GROUP BY
    shop_id
HAVING
    count(shop_items.item_id) = (
        SELECT
            count(*)
        FROM
            items
    )
    AND count(items.item_id) = (
        SELECT
            count(*)
        FROM
            items
    );

-- 演習問題
-- 6-1
SELECT
    CASE
        WHEN count(seq) = 0 THEN 'seqなし'
        WHEN (max(seq) - min(seq) + 1 > count(*)) THEN '歯抜けあり'
        ELSE '歯抜けなし'
    END
FROM
    seqs;

-- 6-2
-- 全員が1/1に提出済みの学部を求める
SELECT
    department
FROM
    student_reports
GROUP BY
    department
HAVING
    count(*) = sum(
        CASE
            WHEN submit_date = '2021-01-01' THEN 1
            ELSE 0
        END
    );

-- 6-3
SELECT
    si.shop_id,
    count(si.item_id) AS my_item_count,
    (
        SELECT
            count(*)
        FROM
            items
    ) - count(si.item_id) AS diff_count
FROM
    shop_items si
    INNER JOIN items i ON si.item_id = i.item_id
GROUP BY
    si.shop_id
ORDER BY
    si.shop_id