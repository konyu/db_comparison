
普通のPostgresに接続
```
>  psql -U postgres -h localhost -p 5432
psql (11.5, server 12.1 (Debian 12.1-1.pgdg100+1))
WARNING: psql major version 11, server major version 12.
         Some psql features might not work.
Type "help" for help.

# テーブル作成
CREATE TABLE customer_reviews
(
    customer_id TEXT,
    review_date DATE,
    review_rating INTEGER,
    review_votes INTEGER,
    review_helpful_votes INTEGER,
    product_id CHAR(10),
    product_title TEXT,
    product_sales_rank BIGINT,
    product_group TEXT,
    product_category TEXT,
    product_subcategory TEXT,
    similar_product_ids CHAR(10)[]
)
```

列指向のPostgresに接続
```
~ » psql -U postgres -h localhost -p 54320
psql (11.5, server 10.3 (Debian 10.3-1.pgdg90+1))
Type "help" for help.

# テーブル作成
-- load extension first time after install
CREATE EXTENSION cstore_fdw;

-- create server object
CREATE SERVER cstore_server FOREIGN DATA WRAPPER cstore_fdw;

-- create foreign table
CREATE FOREIGN TABLE customer_reviews
(
    customer_id TEXT,
    review_date DATE,
    review_rating INTEGER,
    review_votes INTEGER,
    review_helpful_votes INTEGER,
    product_id CHAR(10),
    product_title TEXT,
    product_sales_rank BIGINT,
    product_group TEXT,
    product_category TEXT,
    product_subcategory TEXT,
    similar_product_ids CHAR(10)[]
)
SERVER cstore_server
OPTIONS(compression 'pglz');
```

ファイルのコピー
```
basic/db_comparison » docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED             STATUS              PORTS                       NAMES
15566c86002e        theikkila/analytics-postgresql   "docker-entrypoint.s…"   24 minutes ago      Up 24 minutes       127.0.0.1:54320->5432/tcp   db_comparison_postgresql_1
a035e623ce52        postgres                         "docker-entrypoint.s…"   25 minutes ago      Up 24 minutes       127.0.0.1:5432->5432/tcp    db_comparison_db_1
basic/db_comparison » docker exec -i 15566c86002e  /bin/bash -c "cat > customer_reviews_1999.csv" < customer_reviews_1999.csv
basic/db_comparison » docker-compose exec postgresql  /bin/bash -c "pwd"
/
basic/db_comparison » docker-compose exec postgresql  /bin/bash -c "ls"
bin			   docker-entrypoint-initdb.d  lib    opt   sbin  usr
boot			   docker-entrypoint.sh        lib64  proc  srv   var
customer_reviews_1999.csv  etc			       media  root  sys
dev			   home			       mnt    run   tmp
```

ファイルをもう一個
```
basic/db_comparison » docker exec -i 15566c86002e  /bin/bash -c "cat > customer_reviews_1998.csv" < customer_reviews_1998.csv
```

PSQLからデータ確認


列指向
```
basic/db_comparison » psql -U postgres -h localhost -p 54320
psql (11.5, server 10.3 (Debian 10.3-1.pgdg90+1))
Type "help" for help.

postgres=# COPY customer_reviews FROM '/customer_reviews_1998.csv' WITH CSV;
COPY 589859
postgres=# COPY customer_reviews FROM '/customer_reviews_1999.csv' WITH CSV;
COPY 1172645

postgres=# select * from customer_reviews limit 2;
  customer_id  | review_date | review_rating | review_votes | review_helpful_votes | product_id |
---------------+-------------+---------------+--------------+----------------------+------------+
 AE22YDHSBFYIP | 1970-12-30  |             5 |           10 |                    0 | 1551803542 |
 AE22YDHSBFYIP | 1970-12-30  |             5 |            9 |                    0 | 1551802538 |
```

```
#SQL 計測時間を表示する
postgres=# \timing
Timing is on.

postgres=# SELECT
    width_bucket(length(product_title), 1, 50, 5) title_length_bucket,
    round(avg(review_rating), 2) AS review_average,
    count(*)
FROM
   customer_reviews
WHERE
    product_group = 'Book'
GROUP BY
    title_length_bucket
ORDER BY
    title_length_bucket;
 title_length_bucket | review_average | count
---------------------+----------------+--------
                   1 |           4.26 | 139034
                   2 |           4.24 | 411318
                   3 |           4.34 | 245671
                   4 |           4.32 | 167361
                   5 |           4.30 | 118422
                   6 |           4.40 | 116412
(6 rows)

Time: 427.192 ms


```

週毎の集計の例
```
SELECT review_date - INTERVAL '1 day' * date_part('dow', review_date) AS week,
       COUNT(DISTINCT customer_id) AS wau
FROM customer_reviews
GROUP BY week

Time: 1914.318 ms (00:01.914)


# ソートをつけると遅くなるはずと思ったけど、あまり変わらない
# これはもともとグルーピングしている時点でほぼソートされているからかもしれない
SELECT review_date - INTERVAL '1 day' * date_part('dow', review_date) AS week,
       COUNT(DISTINCT customer_id) AS wau
FROM customer_reviews
GROUP BY week
ORDER BY week desc

Time: 1624.327 ms (00:01.624)

```

