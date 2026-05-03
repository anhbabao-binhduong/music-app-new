# AGENTS.md — music_app Coding Agent

## Role
AI coding assistant for Flutter music app.
- Backend: Supabase (auth, DB, storage, RPC)
- State: `flutter_bloc` / `Cubit` — no other state solution
- DI: `get_it` via `lib/core/di/service_locator.dart`
- Local cache: Hive; remote: Supabase

## Session Start
1. If task involves UI → read `DESIGN_SKILL.md` first
2. Otherwise → start working immediately
3. Do **NOT** auto-read `SOUL.md`, `USER.md`, `MEMORY.md` in coding sessions

## Common Commands
```bash
flutter pub get                                          # install deps
flutter run                                             # run debug
flutter test                                            # run all tests
flutter test test/unit/bloc/player_bloc_test.dart       # run one test
flutter analyze                                         # lint
dart run build_runner build --delete-conflicting-outputs # regenerate Hive adapters
flutter build apk --release
flutter build web
```

## Code Conventions (enforce these)
- `Equatable` for all entity/state classes
- `dartz Either<Failure, T>` for repository method return types
- Vietnamese comments in some files — do **not** translate or remove
- No leading underscores for local identifiers in test files
- Box names from `hive_constants.dart` — never hardcode inline

## UI Screen Map
| Screen | File | Notes |
|--------|------|-------|
| Home | `pages/home_page.dart` | Discover / Charts / Library tabs |
| Player | `pages/player_page.dart` | Full-screen, progress bar, controls |
| Mini Player | `widgets/mini_player.dart` | Persistent bottom bar |
| Search | `pages/search_page.dart` | Search bar + list results |
| Library | `pages/library_page.dart` | Favorites, Playlists, History |

Theme file: `core/config/app_theme.dart`

## Task Discipline
- Before editing any code, confirm scope (logic / UI / both) and target files
- If task is vague (e.g. "fix player bug") → ask ONE clarifying question before reading files
- Before modifying >1 file, state which files and order, then proceed
- When a bug is found outside task scope: note it, do **NOT** fix it silently
- Only read files **directly** related to the task — no exploratory reads

## Minimal Change
- Only edit files directly related to the task
- Do not rename variables, reorder imports, or reformat unrelated code
- Do not add new dependencies to `pubspec.yaml` unless explicitly requested
- Do not delete code that looks unused — note it instead

## Memory Rules
- Log key decisions/discoveries to `memory/YYYY-MM-DD.md`
- Never re-read the same file twice per task
- If tools fail: retry once, then continue with available info
- Do not ask user to paste file contents

## Red Lines
- Do not exfiltrate private data
- Do not run destructive commands without asking
- Do not bypass architecture rules in `.clinerules`
- Do not introduce Riverpod, GetX, MobX, Redux, or any alternate state solution