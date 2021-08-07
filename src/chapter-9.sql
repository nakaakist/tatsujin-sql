-- a, b, diff_bを作成
CREATE TABLE a (id serial PRIMARY KEY);

CREATE TABLE b (id serial PRIMARY KEY);

CREATE TABLE diff_b (id serial PRIMARY KEY);

INSERT INTO
    a (id)
VALUES
    (0),
    (1),
    (2);

INSERT INTO
    b (id)
VALUES
    (0),
    (1),
    (2);

INSERT INTO
    diff_b (id)
VALUES
    (1),
    (3);

-- 確認
SELECT
    *
FROM
    a;

SELECT
    *
FROM
    b;

SELECT
    *
FROM
    diff_b;

-- テーブルが同じかどうか
SELECT
    CASE
        WHEN count(*) = 0 THEN '等しい'
        ELSE '異なる'
    END
FROM
    (
        (
            SELECT
                *
            FROM
                a
            UNION
            SELECT
                *
            FROM
                b
        )
        EXCEPT
            (
                SELECT
                    *
                FROM
                    a
                INTERSECT
                SELECT
                    *
                FROM
                    b
            )
    ) tmp;

SELECT
    CASE
        WHEN count(*) = 0 THEN '等しい'
        ELSE '異なる'
    END
FROM
    (
        (
            SELECT
                *
            FROM
                a
            UNION
            SELECT
                *
            FROM
                diff_b
        )
        EXCEPT
            (
                SELECT
                    *
                FROM
                    a
                INTERSECT
                SELECT
                    *
                FROM
                    diff_b
            )
    ) tmp;

-- 排他的和集合
(
    (
        SELECT
            *
        FROM
            a
    )
    EXCEPT
        (
            SELECT
                *
            FROM
                diff_b
        )
)
UNION
ALL (
    (
        SELECT
            *
        FROM
            diff_b
    )
    EXCEPT
        (
            SELECT
                *
            FROM
                a
        )
);

-- skills, employee_skillsテーブル作成
CREATE TABLE skills (skill varchar (50) PRIMARY KEY);

CREATE TABLE employee_skills (
    employee_id serial,
    skill varchar(50),
    PRIMARY KEY (employee_id, skill)
);

INSERT INTO
    skills (skill)
VALUES
    ('oracle'),
    ('unix'),
    ('java');

INSERT INTO
    employee_skills (employee_id, skill)
VALUES
    (0, 'oracle'),
    (0, 'unix'),
    (0, 'c#'),
    (1, 'oracle'),
    (1, 'unix'),
    (1, 'java'),
    (2, 'oracle'),
    (2, 'c++'),
    (3, 'oracle'),
    (3, 'unix'),
    (3, 'java'),
    (3, 'c++');

-- 確認
SELECT
    *
FROM
    skills;

SELECT
    *
FROM
    employee_skills;

-- skillsテーブルに保存された全てのスキルを持つ従業員(having)
SELECT
    employee_id
FROM
    employee_skills
    INNER JOIN skills ON employee_skills.skill = skills.skill
GROUP BY
    employee_id
HAVING
    count(*) = (
        SELECT
            count(*)
        FROM
            skills
    );

-- skillsテーブルに保存された全てのスキルを持つ従業員(集合演算)
SELECT
    DISTINCT employee_id
FROM
    employee_skills e1
WHERE
    NOT EXISTS (
        SELECT
            skill
        FROM
            skills
        EXCEPT
        SELECT
            skill
        FROM
            employee_skills e2
        WHERE
            e1.employee_id = e2.employee_id
    );

-- supplier_partsテーブル作成
CREATE TABLE supplier_parts (
    supplier char(1),
    part varchar(50),
    PRIMARY KEY(supplier, part)
);

INSERT INTO
    supplier_parts (supplier, part)
VALUES
    ('A', 'volt'),
    ('A', 'nut'),
    ('A', 'pipe'),
    ('B', 'volt'),
    ('B', 'pipe'),
    ('C', 'volt'),
    ('C', 'nut'),
    ('C', 'pipe'),
    ('D', 'volt'),
    ('D', 'pipe'),
    ('E', 'fuse');

-- 確認
SELECT
    *
FROM
    supplier_parts;

-- 数も種類も全く同じ部品を扱う業者のペア
SELECT
    s1.supplier AS supplier_1,
    s2.supplier AS supplier_2
FROM
    supplier_parts s1
    CROSS JOIN supplier_parts s2
WHERE
    s1.supplier < s2.supplier
    AND s1.part = s2.part
GROUP BY
    s1.supplier,
    s2.supplier
HAVING
    count(*) = (
        SELECT
            count (*)
        FROM
            supplier_parts s3
        WHERE
            s3.supplier = s1.supplier
    )
    AND count(*) = (
        SELECT
            count (*)
        FROM
            supplier_parts s3
        WHERE
            s3.supplier = s2.supplier
    );

-- 演習問題
-- 9-1
SELECT
    CASE
        WHEN count(*) <> (
            SELECT
                count(*)
            FROM
                b
        ) THEN '異なる'
        WHEN count(*) <> (
            SELECT
                count(*)
            FROM
                (
                    SELECT
                        *
                    FROM
                        a
                    UNION
                    SELECT
                        *
                    FROM
                        b
                ) tmp
        ) THEN '異なる'
        ELSE '同じ'
    END
FROM
    a;

-- 9-2
SELECT
    DISTINCT employee_id
FROM
    employee_skills e1
WHERE
    NOT EXISTS (
        SELECT
            skill
        FROM
            skills
        EXCEPT
        SELECT
            skill
        FROM
            employee_skills e2
        WHERE
            e1.employee_id = e2.employee_id
    )
    AND NOT EXISTS (
        SELECT
            skill
        FROM
            employee_skills e2
        WHERE
            e1.employee_id = e2.employee_id
        EXCEPT
        SELECT
            skill
        FROM
            skills
    );