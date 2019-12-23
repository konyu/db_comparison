-- データベースはデフォルトのpostgresを使う
-- テーブルの作成
-- create foreign table
CREATE TABLE user_anime_list
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
 );

-- データのロード
-- ヘッダーファイルを見ないようにする

 COPY user_anime_list FROM '/home/UserAnimeList.csv' WITH CSV HEADER;