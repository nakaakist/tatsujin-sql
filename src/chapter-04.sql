-- classテーブル作成
CREATE TABLE class_a (
    student_id serial PRIMARY KEY,
    age int,
    city varchar(50)
);

INSERT INTO
    class_a (student_id, age, city)
VALUES
    (0, 10, 'tokyo'),
    (1, 11, 'tokyo'),
    (2, 11, 'saitama');

CREATE TABLE class_b (
    student_id serial PRIMARY KEY,
    age int,
    city varchar(50)
);

INSERT INTO
    class_b (student_id, age, city)
VALUES
    (3, 11, 'tokyo'),
    (4, NULL, 'tokyo'),
    (5, 11, 'saitama');

-- 確認
SELECT
    *
FROM
    class_a;

SELECT
    *
FROM
    class_b;

-- Bクラスの東京在住の生徒と年齢が一致するAクラスの生徒を選択するSQL
SELECT
    *
FROM
    class_a
WHERE
    EXISTS (
        SELECT
            student_id
        FROM
            class_b
        WHERE
            city = 'tokyo'
            AND class_a.age = class_b.age
    );

-- Bクラスの東京在住の生徒と年齢が一致しないAクラスの生徒を選択するSQL(誤り)
SELECT
    *
FROM
    class_a
WHERE
    age NOT IN (
        SELECT
            age
        FROM
            class_b
        WHERE
            city = 'tokyo'
    );

-- Bクラスの東京在住の生徒と年齢が一致しないAクラスの生徒を選択するSQL(正しい)
SELECT
    *
FROM
    class_a
WHERE
    NOT EXISTS (
        SELECT
            student_id
        FROM
            class_b
        WHERE
            city = 'tokyo'
            AND class_a.age = class_b.age
    );

-- nullを除いたクラスBを作成
CREATE TABLE class_b_non_null (
    student_id serial PRIMARY KEY,
    age int,
    city varchar(50)
);

INSERT INTO
    class_b_non_null (student_id, age, city)
VALUES
    (3, 11, 'tokyo'),
    (4, 12, 'tokyo'),
    (5, 11, 'saitama');

-- 確認
SELECT
    *
FROM
    class_b_non_null;

-- nullを除いたクラスBの東京在住の生徒の誰よりも若いクラスAの生徒
SELECT
    *
FROM
    class_a
WHERE
    age < ALL (
        SELECT
            age
        FROM
            class_b_non_null
        WHERE
            city = 'tokyo'
    );

-- nullありのクラスBの東京在住の生徒の誰よりも若いクラスAの生徒(誤り)
SELECT
    *
FROM
    class_a
WHERE
    age < ALL (
        SELECT
            age
        FROM
            class_b
        WHERE
            city = 'tokyo'
    );

-- nullありのクラスBの東京在住の生徒の誰よりも若いクラスAの生徒(min使用)
SELECT
    *
FROM
    class_a
WHERE
    age < (
        SELECT
            MIN(age)
        FROM
            class_b
        WHERE
            city = 'tokyo'
    );

-- 演習問題
-- 4-1
-- postgresでは、nulls firstだが、
-- ORDER BY *** DESC NULLS LASTとするとnullを最後に持って来れる。
-- 4-2
-- postgresでは、文字列にnull連結するとnullになる
-- 4-3
-- coalesceは、nullの代わりにデフォルト値を埋めてくれる。例えば、
SELECT
    coalesce (age, -1)
FROM
    class_b;

-- nullifは、引数が等しい場合にnullを返す。例えば、
SELECT
    student_id,
    age,
    nullif(age, 10) AS age_null_if_10
FROM
    class_a