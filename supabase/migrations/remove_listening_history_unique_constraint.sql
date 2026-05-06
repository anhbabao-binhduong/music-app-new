-- Cho phép lưu nhiều lượt nghe cho cùng một user và cùng một bài hát
-- để #zingchart cộng dồn đúng số lần phát.
ALTER TABLE listening_history
DROP CONSTRAINT IF EXISTS listening_history_user_id_song_id_unique;