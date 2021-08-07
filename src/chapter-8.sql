-- coursesテーブル作成
CREATE TABLE courses (
    student_id serial,
    course varchar (50),
    PRIMARY KEY (student_id, course)
);

INSERT INTO
    courses (student_id, course)
VALUES
    (0, 'sql'),
    (0, 'unix'),
    (1, 'sql'),
    (2, 'sql'),
    (2, 'java'),
    (3, 'unix');

-- 確認
SELECT
    *
FROM
    courses;

-- クロス表作成
SELECT
    student_ids.student_id AS student_id,
    CASE
        WHEN sql_student_ids.student_id IS NULL THEN 'x'
        ELSE 'o'
    END AS SQL,
    CASE
        WHEN unix_student_ids.student_id IS NULL THEN 'x'
        ELSE 'o'
    END AS unix,
    CASE
        WHEN java_student_ids.student_id IS NULL THEN 'x'
        ELSE 'o'
    END AS java
FROM
    (
        SELECT
            DISTINCT student_id
        FROM
            courses
    ) student_ids
    LEFT OUTER JOIN (
        SELECT
            student_id
        FROM
            courses
        WHERE
            course = 'sql'
    ) sql_student_ids ON student_ids.student_id = sql_student_ids.student_id
    LEFT OUTER JOIN (
        SELECT
            student_id
        FROM
            courses
        WHERE
            course = 'unix'
    ) unix_student_ids ON student_ids.student_id = unix_student_ids.student_id
    LEFT OUTER JOIN (
        SELECT
            student_id
        FROM
            courses
        WHERE
            course = 'java'
    ) java_student_ids ON student_ids.student_id = java_student_ids.student_id
ORDER BY
    student_ids.student_id;

-- 他の方法
SELECT
    student_ids.student_id,
    (
        SELECT
            'o'
        FROM
            courses tmp_courses
        WHERE
            course = 'sql'
            AND tmp_courses.student_id = student_ids.student_id
    ) AS SQL,
    (
        SELECT
            'o'
        FROM
            courses tmp_courses
        WHERE
            course = 'unix'
            AND tmp_courses.student_id = student_ids.student_id
    ) AS unix,
    (
        SELECT
            'o'
        FROM
            courses tmp_courses
        WHERE
            course = 'java'
            AND tmp_courses.student_id = student_ids.student_id
    ) AS java
FROM
    (
        SELECT
            DISTINCT student_id
        FROM
            courses
    ) student_ids;

-- personnelsテーブル作成
CREATE TABLE personnels (
    employee_id serial PRIMARY KEY,
    child_1 varchar(50),
    child_2 varchar(50)
);

INSERT INTO
    personnels (employee_id, child_1, child_2)
VALUES
    (0, 'hoge', 'fuga'),
    (1, 'piyo', NULL),
    (2, NULL, NULL);

-- 確認
SELECT
    *
FROM
    personnels;

-- 列から行へ変換
-- union all を使う。unionとは、concatみたいなもん。
-- unionでは重複行を削除するが、union allでは削除しない
-- https://qiita.com/tarosuke777000/items/391b0291faae45974be1
SELECT
    employee_id,
    child_1 AS child
FROM
    personnels
UNION
ALL
SELECT
    employee_id,
    child_2 AS child
FROM
    personnels;

-- 子供がいる人に関してはnullを排除した上で、子供がいない人も表示する
-- 子供のマスタ作成
-- create view ビュー名(カラム名,...) で、select結果を新たなテーブルにできる。
CREATE VIEW children AS (
    SELECT
        child
    FROM
        (
            SELECT
                child_1 AS child
            FROM
                personnels
            UNION
            SELECT
                child_2 AS child
            FROM
                personnels
        ) children
    WHERE
        child IS NOT NULL
);

-- 確認
SELECT
    *
FROM
    children;

-- 子供のいない社員も含めた子供一覧
SELECT
    p.employee_id,
    c.child
FROM
    personnels p
    LEFT OUTER JOIN children c ON c.child IN (p.child_1, p.child_2);

-- 脱線
-- joinのonのテスト(onをtrueにしてcross joinと同じにする)
SELECT
    *
FROM
    personnels p
    LEFT OUTER JOIN children c ON TRUE;

-- joinのonテスト(onでequal絞り込み)
SELECT
    *
FROM
    personnels p
    LEFT OUTER JOIN children c ON p.child_1 = c.child;

-- ages, sexes, pref_populationsテーブル作成
CREATE TABLE ages (
    age_class serial PRIMARY KEY,
    age_range varchar(50) UNIQUE NOT NULL
);

CREATE TABLE sexes (
    sex_code char(1) PRIMARY KEY,
    sex varchar(50) UNIQUE NOT NULL
);

CREATE TABLE pref_populations (
    pref_name varchar(50),
    age_class serial,
    sex_code char(1),
    population integer NOT NULL,
    PRIMARY KEY (pref_name, age_class, sex_code),
    FOREIGN KEY (age_class) REFERENCES ages(age_class),
    FOREIGN KEY (sex_code) REFERENCES sexes(sex_code)
);

INSERT INTO
    ages (age_class, age_range)
VALUES
    (0, '21-30'),
    (1, '31-40'),
    (2, '41-50');

INSERT INTO
    sexes (sex_code, sex)
VALUES
    ('m', '男'),
    ('f', '女');

INSERT INTO
    pref_populations (pref_name, age_class, sex_code, population)
