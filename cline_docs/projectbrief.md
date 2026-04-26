# Project Brief

## Overview

`music_app` is a cross-platform Flutter music player that targets mobile, web, and desktop. The app combines music playback, playlist/history/favorites management, authentication with Supabase, community upload/comment features, and an admin/moderator area for content review and reporting.

## Main Stack

- Flutter + Dart
- `flutter_bloc` for app state management
- `get_it` for dependency injection
- Supabase for auth, database, storage, and RPC
- Hive for local cache and persistence
- `just_audio` + `audio_service` for playback/background audio

## Architecture Snapshot

The project follows a hybrid layered structure with feature-based presentation code:

- `lib/core/`: app-wide config, constants, dependency injection, errors, utilities
- `lib/domain/`: entities, repository contracts, use cases
- `lib/data/`: models and repository implementations
- `lib/presentation/bloc/`: Bloc/Cubit per feature
- `lib/pages/`: screens and feature UI
- `lib/widgets/`: shared widgets
- `lib/services/`: cross-cutting services such as audio, auth, lyrics, and playlist storage

Primary state management is `flutter_bloc`. `provider` exists in dependencies, but the app architecture is centered on Bloc/Cubit plus `get_it`.

## Runtime Flow

The app boots in `lib/main.dart` with this order:

1. Initialize Hive boxes/adapters
2. Initialize Supabase
3. Register dependencies in `lib/core/di/service_locator.dart`
4. Preload songs/search data and set up auth listeners
5. Build the app with `MultiRepositoryProvider` and `MultiBlocProvider`

`lib/pages/root_page.dart` acts as the first screen router. It checks auth state and user role, then routes either to the normal user experience or the admin stack.

## Key Patterns

- Bloc/Cubit for feature state
- Repository pattern for data access
- Use case classes for selected domain flows
- Service locator pattern with `get_it`
- Model-to-entity mapping between `data` and `domain`
- Hybrid local/remote persistence using Hive + Supabase

## Naming And Structure Conventions

- Files use `snake_case.dart`
- Types use `PascalCase`
- Members use `camelCase`
- Feature suffixes are consistent: `Cubit`, `Bloc`, `State`, `Event`, `RepositoryImpl`, `Entity`, `Model`, `Service`, `Page`

## Notes For Future Changes

- Keep new work inside the existing layer/feature path instead of inventing new folders.
- Prefer extending an existing Bloc/Cubit/service/repository when the feature already has one.
- Limit edits to files directly related to the requested task.
- Preserve the current hybrid style instead of forcing a stricter clean architecture rewrite.
