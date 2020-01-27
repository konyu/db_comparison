-- データベースはデフォルトのpostgresを使う
-- テーブルの作成
-- create foreign table
CREATE TABLE csv
(
    measurement_name TEXT,
    time BIGINT,
    date_time timestamp,
    date DATE,
    date2 TEXT,
    browser  TEXT,
    country  TEXT,
    field_one  INTEGER
 );

-- データのロード
-- ヘッダーファイルを見ないようにする

 COPY csv FROM '/home/imported_file.csv' WITH CSV HEADER;