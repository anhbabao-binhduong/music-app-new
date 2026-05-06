# 2026-05-06 — Fix Supabase History DB lỗi không cộng dồn

## Vấn đề
- Dù code app đã gửi đúng yêu cầu lưu history, Supabase không cộng dồn lượt nghe.
- Bài từ community songs lưu URL vào `song_id` thay vì ID dạng số như bình thường.

## Root Cause (Lỗi Data & DB)
1. **Supabase Constraint:** Bảng `listening_history` có constraint `UNIQUE (user_id, song_id)`. Điều này chặn việc insert 2 bản ghi cho cùng 1 bài hát của 1 user (nên play count luôn = 1).
2. **Community Songs ID:** Khi tạo `MediaItem` cho nhạc tải lên, `id` truyền vào là URL thay vì ID gốc (`song_id` số). Các truy vấn lấy top songs group by `song_id` bị lệch ID giữa nhạc hệ thống và nhạc người dùng.

## Fix
1. **Database:**
   - Drop constraint `listening_history_user_id_song_id_unique`.
   - Thêm index cho `user_id`, `song_id` và `played_at`.
2. **Flutter App (`HistoryCubit` & Tabs):**
   - Truyền thêm `songDbId` vào `MediaItem.extras` trong `chart_tab.dart` và `explore_tab.dart`.
   - Trong `HistoryCubit._saveToSupabase`: Ưu tiên đọc `extras['songDbId']` hoặc `extras['userSongId']` để làm `song_id` chuẩn khi insert vào bảng `listening_history`.

Kết quả: Supabase giờ sẽ insert 1 row mới mỗi lần nghe, giữ chuẩn ID để thống kê chính xác ở ZingChart.
