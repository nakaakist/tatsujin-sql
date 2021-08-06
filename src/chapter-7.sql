-- salesテーブル作成
CREATE TABLE sales (
    year integer PRIMARY KEY,
    sale integer NOT NULL
);

INSERT INTO
    sales (year, sale)
VALUES
    (2020, 50),
    (2021, 60),
    (2022, 60),
    (2023, 50),
    (2024, 80);

-- 確認
SELECT
    *
FROM
    sales;

-- 売り上げが変化しなかった年を求める(相関サブクエリ)
SELECT
    *
FROM
    sales s1
WHERE
    sale = (
        SELECT
            sale
        FROM
            sales s2
        WHERE
            s1.year = s2.year + 1
    );

-- 売り上げが変化しなかった年を求める(window)
SELECT
    *
FROM
    (
        SELECT
            *,
            min(sale) over w AS prev_sale
        FROM
            sales s1 window w AS (
                ORDER BY
                    year ROWS BETWEEN 1 preceding
                    AND 1 preceding
            )
    ) AS tmp
WHERE
    sale = prev_sale;

-- 前年と比べて減少、増加、変化なしを求める
SELECT
    year,
    sale,
    prev_sale,
    CASE
        WHEN sale > prev_sale THEN '増加'
        WHEN sale = prev_sale THEN '変化なし'
        WHEN sale < prev_sale THEN '減少'
    END AS trend
FROM
    (
        SELECT
            *,
            min(sale) over w AS prev_sale
        FROM
            sales s1 window w AS (
                ORDER BY
                    year ROWS BETWEEN 1 preceding
                    AND 1 preceding
            )
    ) AS tmp;

-- shohinsテーブル作成
CREATE TABLE shohins (
    shohin_id serial PRIMARY KEY,
    shohin_mei varchar (50) NOT NULL,
    shohin_bunrui varchar (50) NOT NULL,
    hanbai_tanka int NOT NULL
);

INSERT INTO
    shohins (
        shohin_id,
        shohin_mei,
        shohin_bunrui,
        hanbai_tanka
    )
VALUES
    (0, 'シャツ', '服', 1000),
    (1, 'パンチ', '事務用品', 500),
    (2, 'パンツ', '服', 300),
    (3, '包丁', 'キッチン用品', 2000),
    (4, '鍋', 'キッチン用品', 1000),
    (5, 'ペン', '事務用品', 100);

-- 確認
SELECT
    *
FROM
    shohins;

-- 各商品分類について、平均単価より高い商品
SELECT
    *
FROM
    (
        SELECT
            *,
            avg(hanbai_tanka) over w AS avg_tanka
        FROM
            shohins window w AS (PARTITION BY shohin_bunrui)
    ) AS tmp
WHERE
    hanbai_tanka > avg_tanka;

-- reservationsテーブル作成
CREATE TABLE reservations (
    reserver_id serial PRIMARY KEY,
    start_date date NOT NULL,
    end_date date NOT NULL
);

INSERT INTO
    reservations (reserver_id, start_date, end_date)
VALUES
    (0, '2021-01-01', '2021-01-02'),
    (1, '2021-01-03', '2021-01-05'),
    (2, '2021-01-05', '2021-01-07'),
    (3, '2021-01-09', '2021-01-10'),
    (4, '2021-01-09', '2021-01-12'),
    (5, '2021-01-13', '2021-01-13');

-- 確認
SELECT
    *
FROM
    reservations;

-- 宿泊期間がオーバーラップしている客をリストアップ(相関サブクエリ)
SELECT
    *
FROM
    reservations r1
WHERE
    EXISTS(
        SELECT
            *
        FROM
            reservations r2
        WHERE
            r1.reserver_id <> r2.reserver_id
            AND (
                r1.start_date BETWEEN r2.start_date
                AND r2.end_date
                OR r1.end_date BETWEEN r2.start_date
                AND r2.end_date
            )
    );

-- 宿泊期間がオーバーラップしている客をリストアップ(window)
SELECT
    reserver_id
FROM
    (
        SELECT
            *,
            max(start_date) over w_start AS next_start_date
        FROM
            reservations window w_start AS (
                ORDER BY
                    start_date ROWS BETWEEN 1 following
                    AND 1 following
            )
    ) AS tmp
WHERE
    next_start_date <= end_date;

-- 演習問題
-- 7-1
CREATE TABLE accounts (
    process_date date PRIMARY KEY,
    process_amount int NOT NULL
);

INSERT INTO
    accounts (process_date, process_amount)
VALUES
    ('2021-01-01', 12000),
    ('2021-01-03', -10000),
    ('2021-01-04', 500),
    ('2021-01-05', -1000),
    ('2021-01-07', 20000),
    ('2021-01-10', 1000),
    ('2021-01-11', 720);

-- 確認
SELECT
    *
FROM
    accounts;

-- 相関サブクエリで移動平均
SELECT
    process_date,
    A1.process_amount,
    (
        SELECT
            AVG(process_amount)
        FROM
            accounts A2
        WHERE
            A1.process_date >= A2.process_date
            AND(
                SELECT
                    COUNT(*)
                FROM
                    accounts A3
                WHERE
                    A3.process_date BETWEEN A2.process_date
                    AND A1.process_date
            ) <= 3
    ) AS mvg_sum
FROM
    accounts A1
ORDER BY
    process_date;

-- 7-2
-- 3行未満は平均値をnullとする(window)
SELECT
    process_date,
    CASE
        WHEN count(*) over w < 3 THEN NULL
        ELSE avg(process_amount) over w
    END AS avg_amount
FROM
    accounts window w AS (
        ORDER BY
            process_date ROWS BETWEEN 2 preceding
            AND current ROW
    );

-- 3行未満は平均値をnullとする(相関サブクエリ)
SELECT
    process_date,
    A1.process_amount,
    (
        SELECT
            AVG(process_amount)
        FROM
            accounts A2
        WHERE
            A1.process_date >= A2.process_date
            AND(
                SELECT
                    COUNT(*)
                FROM
                    accounts A3
                WHERE
                    A3.process_date BETWEEN A2.process_date
                    AND A1.process_date
            ) <= 3
        HAVING
            count(*) = 3
    ) AS mvg_sum
FROM
    accounts A1
ORDER BY
    process_date;