列指向 Postgres11の場合
```
SELECT
    width_bucket(length(product_title), 1, 50, 5) title_length_bucket,
    round(avg(review_rating), 2) AS review_average,
    count(*)
FROM
   customer_reviews
WHERE
    product_group = 'Book'
GROUP BY
    title_length_bucket
ORDER BY
    title_length_bucket;
 title_length_bucket | review_average | count
---------------------+----------------+--------
                   1 |           4.26 | 139034
                   2 |           4.24 | 411318
                   3 |           4.34 | 245671
                   4 |           4.32 | 167361
                   5 |           4.30 | 118422
                   6 |           4.40 | 116412
(6 rows)

Time: 463.851 ms


SELECT
    width_bucket(length(product_title), 1, 50, 5) title_length_bucket
FROM
   customer_reviews
WHERE
    product_group = 'Book'
GROUP BY
    title_length_bucket
ORDER BY
    title_length_bucket;

SELECT review_date - INTERVAL '1 day' * date_part('dow', review_date) AS week,
       COUNT(DISTINCT customer_id) AS wau
FROM customer_reviews
GROUP BY week
ORDER BY week desc

Time: 1658.469 ms (00:01.658)
```


行指向の普通のDB Postgres12の場合
```
basic/db_comparison » psql -U postgres -h localhost -p 5432
psql (11.5, server 10.3 (Debian 10.3-1.pgdg90+1))
Type "help" for help.

postgres=# COPY customer_reviews FROM '/customer_reviews_1998.csv' WITH CSV;
COPY 589859
postgres=# COPY customer_reviews FROM '/customer_reviews_1999.csv' WITH CSV;
COPY 1172645

postgres=# select * from customer_reviews limit 2;
  customer_id  | review_date | review_rating | review_votes | review_helpful_votes | product_id |
---------------+-------------+---------------+--------------+----------------------+------------+
 AE22YDHSBFYIP | 1970-12-30  |             5 |           10 |                    0 | 1551803542 |
 AE22YDHSBFYIP | 1970-12-30  |             5 |            9 |                    0 | 1551802538 |
```

```
#SQL 計測時間を表示する
postgres=# \timing
Timing is on.

postgres=# SELECT
    width_bucket(length(product_title), 1, 50, 5) title_length_bucket,
    round(avg(review_rating), 2) AS review_average,
    count(*)
FROM
   customer_reviews
WHERE
    product_group = 'Book'
GROUP BY
    title_length_bucket
ORDER BY
    title_length_bucket;

 title_length_bucket | review_average | count
---------------------+----------------+--------
                   1 |           4.26 | 139034
                   2 |           4.24 | 411318
                   3 |           4.34 | 245671
                   4 |           4.32 | 167361
                   5 |           4.30 | 118422
                   6 |           4.40 | 116412
(6 rows)

Time: 305.361 ms

```

週毎の集計の例
```
SELECT review_date - INTERVAL '1 day' * date_part('dow', review_date) AS week,
       COUNT(DISTINCT customer_id) AS wau
FROM customer_reviews
GROUP BY week

Time: 1672.241 ms (00:01.672)


# ソートをつけると遅くなるはずと思ったけど、あまり変わらない
# これはもともとグルーピングしている時点でほぼソートされているからかもしれない
SELECT review_date - INTERVAL '1 day' * date_part('dow', review_date) AS week,
       COUNT(DISTINCT customer_id) AS wau
FROM customer_reviews
GROUP BY week
ORDER BY week desc;

Time: 1704.129 ms (00:01.704)

```

行指向 Postgres11 の場合

```
basic/db_comparison » psql -U postgres -h localhost -p 54322

postgres=# COPY customer_reviews FROM '/customer_reviews_1998.csv' WITH CSV;
COPY 589859
postgres=# COPY customer_reviews FROM '/customer_reviews_1999.csv' WITH CSV;
COPY 1172645

postgres=# select * from customer_reviews limit 2;
  customer_id  | review_date | review_rating | review_votes | review_helpful_votes | product_id |
---------------+-------------+---------------+--------------+----------------------+------------+
 AE22YDHSBFYIP | 1970-12-30  |             5 |           10 |                    0 | 1551803542 |
 AE22YDHSBFYIP | 1970-12-30  |             5 |            9 |                    0 | 1551802538 |
```

```
#SQL 計測時間を表示する
postgres=# \timing
Timing is on.

postgres=# SELECT
    width_bucket(length(product_title), 1, 50, 5) title_length_bucket,
    round(avg(review_rating), 2) AS review_average,
    count(*)
FROM
   customer_reviews
WHERE
    product_group = 'Book'
GROUP BY
    title_length_bucket
ORDER BY
    title_length_bucket;

 title_length_bucket | review_average | count
---------------------+----------------+--------
                   1 |           4.26 | 139034
                   2 |           4.24 | 411318
                   3 |           4.34 | 245671
                   4 |           4.32 | 167361
                   5 |           4.30 | 118422
                   6 |           4.40 | 116412
(6 rows)

Time: 499.479 ms

```

週毎の集計の例
```
SELECT review_date - INTERVAL '1 day' * date_part('dow', review_date) AS week,
       COUNT(DISTINCT customer_id) AS wau
FROM customer_reviews
GROUP BY week

Time: 1805.251 ms (00:01.805)
```