VALUES
    ('秋田', 0, 'm', 1000),
    ('秋田', 0, 'f', 200),
    ('秋田', 1, 'm', 400),
    ('秋田', 1, 'f', 800),
    ('東京', 0, 'm', 1000),
    ('東京', 0, 'f', 200),
    ('東京', 1, 'f', 800),
    ('千葉', 0, 'm', 1000),
    ('千葉', 0, 'f', 200),
    ('千葉', 1, 'm', 800);

-- 確認
SELECT
    *
FROM
    ages;

SELECT
    *
FROM
    sexes;

SELECT
    *
FROM
    pref_populations;

-- 統計表作成
SELECT
    age_sexes.age_range,
    age_sexes.sex,
    data.population_kanto,
    data.population_tohoku
FROM
    (
        SELECT
            age_class,
            sex_code,
            sum(
                CASE
                    WHEN pref_name IN ('秋田') THEN population
                    ELSE 0
                END
            ) AS population_tohoku,
            sum(
                CASE
                    WHEN pref_name IN ('東京', '千葉') THEN population
                    ELSE 0
                END
            ) AS population_kanto
        FROM
            pref_populations
        GROUP BY
            age_class,
            sex_code
    ) data
    RIGHT OUTER JOIN (
        SELECT
            *
        FROM
            ages
            CROSS JOIN sexes
    ) age_sexes ON age_sexes.age_class = data.age_class
    AND age_sexes.sex_code = data.sex_code;

-- sale_items, sales_historyテーブル作成
CREATE TABLE sale_items (
    item_no serial PRIMARY KEY,
    item varchar(50)
);

CREATE TABLE sales_history (
    sale_date date,
    item_no serial,
    quantity integer NOT NULL,
    PRIMARY KEY (sale_date, item_no),
    FOREIGN KEY (item_no) REFERENCES sale_items(item_no)
);

INSERT INTO
    sale_items (item_no, item)
VALUES
    (0, 'SDカード'),
    (1, 'CD-R'),
    (2, 'USB');

INSERT INTO
    sales_history (sale_date, item_no, quantity)
VALUES
    ('2020-01-01', 0, 4),
    ('2020-01-01', 1, 10),
    ('2020-01-03', 0, 4);

-- 確認
SELECT
    *
FROM
    sale_items;

SELECT
    *
FROM
    sales_history;

-- 商品ごとの売り上げ総計(あまり効率良くない)
SELECT
    sale_items.item,
    agg_sales.total_quantity
FROM
    sale_items
    LEFT OUTER JOIN (
        SELECT
            item_no,
            sum(quantity) AS total_quantity
        FROM
            sales_history
        GROUP BY
            item_no
    ) agg_sales ON sale_items.item_no = agg_sales.item_no;

-- 商品ごとの売り上げ総計(効率良い)
SELECT
    item,
    sum(quantity)
FROM
    sale_items
    LEFT OUTER JOIN sales_history ON sale_items.item_no = sales_history.item_no
GROUP BY
    sale_items.item_no;

-- class_1, class_2テーブル作成
CREATE TABLE class_1 (
    id serial PRIMARY KEY,
    name varchar (50) NOT NULL
);

CREATE TABLE class_2 (
    id serial PRIMARY KEY,
    name varchar (50) NOT NULL
);

INSERT INTO
    class_1 (id, name)
VALUES
    (0, 'hoge'),
    (1, 'fuga'),
    (2, 'piyo');

INSERT INTO
    class_2 (id, name)
VALUES
    (0, 'hoge'),
    (1, 'fuga'),
    (3, 'hogera');

-- 確認
SELECT
    *
FROM
    class_1;

SELECT
    *
FROM
    class_2;

-- full outer joinのテスト
SELECT
    coalesce(class_1.id, class_2.id) AS id,
    class_1.name AS name_1,
    class_2.name AS name_2
FROM
    class_1 FULL
    OUTER JOIN class_2 ON class_1.id = class_2.id;

-- class 1のみに存在する人
SELECT
    class_1.id,
    class_1.name
FROM
    class_1
    LEFT OUTER JOIN class_2 ON class_1.id = class_2.id
WHERE
    class_2.id IS NULL;

-- class 1のみに存在する人(not existを使うパターン)
SELECT
    *
FROM
    class_1
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            class_2
        WHERE
            class_1.id = class_2.id
    );

-- class 1のみに存在する人(not inを使うパターン)
SELECT
    *
FROM
    class_1
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            class_2
    );

-- class 1またはclass 2に存在するが、両方には存在しない人
SELECT
    coalesce(class_1.id, class_2.id),
    coalesce(class_1.name, class_2.name)
FROM
    class_1 FULL
    OUTER JOIN class_2 ON class_1.id = class_2.id
WHERE
    class_1.id IS NULL
    OR class_2.id IS NULL;

-- 演習問題
-- 8-1
SELECT
    ages.age_range,
    sexes.sex,
    sum(
        CASE
            WHEN pref_name IN ('秋田') THEN population
            ELSE 0
        END
    ) AS population_tohoku,
    sum(
        CASE
            WHEN pref_name IN ('東京', '千葉') THEN population
            ELSE 0
        END
    ) AS population_kanto
FROM
    ages
    CROSS JOIN sexes
    LEFT OUTER JOIN pref_populations ON ages.age_class = pref_populations.age_class
    AND sexes.sex_code = pref_populations.sex_code
GROUP BY
    ages.age_class,
    sexes.sex_code;

-- 8-2
SELECT
    p.employee_id,
    count(c.child)
FROM
    personnels p
    LEFT OUTER JOIN children c ON c.child IN (p.child_1, p.child_2)
GROUP BY
    employee_id;

-- 8-3
-- postgresではmerge機能なし