-- load_samplesテーブル作成
CREATE TABLE load_samples (
    sample_date date PRIMARY KEY,
    load_val int NOT NULL
);

INSERT INTO
    load_samples (sample_date, load_val)
VALUES
    ('2021-02-05', 600),
    ('2021-01-01', 100),
    ('2021-01-02', 200),
    ('2021-01-03', 300),
    ('2021-01-04', 400),
    ('2021-01-05', 500);

-- 確認
SELECT
    *
FROM
    load_samples;

-- 過去の直近の負荷
SELECT
    sample_date,
    min(sample_date) over w AS prev_date,
    min(load_val) over w AS prev_load,
    load_val
FROM
    load_samples window w AS (
        ORDER BY
            sample_date ASC ROWS BETWEEN 1 preceding
            AND 1 preceding
    );

-- 未来の直近の負荷
SELECT
    sample_date,
    min(sample_date) over w AS next_date,
    min(load_val) over w AS next_load,
    load_val
FROM
    load_samples window w AS (
        ORDER BY
            sample_date ASC ROWS BETWEEN 1 following
            AND 1 following
    );

-- 1日前の負荷
SELECT
    sample_date,
    min(sample_date) over w AS prev_date,
    min(load_val) over w AS prev_load,
    load_val
FROM
    load_samples window w AS (
        ORDER BY
            sample_date ASC RANGE BETWEEN INTERVAL '1' DAY preceding
            AND INTERVAL '1' DAY preceding
    );

-- 演習問題
-- server_load_samplesテーブル作成
CREATE TABLE server_load_samples (
    server char (1),
    sample_date date,
    load_val int NOT NULL,
    PRIMARY KEY (server, sample_date)
);

INSERT INTO
    server_load_samples (server, sample_date, load_val)
VALUES
    ('A', '2021-01-01', 100),
    ('A', '2021-01-02', 200),
    ('A', '2021-01-03', 300),
    ('A', '2021-01-04', 400),
    ('A', '2021-01-05', 500),
    ('B', '2021-01-01', 300),
    ('B', '2021-01-04', 700),
    ('B', '2021-01-08', 900),
    ('C', '2021-01-01', 400),
    ('C', '2021-01-02', 600),
    ('C', '2021-01-08', 800);

-- 確認
SELECT
    *
FROM
    server_load_samples;

-- 2-1
-- 予想: 全サーバー、全日付の負荷の合計
SELECT
    server,
    sample_date,
    sum(load_val) over () AS sum_load
FROM
    server_load_samples;

-- 2-2
-- 予想: サーバーごとの全日付の負荷の合計
SELECT
    server,
    sample_date,
    sum(load_val) over (PARTITION by server) AS sum_load
FROM
    server_load_samples