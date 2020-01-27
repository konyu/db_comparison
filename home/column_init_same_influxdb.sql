-- データベースはデフォルトのpostgresを使う
-- テーブルの作成
-- load extension first time after install
CREATE EXTENSION cstore_fdw;

-- create server object
CREATE SERVER cstore_server FOREIGN DATA WRAPPER cstore_fdw;

-- create foreign table
CREATE FOREIGN TABLE csv
(
    measurement_name TEXT,
    time BIGINT,
    date_time timestamp,
    date DATE,
    date2 TEXT,
    browser  TEXT,
    country  TEXT,
    field_one  INTEGER
)
SERVER cstore_server
OPTIONS(compression 'pglz');
-- データのロード
-- ヘッダーファイルを見ないようにする


 COPY csv FROM '/home/imported_file.csv' WITH CSV HEADER;