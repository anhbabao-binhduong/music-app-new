# AI_CONTEXT.md — music_app

## App Overview
Flutter music streaming app. Cross-platform (Android/iOS/web). Offline-capable via Hive cache, streaming from Supabase Storage.

## Key Features
- Music playback: queue, next/prev/seek, shuffle, repeat (`just_audio` + `audio_service`)
- Auth: email/password + Google Sign-In via Supabase
- Content: browse songs, albums, categories, charts (from Supabase DB)
- User features: favorites, downloads, listening history, playlists (stored Hive + Supabase)
- Comments per song
- User song upload: audio + cover → Supabase Storage → `user_songs` table (status: `pending`)
- Admin/moderator stack: approve/reject songs, manage users/comments, view stats

## Architecture
See `.clinerules` for full rules. Short version: hybrid clean arch — domain/data layers + some direct Supabase calls from Cubits/Services.

## Entry Point & Init Order (`lib/main.dart`)
1. Hive init + register adapters
2. Supabase init (from `supabase_config.dart`)
3. `setupServiceLocator()` — DI + audio service init
4. Fetch songs from Supabase, update audio queue
5. Build search pool (`SearchCubit.loadSongPool`)
6. Set auth listener (sign-out: clear state; sign-in: reload history)
7. `runApp(MyApp)`

## Auth Flow
- No session → `HomePage` (guest mode)
- Session + `profiles.role = user` → `HomePage`
- Session + `profiles.role = admin/moderator` → `AdminStack`
- PKCE error (`AuthException`) → auto sign-out, fall to guest

## Key Gotchas (where AI commonly makes mistakes)
- Audio URL: always from `MediaItem.extras['url']` — **never** from `MediaItem.id`
- Hive box names: always from `hive_constants.dart` — never hardcode strings
- `MusicPlayerService` is a singleton (stateful audio handler) — do not create new instances
- Some Cubits call Supabase directly (not via repository) — this is intentional, do not force a repo layer
- `user_songs` table ≠ `songs` table — user uploads are separate from official catalog

## Never Do
- Force full clean architecture on features that currently use direct Supabase calls from Cubits
- Use `setState` outside trivial local UI cases — use Bloc/Cubit
- Hardcode Supabase URLs, keys, or bucket names — use config/constants files
- Add columns/tables to Supabase without documenting in `supabase/migrations/`
- Translate or remove Vietnamese comments