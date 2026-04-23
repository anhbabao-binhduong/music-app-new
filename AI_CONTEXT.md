# AI_CONTEXT.md

Tài liệu này giúp AI agent / người mới đọc code hiểu nhanh project **dựa trên code hiện có**.

## 1) Project là gì?

- Tên package: `music_app` (Flutter).
- Mô tả trong `pubspec.yaml`: “A modern cross-platform music player app.”
- Chức năng quan sát được từ code:
  - Phát nhạc (queue, next/prev/seek, shuffle, repeat) dùng `just_audio` + `audio_service`.
  - Xác thực bằng Supabase Auth (email/password + Google Sign-In).
  - Dữ liệu nhạc lấy từ Supabase table `songs` và Supabase Storage bucket `songs`.
  - Tính năng người dùng: favorites, downloads, listening history, playlists.
  - Bình luận theo bài hát.
  - Upload nhạc của user lên Supabase Storage (`user-audio`, `user-covers`) và lưu metadata vào table `user_songs` (trạng thái `pending`).
  - Admin/moderator stack: duyệt bài, quản lý user/comment, xem thống kê (RPC).

## 2) Tech stack (từ `pubspec.yaml`)

- Flutter / Dart SDK: Dart `>=3.0.0 <4.0.0`, Flutter `>=3.10.0`.
- State management: `flutter_bloc`, `equatable`.
- Dependency injection: `get_it`.
- Local storage/cache: `hive`, `hive_flutter`, `shared_preferences`.
- Backend: `supabase_flutter`, `google_sign_in`.
- Audio: `just_audio`, `audio_service`, `audio_session`, `just_audio_background`.
- Network: `dio`, `http`.
- UI/utilities: `cached_network_image`, `fl_chart`, `intl`, `shimmer`, `file_picker`, …
- Testing: `flutter_test`, `bloc_test`, `mocktail`.

## 3) Entry point & init order

File: `lib/main.dart`

Thứ tự khởi tạo quan trọng:

1. `HiveInitializer.init()` (mở box Hive và register adapters).
2. `Supabase.initialize(url, anonKey)` đọc từ `lib/core/config/supabase_config.dart`.
3. `setupServiceLocator()` trong `lib/core/di/service_locator.dart` (đăng ký DI và init audio service).
4. Load bài hát từ Supabase (`SongRepository.fetchSongsFromSupabase()` trong `lib/data/local_music_data.dart`).
5. Nếu đã đăng nhập và playlist không rỗng: `musicService.handler.updateQueue(supabasePlaylist)`.
6. Build song pool cho tìm kiếm (`SearchCubit.loadSongPool`).
7. Set global auth listener `_setupAuthListener()`:
   - `signedOut`: stop player, clear queue, reset player bloc, clear favorite/download/history local.
   - `signedIn/initialSession`: `HistoryCubit.reloadForUser()`.
8. `runApp(MyApp)` với `MultiRepositoryProvider` + `MultiBlocProvider`.

## 4) Điều phối màn hình đầu tiên

File: `lib/pages/root_page.dart`

- Nếu không có session: vào user stack (`HomePage`) — “guest mode”.
- Nếu có session: gọi `AdminCubit.loadCurrentRole()` đọc `profiles.role` để quyết định:
  - `admin/moderator` → `AdminStack`
  - còn lại → `HomePage`

Có xử lý lỗi `AuthException` (ví dụ PKCE “code verifier not found”): sign out và rơi về guest.

## 5) Các thành phần “xương sống”

### Audio
- `lib/services/music_player_service.dart`: init audio session + `AudioService.init`, expose API tiện dụng.
- `lib/services/audio_handler.dart`: `MyAudioHandler` nối `just_audio` với `audio_service`.
  - Quan trọng: audio URL lấy từ `MediaItem.extras['url']`. Nếu url trống/không http → fallback sample mp3.

### Supabase Auth
- `lib/services/supabase_auth_service.dart`:
  - Email/password sign in/up.
  - Google Sign-In:
    - Web: `signInWithOAuth` redirect.
    - Mobile: `GoogleSignIn(serverClientId: _webClientId)`.

### Data access
- `lib/data/repositories/music_repository_impl.dart`: mix local Hive (favorites/history/playlists/settings/cache) + Supabase (categories/songs/albums/charts).
- `lib/data/local_music_data.dart` (`SongRepository`): fetch songs từ Supabase table `songs` và resolve audio url từ bucket `songs`.
- `lib/data/repositories/comment_repository_impl.dart`: CRUD comments (và RPC lấy comment theo user).

### Playlist trên Supabase
- `lib/services/playlist_storage_service.dart`: thao tác playlists + playlist_songs (create/rename/delete/add/remove/reorder).

### Lyrics
- `lib/services/lyrics_service.dart`: gọi public API `https://lrclib.net/api` (get/search), parse LRC (synced lyrics) hoặc plain lyrics.

### Upload
- `lib/presentation/bloc/upload/upload_cubit.dart`:
  - File picker: audio + cover.
  - Upload cover → bucket `user-covers`.
  - Upload audio → bucket `user-audio`.
  - Insert row vào table `user_songs` với status `pending`.

### Admin
- `lib/presentation/bloc/admin/admin_cubit.dart`:
  - Load role (table `profiles`).
  - RPC: `get_admin_stats`.
  - Load `user_songs` join `profiles(...)`, list `profiles`, list `comments`.
  - Approve/reject song (update `user_songs.status`).
  - Ban/unban/change role (update `profiles`).
  - Delete comment.

## 6) Chỗ dễ “vấp” khi AI chỉnh code

- `SupabaseConfig` đang hard-code URL/anonKey trong repo (security + portability).
- EmailJS credentials đang hard-code trong `EmailJsService`.
- Google web client id đang hard-code trong `SupabaseAuthService`.
- Audio URL phụ thuộc `MediaItem.extras['url']`; khi mapping entity/model cần giữ đúng.

## 7) TODO để AI hiểu tốt hơn (không đoán)

- TODO: Mô tả rõ schema Supabase (types/constraints/RLS) — hiện chỉ suy ra từ code.
- TODO: Quy ước `songs.id` là `bigint` hay `uuid`? Trong code có chỗ assume numeric (`int.tryParse`).
- TODO: Liệt kê đầy đủ các Supabase RPC functions và signature (hiện chỉ thấy qua call site).
