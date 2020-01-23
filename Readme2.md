### 参考: 時系列DBのクエリ
1日単位
SELECT sum("field_one") FROM "measurement_like_table" WHERE time > '2020-01-01T00:00:00Z' and time < '2020-01-10T23:59:59Z' GROUP BY time(1d) fill(null)

181.589ms

### 1時間単位
SELECT sum(\"field_one\") FROM \"measurement_like_table\" WHERE time > '2020-01-01T00:00:00Z' and time < '2020-01-10T23:59:59Z' GROUP BY time(1h), \"country\" fill(none)

105201ns
105.201ms

## 列指向のPostgresにテーブルを作成して、CSVデータを挿入

psql -f home/column_init_same_influxdb.sql -U postgres -h localhost -p 54321


## 行指向普通のPostgresにテーブルを作成して、CSCデータを挿入

psql -f home/column_init_same_influxdb.sql -U postgres -h localhost -p 5432


-----
## 列指向DBでの操作

### 列指向DBにアクセスする

```
psql -U postgres -h localhost -p 54321
```


### 列指向
```
#SQL 計測時間を表示する
\timing
Timing is on.
```

DATETIME型のもの（日付で丸めていない）
```
SELECT
    day :: date,
    country,
    SUM(field_one)
FROM
   csv, date_trunc('day', date_time) as day
WHERE
    time > 1577836800000 and time < 1578700799000
group by 1, country
order by 1, country;

Time: 49.387 ms
```


DATETIME型の型で同じ日付の00:00:00にまるめているもの
```
SELECT
    day :: date,
    country,
    SUM(field_one)
FROM
   csv, date_trunc('day', date) as day
WHERE
    time > 1577836800000 and time < 1578700799000
group by 1, country
order by 1, country

Time: 28.344 ms
```


DATETIME型の型で同じ日付の00:00:00にまるめているもので
date_trunc関数で丸め処理をしていない場合
```
SELECT
    date,
    country,
    SUM(field_one)
FROM
   csv
WHERE
    time > 1577836800000 and time < 1578700799000
group by date, country
order by date, country

Time: 23.006 ms
```



文字列型の日付の文字列が入っているもの
文字列の日付で集計している(例: "2020-01-01")

```
SELECT
    date2,
    country,
    SUM(field_one)
FROM
   csv
WHERE
    time > 1577836800000 and time < 1578700799000
group by date2, country
order by date2, country

Time: 9.002 ms
```

# 行指向のDB Postgres12の場合
```
#SQL 計測時間を表示する
\timing
Timing is on.
```

DATETIME型のもの（日付で丸めていない）
```
SELECT
    day :: date,
    country,
    SUM(field_one)
FROM
   csv, date_trunc('day', date_time) as day
WHERE
    time > 1577836800000 and time < 1578700799000
group by 1, country
order by 1, country;


Time: 306.398 ms
Time: 163.902 ms
```


DATETIME型の型で同じ日付の00:00:00にまるめているもの
```
SELECT
    day :: date,
    country,
    SUM(field_one)
FROM
   csv, date_trunc('day', date) as day
WHERE
    time > 1577836800000 and time < 1578700799000
group by 1, country
order by 1, country;

Time: 67.488 ms
```


DATETIME型の型で同じ日付の00:00:00にまるめているもので
date_trunc関数で丸め処理をしていない場合

```
SELECT
    date,
    country,
    SUM(field_one)
FROM
   csv
WHERE
    time > 1577836800000 and time < 1578700799000
group by date, country
order by date, country;

Time: 35.242 ms
```

文字列型の日付の文字列が入っているもの
文字列の日付で集計している(例: "2020-01-01")

```
SELECT
    date2,
    country,
    SUM(field_one)
FROM
   csv
WHERE
    time > 1577836800000 and time < 1578700799000
group by date2, country
order by date2, country;

Time: 42.970 ms
```