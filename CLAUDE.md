# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Flutter music player app with Supabase backend, Clean Architecture, and background audio playback. Targets Android/iOS/web.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug)
flutter run

# Run a specific test file
flutter test test/unit/bloc/player_bloc_test.dart

# Run all tests
flutter test

# Analyze code
flutter analyze

# Generate Hive TypeAdapters (after changing model .g.dart files)
dart run build_runner build --delete-conflicting-outputs

# Build release APK
flutter build apk --release

# Build for web
flutter build web
```

## Architecture

### Layer Structure

```
lib/
  core/          # App-wide: DI, config, constants, errors, routing
  domain/        # Entities + repository interfaces + use cases (pure business logic)
  data/          # Repository implementations, models (Hive/Supabase)
  presentation/  # BLoCs/Cubits, UI state
  pages/         # Screen widgets (route destinations)
  services/      # Audio handler, auth service, lyrics, player service
  widgets/       # Shared reusable widgets (mini player, progress bar, etc.)
```

**Dependency flow**: `pages/presentation/bloc → services/data → domain ← services/data` (domain has no outward dependencies).

### Key Architectural Decisions

**Clean Architecture boundary**: `domain/` contains no Flutter/Dart SDK imports — only pure entities, repository interfaces, and use cases. `data/` implements `domain/` interfaces.

**DI setup** (`service_locator.dart`): `get_it` singleton/factory registrations. `MusicPlayerService` is a singleton because the audio handler is stateful. BLoCs/Cubits are registered as `lazySingleton` (globally unique state) or `factory` (fresh state per use).

**Audio engine**: `MusicPlayerService` initializes `MyAudioHandler` (a `BaseAudioHandler` from `audio_service`) before `runApp()`. The handler wraps `just_audio`'s `AudioPlayer` and a `ConcatenatingAudioSource`. Audio URLs come from `MediaItem.extras['url']` — **not** from `MediaItem.id`.

**Hive boxes** (`hive_constants.dart`): `songs_box`, `favorites_box`, `history_box`, `playlists_box`, `albums_box`, `settings_box`. Box names are never hardcoded inline.

**Supabase integration**: All remote data (categories, songs, albums, charts, auth) goes through `MusicRepositoryImpl` which holds a `SupabaseClient`. Categories/songs/albums are fetched from Supabase; favorites/history/playlists are cached locally in Hive.

**State management**: `flutter_bloc` for `PlayerBloc` (complex, event-driven). `Cubit` for simpler features (search, favorites, theme, etc.).

## Supabase Schema

Tables: `songs`, `categories`, `albums`, `album_songs`, `song_categories`, `play_history`, `users`, `comments`.

Stored RPC functions: `get_chart_top_songs`, `get_chart_trends`.

**Config** (`supabase_config.dart`): Supabase URL + anon key are hardcoded here.

## Auth Flow

1. `main.dart` → initializes Hive, Supabase, service locator
2. `RootPage` → checks `currentSession`, calls `AdminCubit.loadCurrentRole()`
3. If sessionless/guest → `HomePage` (guest mode)
4. If session + role `user` → `HomePage`
5. If session + role `admin`/`moderator` → `AdminStack`
6. On sign-out: `AuthListener` in `main.dart` clears all BLoC/Cubit state

## Model Generation

Hive TypeAdapters are generated: `song_model.g.dart`, `playlist_model.g.dart`, `history_entry_model.g.dart`, `album_model.g.dart`. Run `build_runner` after modifying any model class annotated with `@HiveType`.

## Testing

Tests use `bloc_test` + `mocktail`. `PlayerBloc` tests use a `FakeAudioHandler` subclass of `MyAudioHandler` (because `BaseAudioHandler` cannot be mocked via `implements`). Stream controllers must be closed in test teardown.

## Code Conventions

- **No leading underscores** for local identifiers in test files (`ignore_for_file: no_leading_underscores_for_local_identifiers`)
- **Equatable** for all entities/state classes
- **Dartz `Either`** for error handling in repository methods
- **Vietnamese comments** in some files — do not translate or remove

---

## Working Session Protocol (Chống mất context)

### Trước khi bắt đầu task mới, hỏi user:
- Task này độc lập hay tiếp nối session trước?
- Có file/feature nào đang làm dở không?
- Kết quả mong đợi là gì (UI thay đổi, logic, test, v.v.)?

### Session Handoff Block
Khi user gõ `/handoff`, tạo ngay một block tóm tắt để paste vào session mới:

```
## SESSION HANDOFF
**Đang làm**: [feature/bug]
**Files đã sửa**: [list]
**Vấn đề còn lại**: [list]
**Quyết định design đã chốt**: [list]
**Bước tiếp theo**: [next action]
```

---

## Task Clarity Rules (Chống tốn token)

**Trước khi đọc bất kỳ file nào**, Claude phải xác nhận:
1. Scope: sửa logic, UI, hay cả hai?
2. File target: user biết file nào cần sửa chưa? Nếu không, hỏi trước khi dùng grep/find.
3. Definition of done: task xong khi nào?

**Nếu task mơ hồ** (ví dụ: "sửa lỗi player", "cải thiện UI") → **hỏi lại, không tự đoán**.

Ví dụ câu hỏi tốt:
- "Lỗi xảy ra ở màn hình nào / thao tác nào?"
- "UI muốn thay đổi cụ thể chỗ nào — màu, layout, hay spacing?"

---

## Context Window Management (Chống "lú" cuối session)

### Dấu hiệu cần `/clear`:
- Session đã qua 3+ feature khác nhau
- Claude bắt đầu nhắc lại thông tin sai / mâu thuẫn
- Đang chuyển sang task hoàn toàn mới

### Chiến lược đọc file:
- Chỉ đọc file **liên quan trực tiếp** đến task — không đọc "để hiểu thêm"
- Với file dài (>300 dòng), hỏi user phần nào cần xem trước
- Không đọc lại file đã đọc trong cùng session trừ khi bị sửa

### Thứ tự ưu tiên đọc:
1. File user chỉ định
2. File import trực tiếp của file đó
3. Domain entity liên quan
4. Không đọc thêm trừ khi thực sự cần

---

## UI Context (Claude không thấy màn hình)

### Màn hình chính và widget tương ứng:
| Màn hình | File chính | Mô tả |
|---|---|---|
| Home | `pages/home_page.dart` | Tab bar: Discover, Charts, Library |
| Player | `pages/player_page.dart` | Full-screen player với progress bar, controls |
| Mini Player | `widgets/mini_player.dart` | Bottom persistent bar khi có bài đang phát |
| Search | `pages/search_page.dart` | Search bar + kết quả dạng list |
| Library | `pages/library_page.dart` | Favorites, Playlists, History |

### Quy tắc khi sửa UI:
- Luôn hỏi user "màn hình hiện tại trông như thế nào?" nếu task là visual bug
- Nếu user cung cấp screenshot → mô tả lại những gì thấy trước khi sửa
- Không tự suy đoán màu sắc / spacing — hỏi hoặc đọc theme file

### Theme file: `core/config/app_theme.dart` (màu, typography, spacing chuẩn của app)

---

## Minimal Change Principle (Chống over-engineer)

**Quy tắc vàng**: Chỉ sửa đúng chỗ được yêu cầu. Không refactor code xung quanh trừ khi được hỏi.

### Claude KHÔNG được tự làm (trừ khi user yêu cầu rõ ràng):
- Đổi tên biến/hàm không liên quan đến task
- Tách file / tạo abstraction mới
- Sửa style/format của code không liên quan
- Thêm dependency mới vào `pubspec.yaml`
- Xóa code "trông có vẻ không dùng"

### Trước khi sửa nhiều hơn 1 file, Claude phải nói:
> "Task này ảnh hưởng đến [X, Y, Z]. Tôi sẽ sửa theo thứ tự [1→2→3]. Bạn muốn tiếp tục không?"

### Khi phát hiện bug ngoài scope:
> "Tôi thấy vấn đề ở [chỗ khác] nhưng nó ngoài scope task này. Ghi chú lại để xử lý sau nhé?"
— Không tự sửa luôn.