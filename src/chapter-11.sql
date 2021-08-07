-- sale_items, sales_historyテーブル確認
SELECT
    *
FROM
    sale_items;

SELECT
    *
FROM
    sales_history;

-- 売り上げのあった商品を抽出(join, distinctあり)
SELECT
    DISTINCT i.item_no
FROM
    sale_items i
    INNER JOIN sales_history h ON i.item_no = h.item_no;

-- 売り上げのあった商品を抽出(exists, distinctなし)
SELECT
    i.item_no
FROM
    sale_items i
WHERE
    EXISTS (
        SELECT
            *
        FROM
            sales_history h
        WHERE
            h.item_no = i.item_no
    );

-- 特定日の売り上げ(group by前に絞り込み)
SELECT
    sum(quantity)
FROM
    sales_history
WHERE
    sale_date = '2020-01-01'
GROUP BY
    sale_date;

-- 特定日の売り上げ(group by後に絞り込み)
SELECT
    sum(quantity)
FROM
    sales_history
GROUP BY
    sale_date
HAVING
    sale_date = '2020-01-01';

-- 売り上げ最大値が5以上の日の最大売り上げ
SELECT
    max(quantity)
FROM
    sales_history
GROUP BY
    sale_date
HAVING
    max(quantity) >= 5;