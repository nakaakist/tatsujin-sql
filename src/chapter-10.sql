-- digitsテーブル作成
CREATE TABLE digits (digit serial PRIMARY KEY);

INSERT INTO
    digits (digit)
VALUES
    (0),
    (1),
    (2),
    (3),
    (4),
    (5),
    (6),
    (7),
    (8),
    (9);

-- 確認
SELECT
    *
FROM
    digits;

-- 0-99の連番
SELECT
    d1.digit + d2.digit * 10 AS seq
FROM
    digits d1
    CROSS JOIN digits d2
ORDER BY
    seq;

-- 123-542の連番
SELECT
    seq
FROM
    (
        SELECT
            d1.digit + d2.digit * 10 + d3.digit * 100 AS seq
        FROM
            digits d1
            CROSS JOIN digits d2
            CROSS JOIN digits d3
    ) tmp
WHERE
    seq BETWEEN 123
    AND 542
ORDER BY
    seq;

-- 連番view作成
CREATE VIEW sequences AS
SELECT
    d1.digit + d2.digit * 10 + d3.digit * 100 AS seq
FROM
    digits d1
    CROSS JOIN digits d2
    CROSS JOIN digits d3
ORDER BY
    seq;

-- 確認
SELECT
    *
FROM
    sequences;

-- seq_table作成
CREATE TABLE seq_table (seq serial PRIMARY KEY);

INSERT INTO
    seq_table (seq)
VALUES
    (1),
    (2),
    (4),
    (5),
    (6),
    (7),
    (8),
    (11),
    (12);

-- 欠番を全て求める
SELECT
    seq
FROM
    (
        SELECT
            seq
        FROM
            sequences
        WHERE
            seq <= (
                SELECT
                    max(seq)
                FROM
                    seq_table
            )
        EXCEPT
        SELECT
            seq
        FROM
            seq_table
    ) seq_lack;

-- 欠番を全て求める(IN使用)
SELECT
    seq
FROM
    sequences
WHERE
    seq <= (
        SELECT
            max(seq)
        FROM
            seq_table
    )
    AND seq NOT IN (
        SELECT
            seq
        FROM
            seq_table
    );

-- seatsテーブル作成
CREATE TYPE seat_status AS enum('vacant', 'occupied');

CREATE TABLE seats (
    seat serial PRIMARY KEY,
    seat_status seat_status NOT NULL
);

INSERT INTO
    seats (seat_status)
VALUES
    ('occupied'),
    ('vacant'),
    ('vacant'),
    ('vacant'),
    ('vacant'),
    ('occupied'),
    ('vacant'),
    ('occupied'),
    ('vacant'),
    ('vacant'),
    ('vacant');

-- 確認
SELECT
    *
FROM
    seats;

-- 3人席のシーケンスを探す(window)
SELECT
    seat
FROM
    (
        SELECT
            seat,
            sum(
                CASE
                    seat_status
                    WHEN 'vacant' THEN 1
                    ELSE 0
                END
            ) over w AS num_next_vacant_seats
        FROM
            seats window w AS (
                ORDER BY
                    seat ROWS BETWEEN current ROW
                    AND 2 following
            )
    ) agg
WHERE
    num_next_vacant_seats = 3;

-- 3人席のシーケンスを探す(not exists)
SELECT
    s1.seat
FROM
    seats s1
    CROSS JOIN seats s2
WHERE
    s2.seat = s1.seat + 2
    AND NOT EXISTS (
        SELECT
            *
        FROM
            seats s3
        WHERE
            seat BETWEEN s1.seat
            AND s2.seat
            AND seat_status = 'occupied'
    );

-- line_seatsテーブル作成
CREATE TABLE line_seats (
    seat serial PRIMARY KEY,
    line_id char(1) NOT NULL,
    seat_status seat_status NOT NULL
);

INSERT INTO
    line_seats (line_id, seat_status)
VALUES
    ('A', 'occupied'),
    ('A', 'vacant'),
    ('A', 'vacant'),
    ('A', 'vacant'),
    ('B', 'vacant'),
    ('B', 'occupied'),
    ('B', 'vacant'),
    ('B', 'occupied'),
    ('C', 'vacant'),
    ('C', 'vacant'),
    ('C', 'vacant'),
    ('C', 'vacant');

-- 確認
SELECT
    *
FROM
    line_seats;

-- 同じline内で3人席のシーケンスを探す
SELECT
    seat
FROM
    (
        SELECT
            *,
            max(line_id) over w AS max_line_id,
            min(line_id) over w AS min_line_id,
            sum(
                CASE
                    seat_status
                    WHEN 'vacant' THEN 1
                    ELSE 0
                END
            ) over w AS num_next_vacant_seats
        FROM
            line_seats window w AS (
                ORDER BY
                    seat ROWS BETWEEN current ROW
                    AND 2 following
            )
    ) tmp
