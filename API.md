# API.md

Tài liệu này **không phải schema chính thức**, mà là phần suy ra trực tiếp từ code hiện có.

## 1) Supabase tables được thấy trong code

### `songs`
Được truy cập ở:
- `lib/data/local_music_data.dart`
- `lib/data/repositories/music_repository_impl.dart`

Các field thấy rõ trong code:
- `id`
- `title`
- `artist`
- `album`
- `art_url`
- `audio_path`
- `duration_seconds`

Ghi chú:
- Audio path được resolve thành public URL qua bucket `songs` nếu không phải URL tuyệt đối.
- `id` thường được convert sang string ở app layer.

### `categories`
Được truy cập ở:
- `MusicRepositoryImpl.getCategories()`
- `MusicRepositoryImpl.getSongsByCategory()`

Các field thấy trong code:
- `id`
- `slug`
- `display_order`
- TODO: Các field khác của category model chưa liệt kê đầy đủ trong tài liệu này.

### `song_categories`
Bảng trung gian category ↔ song.

Các field thấy trong code:
- `category_id`
- `song_id`

### `albums`
Được truy cập ở `MusicRepositoryImpl.getAlbums()` và `getAlbumById()`.

Join relation thấy trong query:
- `album_songs(song_id, track_number)`

Field trực tiếp của `albums`:
- TODO: Chưa xác nhận đầy đủ từ code đã đọc.

### `album_songs`
Bảng trung gian album ↔ song.

Field thấy trong code:
- `song_id`
- `track_number`
- TODO: Có thể còn `album_id` nhưng ở query relation không hiện trực tiếp field list.

### `comments`
Được truy cập ở:
- `CommentRepositoryImpl`
- `AdminCubit`

Field thấy trong code:
- `id`
- `song_id`
- `user_id`
- `display_name`
- `content`
- `created_at`

Admin load comment dùng:
- `.from('comments').select().order('created_at', ascending: false).limit(100)`

### `profiles`
Được truy cập ở:
- `RootPage` / `AdminCubit.loadCurrentRole()`
- admin screens/cubit
- join với `user_songs`

Field thấy trong code:
- `id`
- `role`
- `name`
- `email`
- `avatar_url`
- `created_at`
- `is_banned`
- `banned_at`
- `ban_reason`

### `user_songs`
Được truy cập ở:
- `UploadCubit`
- `UserSongsCubit`
- `AdminCubit`

Field thấy trong code:
- `id`
- `user_id`
- `title`
- `artist`
- `album`
- `audio_url`
- `art_url`
- `file_size`
- `status`
- `reject_reason`
- `created_at`
- `updated_at`
- TODO: `duration_ms` có xuất hiện trong model admin, nhưng chưa thấy insert trong `UploadCubit`.

### `favorites`
Được truy cập ở `FavoriteCubit`.

Field thấy trong code:
- `user_id`
- `song_id`
- `created_at` (dùng để order)

### `downloads`
Được truy cập ở `DownloadCubit`.

Field thấy trong code:
- `user_id`
- `song_id`
- TODO: Chưa đọc full file nên chưa xác nhận thêm field khác.

### `listening_history`
Được truy cập ở `HistoryCubit`.

Field thấy trong code:
- `user_id`
- `song_id`
- `song_title`
- `song_artist`
- `song_art_uri`
- `song_duration_ms`
- `song_extras`
- `played_at`

Ghi chú:
- Upsert dùng `onConflict: 'user_id,song_id'`.
- App chỉ lưu tối đa 50 mục gần nhất ở UI state/local sync.

### `playlists`
Được truy cập ở `PlaylistStorageService`.

Field thấy trong code:
- `id`
- `user_id`
- `name`
- `name_lower`
- `cover_art_url`
- `visibility`
- `created_at`
- `updated_at`

### `playlist_songs`
Được truy cập ở `PlaylistStorageService`.

Field thấy trong code:
- `id`
- `playlist_id`
- `song_id`
- `position`

## 2) Supabase Storage buckets thấy trong code

- `songs`
  - Dùng để lấy public URL cho audio official songs.
- `user-audio`
  - Dùng cho audio user upload.
- `user-covers`
  - Dùng cho cover image user upload.

## 3) Supabase RPC functions thấy trong code

### `get_chart_top_songs`
Được gọi ở `MusicRepositoryImpl.getChartTopSongs(int daysAgo)`.

Params thấy trong code:
- `days_ago`

Return payload suy ra từ code:
- `song_id`
- `play_count`
- có thể gồm thêm:
  - `song_title`
  - `song_artist`
  - `song_art_uri`
  - `song_duration_ms`
  - `song_extras`

### `get_chart_trends`
Được gọi ở `MusicRepositoryImpl.getChartTrends(int daysAgo, List<String> songIds)`.

Params thấy trong code:
- `days_ago`
- `song_ids_csv`

Return payload suy ra:
- `song_id`
- `play_date`
- `play_count`

### `get_user_comments_with_songs`
Được gọi ở `CommentRepositoryImpl.getUserComments(String userId)`.

Params thấy trong code:
- `p_user_id`

Return payload suy ra:
- `id`
- `song_id`
- `user_id`
- `display_name`
- `content`
- `created_at`
- `song_title`
- `song_artist`
- `song_art_url`

### `get_admin_stats`
Được gọi ở `AdminCubit.loadAll()`.

Params:
- Không thấy params trong code call.

Return payload suy ra từ `AdminStats.fromJson(...)` usage:
- TODO: Cần đọc model/state để xác nhận field chính xác.
- Từ state update trong code, nhiều khả năng có:
  - `totalUsers`
  - `totalSongs`
  - `pendingSongs`
  - `approvedSongs`
  - `rejectedSongs`
  - `totalPlays`
  - `totalComments`

## 4) External HTTP APIs thấy trong code

### Lyrics API
- Base URL: `https://lrclib.net/api`
- Endpoints dùng:
  - `GET /get?artist_name=...&track_name=...`
  - `GET /search?q=...`

### EmailJS API
- URL: `https://api.emailjs.com/api/v1.0/email/send`
- Dùng để gửi OTP qua email.

## 5) Auth providers

Trong code thấy:
- Email/password auth qua Supabase Auth
- Google OAuth / Google Sign-In

## 6) Điều còn thiếu để tài liệu API đầy đủ hơn

- TODO: Export schema chính thức từ Supabase.
- TODO: Tài liệu RLS policies cho từng table/bucket.
- TODO: Signature chính xác của RPC và JSON sample responses.
- TODO: Mapping đầy đủ model fields cho `albums`, `categories`, `downloads`.
