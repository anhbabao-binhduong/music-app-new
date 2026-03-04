import 'package:audio_service/audio_service.dart';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/hive_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/music_repository.dart';
import '../models/history_entry_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class MusicRepositoryImpl implements MusicRepository {
  // Boxes are already open (via HiveInitializer.init())
  Box<SongModel>         get _songs      => Hive.box(HiveBoxes.songs);
  Box<SongModel>         get _favorites  => Hive.box(HiveBoxes.favorites);
  Box<HistoryEntryModel> get _history    => Hive.box(HiveBoxes.history);
  Box<PlaylistModel>     get _playlists  => Hive.box(HiveBoxes.playlists);
  Box<dynamic>           get _settings   => Hive.box(HiveBoxes.settings);

  final _uuid = const Uuid();

  // ─── Favorites ───────────────────────────────────────────

  @override
  Future<Either<Failure, List<SongEntity>>> getFavorites() async {
    try {
      final items = _favorites.values
          .map((m) => m.toMediaItem().toEntity())
          .toList()
          .reversed
          .toList(); // newest first
      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to load favorites: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addFavorite(MediaItem song) async {
    try {
      final model = SongModel.fromMediaItem(song)
          .copyWith(addedAt: DateTime.now());
      await _favorites.put(song.id, model);
      // Also cache song data for offline access
      await _songs.put(song.id, model);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to add favorite: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFavorite(String songId) async {
    try {
      await _favorites.delete(songId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to remove favorite: $e'));
    }
  }

  @override
  Future<bool> isFavorite(String songId) async =>
      _favorites.containsKey(songId);

  // ─── History ─────────────────────────────────────────────

  @override
  Future<Either<Failure, List<SongEntity>>> getHistory({int limit = 50}) async {
    try {
      // Sort by playedAt desc, take [limit]
      final entries = _history.values.toList()
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

      final songs = entries.take(limit).map((entry) {
        final model = _songs.get(entry.songId);
        return model?.toMediaItem().toEntity();
      }).whereType<SongEntity>().toList();

      return Right(songs);
    } catch (e) {
      return Left(CacheFailure('Failed to load history: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addToHistory(
      MediaItem song, {int playedMs = 0}) async {
    try {
      // Cache song metadata
      await _songs.put(song.id, SongModel.fromMediaItem(song));

      final entry = HistoryEntryModel(
        songId:        song.id,
        playedAt:      DateTime.now(),
        playDurationMs: playedMs,
      );

      // Use timestamp as key so duplicates create new entries
      await _history.put(
        '${song.id}_${DateTime.now().millisecondsSinceEpoch}',
        entry,
      );

      // Prune old entries if over 200
      await _pruneHistory(maxEntries: 200);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to add history: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearHistory() async {
    try {
      await _history.clear();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to clear history: $e'));
    }
  }

  Future<void> _pruneHistory({required int maxEntries}) async {
    if (_history.length <= maxEntries) return;
    final keys = _history.keys.toList();
    final toDelete = keys.take(_history.length - maxEntries);
    await _history.deleteAll(toDelete);
  }

  // ─── Playlists ───────────────────────────────────────────

  @override
  Future<Either<Failure, List<PlaylistEntity>>> getPlaylists() async {
    try {
      final result = _playlists.values
          .map((m) => PlaylistEntity(
                id:          m.id,
                name:        m.name,
                songIds:     m.songIds,
                createdAt:   m.createdAt,
                coverArtUrl: m.coverArtUrl,
              ))
          .toList();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Failed to load playlists: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> createPlaylist(String name) async {
    try {
      final id = _uuid.v4();
      await _playlists.put(id, PlaylistModel(id: id, name: name));
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to create playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePlaylist(String playlistId) async {
    try {
      await _playlists.delete(playlistId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addSongToPlaylist(
      String playlistId, MediaItem song) async {
    try {
      final playlist = _playlists.get(playlistId);
      if (playlist == null) {
        return const Left(NotFoundFailure('Playlist not found'));
      }
      if (!playlist.songIds.contains(song.id)) {
        playlist.songIds.add(song.id);
        await playlist.save();
        await _songs.put(song.id, SongModel.fromMediaItem(song));
      }
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to add song: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeSongFromPlaylist(
      String playlistId, String songId) async {
    try {
      final playlist = _playlists.get(playlistId);
      if (playlist == null) {
        return const Left(NotFoundFailure('Playlist not found'));
      }
      playlist.songIds.remove(songId);
      await playlist.save();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to remove song: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SongEntity>>> getPlaylistSongs(
      String playlistId) async {
    try {
      final playlist = _playlists.get(playlistId);
      if (playlist == null) {
        return const Left(NotFoundFailure('Playlist not found'));
      }
      final songs = playlist.songIds
          .map((id) => _songs.get(id)?.toMediaItem().toEntity())
          .whereType<SongEntity>()
          .toList();
      return Right(songs);
    } catch (e) {
      return Left(CacheFailure('Failed to get playlist songs: $e'));
    }
  }

  // ─── Song Cache ──────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> cacheSong(MediaItem song) async {
    try {
      await _songs.put(song.id, SongModel.fromMediaItem(song));
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to cache song: $e'));
    }
  }

  @override
  Future<Either<Failure, SongEntity?>> getCachedSong(String songId) async {
    try {
      final model = _songs.get(songId);
      return Right(model?.toMediaItem().toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get cached song: $e'));
    }
  }

  // ─── Settings ────────────────────────────────────────────

  @override
  Future<void> saveLastPlayed(String songId, int positionMs) async {
    await _settings.put(HiveSettingsKeys.lastSongId, songId);
    await _settings.put(HiveSettingsKeys.lastPosition, positionMs);
  }

  @override
  Future<({String? songId, int positionMs})> getLastPlayed() async {
    final songId     = _settings.get(HiveSettingsKeys.lastSongId) as String?;
    final positionMs = _settings.get(HiveSettingsKeys.lastPosition, defaultValue: 0) as int;
    return (songId: songId, positionMs: positionMs);
  }
}

// Extension to convert MediaItem → SongEntity cleanly
extension on MediaItem {
  SongEntity toEntity() => SongEntity(
    id:          id,
    title:       title,
    artist:      artist ?? 'Unknown',
    album:       album  ?? 'Unknown',
    artUrl:      artUri?.toString(),
    audioUrl:    id,
    durationMs:  duration?.inMilliseconds ?? 0,
  );
}