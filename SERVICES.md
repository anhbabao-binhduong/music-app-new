# SERVICES.md — music_app Service Layer

## AudioService (`MusicPlayerService`)

- **Pattern**: Eager singleton via get_it (`registerSingleton`, initialized with `await musicService.init()` before registration)
- **File**: `lib/services/music_player_service.dart`
- **Wraps**: `just_audio` (`AudioPlayer`) + `audio_service` (`BaseAudioHandler` → `MyAudioHandler`)
- **Handler**: `MyAudioHandler` (`lib/services/audio_handler.dart`) — also registered separately as `AudioHandler` eager singleton
- **Key methods**:
  - `playSong(MediaItem item)` — replaces queue with single item and plays
  - `playPlaylist(List<MediaItem> items, {int startIndex = 0})` — sets queue and seeks to index
  - `play()`, `pause()`, `stop()`
  - `next()`, `previous()`
  - `seek(Duration pos)`
- **Streams exposed**:
  - `playbackStateStream` → `Stream<PlaybackState>`
  - `currentSongStream` → `Stream<MediaItem?>`
  - `positionStream` → `Stream<Duration>`
  - `durationStream` → `Stream<Duration?>`
- **Audio URL**: read from `MediaItem.extras['url']` — NOT from `MediaItem.id`
- **Queue backend**: `ConcatenatingAudioSource` (just_audio)
- **Background audio**: registered via `AudioService.init()` with Android notification channel `com.yourapp.music.channel.audio`

---

## AuthService (`SupabaseAuthService`)

- **Pattern**: Lazy singleton via get_it (`registerLazySingleton`)
- **File**: `lib/services/supabase_auth_service.dart`
- **Wraps**: `Supabase.instance.client.auth`
- **Key methods**:
  - `signIn({required String email, required String password})` → `Future<AuthResponse>`
  - `signUp({required String name, required String email, required String password})` → `Future<AuthResponse>`
  - `signInWithGoogle()` → web: OAuth redirect (`signInWithOAuth`); mobile: native Google Account Picker via `google_sign_in` + `signInWithIdToken`
  - `signOut()` — signs out of both Google and Supabase
  - `resetPasswordForEmail(String email)`
  - `updatePassword(String newPassword)`
  - `mapError(Object error)` → localized Vietnamese error string
- **State**:
  - `authStateChanges` → `Stream<AuthState>`
  - `currentUser` → `User?`
- **Google OAuth**:
  - Web: redirect to `Uri.base.origin` with `prompt: select_account`
  - Mobile: `GoogleSignIn(serverClientId: ...)` with `signInWithIdToken`

---

## LyricsService

- **Pattern**: Lazy singleton via get_it (`registerLazySingleton`)
- **File**: `lib/services/lyrics_service.dart`
- **Fetch lyrics from**: `https://lrclib.net/api`
  - Primary: `GET /get?artist_name=&track_name=` (direct lookup, 8s timeout)
  - Fallback: `GET /search?q=` (fuzzy search with score-based ranking)
- **Sync method**: Timestamp-based LRC parsing — format `[mm:ss.xx]` per line, with optional `[offset:ms]` header support
- **Return type**: `LyricsData`
  - `syncedLyrics: List<LyricLine>` (each line has `Duration time` + `String text`) — for karaoke-style highlight
  - `plainLyrics: String` — fallback static text
- **Caching**: In-memory `Map<String, LyricsData?>` keyed by `"artist||title"` (lowercased)
- **Public API**: `getLyrics({required String artist, required String title})`, `clearCache()`

---

## PlaylistStorageService

- **Pattern**: Lazy singleton via get_it (`registerLazySingleton`)
- **File**: `lib/services/playlist_storage_service.dart`
- **Backend**: Supabase tables `playlists` + `playlist_songs`
- **Key methods**:
  - `fetchPlaylists()` → `Future<List<PlaylistModel>>` — fetches playlists + song IDs for current user
  - `createPlaylist(String name)` → `Future<String>` (returns new playlist ID)
  - `addSongToPlaylist(String playlistId, String songId)` — appends at next position
  - `removeSongFromPlaylist(String playlistId, String songId)` — removes + normalizes positions
  - `reorderSongs(String playlistId, int oldIndex, int newIndex)` — updates position column for all rows
  - `renamePlaylist(String playlistId, String newName)`
  - `deletePlaylist(String playlistId)`
- **Auth guard**: `_requireUid()` throws if not logged in; `_ensurePlaylistOwned()` validates ownership before mutating

---

## StorageService (Upload)

- **No dedicated StorageService class** — uploads are handled directly inside `UploadCubit` (`lib/presentation/bloc/upload/upload_cubit.dart`)
- **Bucket names** (from `.clinerules` / Supabase config):
  - `songs` — official audio files
  - `user-audio` — user-uploaded audio
  - `user-covers` — user-uploaded cover art
- **Upload pattern**: direct `Supabase.instance.client.storage.from(bucket).upload(path, file)` called from `UploadCubit`
- **URL generation**: `getPublicUrl(path)` on the storage bucket reference

---

## Dependency Injection

- **Container**: `get_it` (`GetIt.instance`), exported as global `getIt` from `lib/core/di/service_locator.dart`
- **Init function**: `setupServiceLocator()` — called from `lib/main.dart` after Hive and Supabase are initialized
- **Registration summary**:

| Dependency | Type | Lifetime |
|---|---|---|
| `SupabaseClient` | Core | `lazySingleton` |
| `MusicPlayerService` | Service | Eager `singleton` (awaited init) |
| `AudioHandler` | Service | Eager `singleton` |
| `LyricsService` | Service | `lazySingleton` |
| `PlaylistStorageService` | Service | `lazySingleton` |
| `SupabaseAuthService` | Service | `lazySingleton` |
| `MusicRepository` | Repository | `lazySingleton` |
| `CommentRepository` | Repository | `lazySingleton` |
| `PlayerBloc` | Bloc | `lazySingleton` |
| `ThemeBloc` | Bloc | `lazySingleton` |
| `FavoriteCubit` | Cubit | `lazySingleton` |
| `DownloadCubit` | Cubit | `lazySingleton` |
| `PlaylistCubit` | Cubit | `lazySingleton` |
| `HistoryCubit` | Cubit | `lazySingleton` |
| `UploadCubit` | Cubit | `lazySingleton` |
| `UserSongsCubit` | Cubit | `lazySingleton` |
| `AdminCubit` | Cubit | `lazySingleton` |
| `SearchCubit` | Cubit | `factory` (per use) |
| `ChartCubit` | Cubit | `factory` (per use) |
| `CategoryCubit` | Cubit | `factory` (per use) |
| `AlbumCubit` | Cubit | `factory` (per use) |
| `CommentCubit` | Cubit | `factory` (per use) |
| `ForgotPasswordCubit` | Cubit | `factory` (per use) |

- **Init order in `main.dart`**: Hive → Supabase → `setupServiceLocator()` → `runApp()`