WHERE
    max_line_id = min_line_id
    AND num_next_vacant_seats = 3;

-- 同じline内で3人席のシーケンスを探す(not exists)
SELECT
    s1.seat
FROM
    line_seats s1
    CROSS JOIN line_seats s2
WHERE
    s2.seat = s1.seat + 2
    AND s1.line_id = s2.line_id
    AND NOT EXISTS (
        SELECT
            *
        FROM
            line_seats s3
        WHERE
            seat BETWEEN s1.seat
            AND s2.seat
            AND seat_status = 'occupied'
    );

-- 同じline内で3人席のシーケンスを探す(windowでpartition by利用)
SELECT
    seat
FROM
    (
        SELECT
            *,
            sum(
                CASE
                    seat_status
                    WHEN 'vacant' THEN 1
                    ELSE 0
                END
            ) over w AS num_next_vacant_seats
        FROM
            line_seats window w AS (
                PARTITION by line_id
                ORDER BY
                    seat ROWS BETWEEN current ROW
                    AND 2 following
            )
    ) tmp
WHERE
    num_next_vacant_seats = 3;

-- my_stockテーブル作成
CREATE TABLE my_stock (
    deal_date date PRIMARY KEY,
    price int NOT NULL
);

INSERT INTO
    my_stock (deal_date, price)
VALUES
    ('2021-01-01', 1000),
    ('2021-01-03', 1050),
    ('2021-01-04', 1050),
    ('2021-01-05', 900),
    ('2021-01-06', 800),
    ('2021-01-09', 1000),
    ('2021-01-10', 1100),
    ('2021-01-11', 1300);

--確認
SELECT
    *
FROM
    my_stock;

-- 前回から上昇したかどうか
SELECT
    *,
    CASE
        sign(price - (min(price) over w))
        WHEN 1 THEN 'up'
        WHEN 0 THEN 'stay'
        WHEN -1 THEN 'down'
        ELSE NULL
    END
FROM
    my_stock window w AS (
        ORDER BY
            deal_date ROWS BETWEEN 1 preceding
            AND 1 preceding
    );

-- upのレコードに限定して、連番を降ったビューを作成
CREATE VIEW my_stock_up_seq AS (
    SELECT
        deal_date,
        price,
        row_num
    FROM
        (
            SELECT
                deal_date,
                price,
                CASE
                    sign(price - (min(price) over w))
                    WHEN 1 THEN 'up'
                    WHEN 0 THEN 'stay'
                    WHEN -1 THEN 'down'
                    ELSE NULL
                END AS diff,
                row_number() over(
                    ORDER BY
                        deal_date
                ) AS row_num
            FROM
                my_stock window w AS (
                    ORDER BY
                        deal_date ROWS BETWEEN 1 preceding
                        AND 1 preceding
                )
        ) AS tmp
    WHERE
        diff = 'up'
);

-- 確認
SELECT
    *
FROM
    my_stock_up_seq;

-- priceが上昇している区間を抽出
SELECT
    MIN(deal_date) AS start_date,
    '～',
    MAX(deal_date) AS end_date
FROM
    (
        SELECT
            M1.deal_date,
            COUNT(M2.row_num) - MIN(M1.row_num) AS gap
        FROM
            my_stock_up_seq M1
            INNER JOIN my_stock_up_seq M2 ON M2.row_num <= M1.row_num
        GROUP BY
            M1.deal_date
    ) TMP
GROUP BY
    gap;

-- 演習問題
-- 10-1
-- not exists
SELECT
    *
FROM
    sequences s1
WHERE
    seq <= 12
    AND NOT EXISTS (
        SELECT
            *
        FROM
            seq_table
        WHERE
            s1.seq = seq_table.seq
    );

-- 外部結合
SELECT
    s1.seq
FROM
    sequences s1
    LEFT OUTER JOIN seq_table s2 ON s1.seq = s2.seq
WHERE
    s1.seq <= 12
    AND s2.seq IS NULL;

-- 10-2
-- 列がないパターン
SELECT
    s1.seat
FROM
    seats s1
    CROSS JOIN seats s2
WHERE
    s2.seat BETWEEN s1.seat
    AND s1.seat + 2
GROUP BY
    s1.seat
HAVING
    3 = sum(
        CASE
            WHEN s2.seat_status = 'vacant' THEN 1
            ELSE 0
        END
    );

-- 列があるパターン
SELECT
    s1.seat
FROM
    line_seats s1
    CROSS JOIN line_seats s2
WHERE
    s2.seat BETWEEN s1.seat
    AND s1.seat + 2
GROUP BY
    s1.seat
HAVING
    3 = sum(
        CASE
            WHEN s1.line_id = s2.line_id
            AND s2.seat_status = 'vacant' THEN 1
            ELSE 0
        END
    );