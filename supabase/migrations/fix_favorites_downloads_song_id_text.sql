-- Đổi song_id từ bigint -> text để hỗ trợ cả regular song (numeric) và community song (UUID)
ALTER TABLE favorites ALTER COLUMN song_id TYPE text USING song_id::text;
ALTER TABLE downloads ALTER COLUMN song_id TYPE text USING song_id::text;