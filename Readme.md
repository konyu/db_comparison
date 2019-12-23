
## はじめに
DBMSの得意不得意、特にデータ分析に使うビッグデータの取り扱いについてパフォーマンス測定した。

## 比較対象DBMS

比較対象にしたDBMSはそれぞれ

* PostgreSQLやMySQLに代表されるリレーショナルデータベース(RDB)
    * PostgreSQL12を使用
* Redshiftに代表される列指向DB
    * PostgreSQL11に列指向DBにするプラグインcstore_fdwを適用したもの
* InfluxDBに代表される時系列DB
    * Go言語製の時系列DB InfluxDB


## 比較調査内容
### パフォーマンス測定1 RDBと列指向DBの比較
100万行ほどのデータ(200MBほどのCSV)

### パフォーマンス測定2 RDBと列指向DBの比較
800万行ほどのデータ(5GBほどのCSV)

### TODO 時系列DBとの比較
InfluxDBをdockerで動かしデータ挿入するところまでは完了している
データ分析対象になるデータを用意してInfluxDBに挿入するところがまだできていない


## パフォーマンス測定1 RDBと列指向DBの比較
100万行ほどのデータ(200MBほどのCSV)

### データ取得元
cstore_fdwのGithubにあるReadmeより
https://github.com/citusdata/cstore_fdw/blob/master/README.md

データサンプル

```
customer_id, review_date,review_rating, review_votes, review_helpful_votes, product_id,vproduct_title, product_sales_rank,vproduct_group , product_category, product_subcategory, similar_product_ids
AE22YDHSBFYIP,1970-12-30,5,10,0,1551803542,"Start and Run a Coffee Bar (Start & Run a)",11611,Book,"Business & Investing","General","{0471136174,0910627312,047112138X,0786883561,0201570483}"
AE22YDHSBFYIP,1970-12-30,5,9,0,1551802538,"Start and Run a Profitable Coffee Bar",689262,Book,"Business & Investing","General","{0471136174,0910627312,047112138X,0786883561,0201570483}"
```

### 集計SQL1

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
```

### 集計SQL2
1週間毎にまとめたデータ

```
SELECT review_date - INTERVAL '1 day' * date_part('dow', review_date) AS week,
       COUNT(DISTINCT customer_id) AS wau
FROM customer_reviews
GROUP BY week
ORDER BY week desc
```

### 結果 
DB種別|集計SQL1 | 集計SQL2
-|-|-
列指向 Postgres11の場合 | Time: 463.851 ms | Time: 1658.469 ms
行指向の普通のDB Postgres12の場合| Time: 305.361 ms | Time: 1672.241 ms

100万件程度のデータの場合は、行指向のRDBも列指向のDBもパフォーマンス大きな差がない。むしろPostgreSQLのバージョンが最新の12のパフォーマンスが良い。
特にインデックスを貼っていない状態でも速度的に問題なさそうである。


### パフォーマンス測定2 RDBと列指向DBの比較
800万行ほどのデータ(5GBほどのCSV)


### データ取得元
Kaggleの適当に大きなデータセットより
https://www.kaggle.com/azathoth42/myanimelist

データサンプル

```
username,anime_id,my_watched_episodes,my_start_date,my_finish_date,my_score,my_status,my_rewatching,my_rewatching_ep,my_last_updated,my_tags
karthiga,21,586,0000-00-00,0000-00-00,9,1,,0,1362307973,
karthiga,59,26,0000-00-00,0000-00-00,7,2,,0,1362923691,
```


### 集計SQL1

```
SELECT
    my_status,
   sum(my_score)
FROM
   user_anime_list
GROUP BY
    my_status;

```


### 結果 
DB種別|集計SQL1
-|-
列指向 Postgres11の場合 | Time: 9974.595 ms 
行指向の普通のDB Postgres12の場合| Time: 29186.852 ms 

800万件程度の場合、列指向と行指向で大きな差が出た。
また対象のレコードでIndexを適切に貼った場合はまた違う結果になるだろうが、
本質的に集計・データ分析用のSQL用にインデックスをむやみに貼るべきではない。

このように様々な角度で分析するような場合は列指向DBが優れている


# TODO 項目
* 列指向、行指向、時系列DBに挿入するデータを作成する
* 対象の比較ができるように予め加工したデータを用いて比較する
    * 年、月、週次のデータを文字列でもたせる
    * 日のデータの形式はDate型が良いのか文字列で持つべきか
    * 時系列DBのクエリで、セカンダリディメンションで検索できるか


以下試行錯誤のログ

----------------

列指向のDB　PostgresSQL11 列指向

対象がすべてのレコード800万レコードの場合
postgres=# SELECT
    my_status,
   sum(my_score)
FROM
   user_anime_list
GROUP BY
    my_status;
 my_status |    sum
-----------+-----------
         0 |       693
         1 |  10125113
         2 | 321110361
         3 |   6839605
         4 |   7457074
         5 |         7
         6 |   1870173
        33 |         5
        55 |         0
(9 rows)

Time: 9974.595 ms (00:09.975)
postgres=#


---------------------------

行指向DB　PostgresSQL11
postgres=# SELECT
    my_status,
   sum(my_score)
FROM
   user_anime_list
GROUP BY
    my_status;
 my_status |    sum
-----------+-----------
         0 |       693
         1 |  10125113
         2 | 321110361
         3 |   6839605
         4 |   7457074
         5 |         7
         6 |   1870173
        33 |         5
        55 |         0
(9 rows)

Time: 10009.746 ms (00:10.010)

-----------------------------

行指向DB　PostgreSQL12
postgres=# SELECT
postgres-#     my_status,
postgres-#    sum(my_score)
postgres-# FROM
postgres-#    user_anime_list
postgres-# GROUP BY
postgres-#     my_status;
 my_status |    sum
-----------+-----------
         0 |       693
         1 |  10125113
         2 | 321110361
         3 |   6839605
         4 |   7457074
         5 |         7
         6 |   1870173
        33 |         5
        55 |         0
(9 rows)

Time: 29186.852 ms (00:29.187)

# レコード挿入された場所が後ろの人にWhere句で絞った場合どうなるか？
---------
SELECT
my_status,
sum(my_score)
FROM
user_anime_list
where username = 'DittoGang'
GROUP BY
my_status;

------------------------

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