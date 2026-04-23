# docs/architecture.md

Tài liệu kiến trúc **dựa trên code hiện có** trong repo.

## 1) Tổng quan

Project là một Flutter app theo hướng chia lớp (layered) và theo feature (Bloc/Cubit theo từng module).

Các nguồn dữ liệu chính:

- **Supabase**: Auth, Database (Postgres), Storage, RPC.
- **Hive**: local cache (favorites/history/playlists/albums/settings).

## 2) High-level diagram (logic)

- UI (`pages/`, `widgets/`) → gọi Bloc/Cubit (`presentation/bloc/`)
- Bloc/Cubit → gọi repository/service
- Repository/Service → Supabase/Hive/HTTP

Audio là “cross-cutting service” chạy xuyên suốt app (queue, state stream).

## 3) Init & Dependency Injection

### 3.1 Entry point

- `lib/main.dart` thực hiện:
  1. `HiveInitializer.init()`
  2. `Supabase.initialize(url, anonKey)`
  3. `setupServiceLocator()`
  4. Fetch bài hát `SongRepository.fetchSongsFromSupabase()` và nạp queue
  5. Lắng nghe `auth.onAuthStateChange`
  6. `runApp()` + register Bloc/Cubit trong widget tree

### 3.2 Service locator (`get_it`)

- File: `lib/core/di/service_locator.dart`
- Các đăng ký quan trọng:
  - `SupabaseClient`: lazy singleton từ `Supabase.instance.client`
  - `MusicPlayerService`: singleton (có `init()` async) + expose `AudioHandler`
  - `MusicRepository`: lazy singleton → `MusicRepositoryImpl(supabaseClient: ...)`
  - Use cases: `GetCategoriesUseCase`, `GetSongsByCategoryUseCase`, `GetAlbumsUsecase`
  - Cubit/Bloc: `HistoryCubit` (lazy singleton), `PlayerBloc`, `ThemeBloc`, `FavoriteCubit`, `DownloadCubit`, `PlaylistCubit`, `CategoryCubit` (factory), `AlbumCubit` (factory), `CommentCubit` (factory), `UploadCubit`, `UserSongsCubit`, `AdminCubit`

**Ghi chú:** Có cả `RepositoryProvider<MusicPlayerService>` đặt trong widget tree (từ `main.dart`). Các bloc/cubit chủ yếu lấy dependency từ `getIt`.

## 4) Data layer & Domain layer

### 4.1 Domain

- `lib/domain/entities/*`: entity (SongEntity, PlaylistEntity, CommentEntity, CategoryEntity, AlbumEntity, ChartTopSong, ChartTrendPoint).
- `lib/domain/repositories/*`: contracts (MusicRepository, CommentRepository).
- `lib/domain/usecases/*`: use case cho categories, songs by category, albums.

### 4.2 Data

- `lib/data/models/*`: model mapping DB/json/Hive.
- `lib/data/repositories/*`:
  - `MusicRepositoryImpl`: phần “hybrid” — một số chức năng dùng Hive (favorites/history/playlists/settings/cache) và một số dùng Supabase (categories/songs/albums/charts).
  - `CommentRepositoryImpl`: comments CRUD + RPC get comments by user.

### 4.3 Local cache (Hive)

- `lib/core/di/hive_initializer.dart`:
  - Register adapters: SongModel(0), HistoryEntryModel(1), PlaylistModel(2), AlbumModel(3).
  - Open boxes: songs, favorites, history, playlists, albums, settings.

## 5) Presentation layer (UI + State)

- UI screens: `lib/pages/*`.
- Root routing: `lib/pages/root_page.dart`:
  - Không có session → `HomePage`.
  - Có session → đọc `profiles.role` qua `AdminCubit.loadCurrentRole()`:
    - admin/moderator → `AdminStack`
    - user → `HomePage`

Các bloc/cubit chính (ví dụ):

- `PlayerBloc`: điều khiển playback thông qua `AudioHandler`.
- `HistoryCubit`: sync listening_history giữa Hive và Supabase, có debounce + tránh race khi modify.
- `FavoriteCubit`: sync favorites từ Supabase theo user.
- `UploadCubit`: upload file lên Supabase Storage + insert user_songs.
- `AdminCubit`: load & mutate dữ liệu admin (RPC + tables).

## 6) Audio architecture

- `MusicPlayerService` wraps `AudioService.init` và expose các thao tác.
- `MyAudioHandler`:
  - Source audio dựa trên `MediaItem.extras['url']`.
  - Queue là `ConcatenatingAudioSource`.
  - Đồng bộ state (shuffle/repeat/position/currentIndex) qua streams.

## 7) External APIs

- Lyrics: `https://lrclib.net/api` (get/search). Parse LRC + offset.
- Email OTP: EmailJS endpoint `https://api.emailjs.com/api/v1.0/email/send`.

## 8) Những điểm thiếu tài liệu / cần xác nhận

- TODO: Supabase schema chi tiết (types, constraints, RLS policies).
- TODO: RPC function definitions và return payload.
- TODO: Quy ước ID type (một số chỗ treat `songs.id` như numeric string).
