-- productsテーブル作成
CREATE TABLE products (
    product_id serial PRIMARY KEY,
    price int NOT NULL
);

INSERT INTO
    products (product_id, price)
VALUES
    (1, 100),
    (2, 200),
    (3, 300);

-- 重複を許容した順列
SELECT
    p1.product_id AS id_1,
    p2.product_id AS id_2
FROM
    products AS p1
    CROSS JOIN products AS p2;

-- 重複を許容しない順列
SELECT
    p1.product_id AS id_1,
    p2.product_id AS id_2
FROM
    products AS p1
    INNER JOIN products AS p2 ON p1.product_id <> p2.product_id;

-- 必ず２番目が大きくなる順列(=組み合わせ)
SELECT
    p1.product_id AS id_1,
    p2.product_id AS id_2
FROM
    products AS p1
    INNER JOIN products AS p2 ON p1.product_id < p2.product_id;

-- ３ことりだしたときの組み合わせ
SELECT
    p1.product_id AS id_1,
    p2.product_id AS id_2,
    p3.product_id AS id_3
FROM
    products AS p1
    INNER JOIN products AS p2 ON p1.product_id < p2.product_id
    INNER JOIN products AS p3 ON p2.product_id < p3.product_id;

-- priceが重複している行を入れる
INSERT INTO
    products (product_id, price)
VALUES
    (4, 100);

-- 確認
SELECT
    *
FROM
    products;

-- 重複削除(自己相関サブクエリ)
DELETE FROM
    products p1
WHERE
    p1.product_id > (
        SELECT
            min(p2.product_id)
        FROM
            products p2
        WHERE
            p1.price = p2.price
    );

-- 確認
SELECT
    *
FROM
    products;

-- priceが重複している行を入れる
INSERT INTO
    products (product_id, price)
VALUES
    (4, 100);

-- 確認
SELECT
    *
FROM
    products;

-- 重複削除(非等値結合)
DELETE FROM
    products p1
WHERE
    EXISTS (
        SELECT
            *
        FROM
            products p2
        WHERE
            p1.price = p2.price
            AND p1.product_id > p2.product_id
    );

-- 確認
SELECT
    *
FROM
    products;

-- addressesテーブル作成
CREATE TABLE addresses (
    person_id serial PRIMARY KEY,
    family_id serial NOT NULL,
    address varchar (50) NOT NULL
);

INSERT INTO
    addresses (person_id, family_id, address)
VALUES
    (1, 100, 'hoge street'),
    (2, 100, 'hogge street'),
    (3, 200, 'fuga street'),
    (4, 200, 'fuga street'),
    (5, 300, 'piyo street'),
    (6, 400, 'piyo street');

-- 確認
SELECT
    *
FROM
    addresses;

-- 同じfamily_idだけど住所が違うレコード抽出
SELECT
    a1.*
FROM
    addresses a1
    INNER JOIN addresses a2 ON a1.family_id = a2.family_id
    AND a1.address <> a2.address;

-- ランキング付け
-- priceが重複している行を入れる
INSERT INTO
    products (product_id, price)
VALUES
    (4, 200);

-- 確認
SELECT
    *
FROM
    products;

-- 2種類のランキング (rank(), dense_rank()関数はover節の前にしか使えない)
SELECT
    product_id,
    rank() over w AS rank_1,
    dense_rank() over w AS rank_2,
    price
FROM
    products window w AS (
        ORDER BY
            price DESC
    );

-- 自己非等値結合を使う場合
SELECT
    p1.product_id,
    count(p2.product_id) + 1 AS rank,
    p1.price
FROM
    products p1
    LEFT OUTER JOIN products p2 ON p1.price < p2.price
GROUP BY
    p1.product_id
ORDER BY
    rank;

-- 付け加えた余分な行削除
DELETE FROM
    products
WHERE
    product_id = 4;

-- 演習問題
-- 3-1
SELECT
    p1.product_id AS id_1,
    p2.product_id AS id_2
FROM
    products p1
    INNER JOIN products p2 ON p1.product_id <= p2.product_id