-- データベースはデフォルトのpostgresを使う
-- テーブルの作成
-- load extension first time after install
CREATE EXTENSION cstore_fdw;

-- create server object
CREATE SERVER cstore_server FOREIGN DATA WRAPPER cstore_fdw;

-- create foreign table
CREATE FOREIGN TABLE user_anime_list
(
    username TEXT,
    anime_id TEXT,
    my_watched_episodes INTEGER,
    my_start_date TEXT,
    my_finish_date TEXT,
    my_score INTEGER,
    my_status  INTEGER,
    my_rewatching  INTEGER,
    my_rewatching_ep  INTEGER,
    my_last_updated BIGINT,
    my_tags TEXT
)
SERVER cstore_server
OPTIONS(compression 'pglz');
-- データのロード
-- ヘッダーファイルを見ないようにする


 COPY user_anime_list FROM '/home/UserAnimeList.csv' WITH CSV HEADER;