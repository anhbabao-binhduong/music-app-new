import 'package:audio_service/audio_service.dart';
import 'package:dartz/dartz.dart' as dz;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/hive_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/music_repository.dart';
import '../models/history_entry_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

extension MediaItemToEntity on MediaItem {
  SongEntity toEntity() => SongEntity(
        id: id,
        title: title,
        artist: artist ?? 'Unknown',
        album: album ?? 'Unknown',
        artUrl: artUri?.toString(),
        audioUrl: id,
        durationMs: duration?.inMilliseconds ?? 0,
      );
}

class MusicRepositoryImpl implements MusicRepository {
  Box<SongModel> get _songs => Hive.box<SongModel>(HiveBoxes.songs);
  Box<SongModel> get _favorites => Hive.box<SongModel>(HiveBoxes.favorites);
  Box<HistoryEntryModel> get _history =>
      Hive.box<HistoryEntryModel>(HiveBoxes.history);
  Box<PlaylistModel> get _playlists =>
      Hive.box<PlaylistModel>(HiveBoxes.playlists);
  Box<dynamic> get _settings => Hive.box<dynamic>(HiveBoxes.settings);

  final _uuid = const Uuid();

  // ─── Favorites ───────────────────────────────────────────

  @override
  Future<dz.Either<Failure, List<SongEntity>>> getFavorites() async {
    try {
      final items = _favorites.values
          .map((m) => m.toMediaItem().toEntity())
          .toList()
          .reversed
          .toList();
      return dz.Right(items);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to load favorites: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> addFavorite(MediaItem song) async {
    try {
      final model =
          SongModel.fromMediaItem(song).copyWith(addedAt: DateTime.now());
      await _favorites.put(song.id, model);
      await _songs.put(song.id, model);
      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to add favorite: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> removeFavorite(String songId) async {
    try {
      await _favorites.delete(songId);
      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to remove favorite: $e'));
    }
  }

  @override
  Future<bool> isFavorite(String songId) async =>
      _favorites.containsKey(songId);

  // ─── History ─────────────────────────────────────────────

  @override
  Future<dz.Either<Failure, List<SongEntity>>> getHistory(
      {int limit = 50}) async {
    try {
      final entries = _history.values.toList()
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

      final songs = entries.take(limit).map((entry) {
        final model = _songs.get(entry.songId);
        return model?.toMediaItem().toEntity();
      }).whereType<SongEntity>().toList();

      return dz.Right(songs);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to load history: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> addToHistory(
      MediaItem song, {int playedMs = 0}) async {
    try {
      await _songs.put(song.id, SongModel.fromMediaItem(song));

      final entry = HistoryEntryModel(
        songId: song.id,
        playedAt: DateTime.now(),
        playDurationMs: playedMs,
      );

      await _history.put(
        '${song.id}_${DateTime.now().millisecondsSinceEpoch}',
        entry,
      );

      await _pruneHistory(maxEntries: 200);

      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to add history: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> clearHistory() async {
    try {
      await _history.clear();
      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to clear history: $e'));
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
  Future<dz.Either<Failure, List<PlaylistEntity>>> getPlaylists() async {
    try {
      final result = _playlists.values
          .map((m) => PlaylistEntity(
                id: m.id,
                name: m.name,
                songIds: List<String>.from(m.songIds),
                createdAt: m.createdAt,
                coverArtUrl: m.coverArtUrl,
              ))
          .toList();

      return dz.Right(result);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to load playlists: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> createPlaylist(String name) async {
    try {
      final id = _uuid.v4();
      await _playlists.put(id, PlaylistModel(id: id, name: name));
      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to create playlist: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> deletePlaylist(
      String playlistId) async {
    try {
      await _playlists.delete(playlistId);
      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to delete playlist: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> addSongToPlaylist(
      String playlistId, MediaItem song) async {
    try {
      final playlist = _playlists.get(playlistId);
      if (playlist == null) {
        return const dz.Left(NotFoundFailure('Playlist not found'));
      }

      if (!playlist.songIds.contains(song.id)) {
        playlist.songIds.add(song.id);
        await playlist.save();
        await _songs.put(song.id, SongModel.fromMediaItem(song));
      }

      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to add song: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, dz.Unit>> removeSongFromPlaylist(
      String playlistId, String songId) async {
    try {
      final playlist = _playlists.get(playlistId);
      if (playlist == null) {
        return const dz.Left(NotFoundFailure('Playlist not found'));
      }

      playlist.songIds.remove(songId);
      await playlist.save();

      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to remove song: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, List<SongEntity>>> getPlaylistSongs(
      String playlistId) async {
    try {
      final playlist = _playlists.get(playlistId);
      if (playlist == null) {
        return const dz.Left(NotFoundFailure('Playlist not found'));
      }

      final songs = playlist.songIds
          .map((id) => _songs.get(id)?.toMediaItem().toEntity())
          .whereType<SongEntity>()
          .toList();

      return dz.Right(songs);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to get playlist songs: $e'));
    }
  }

  // ─── Song Cache ──────────────────────────────────────────

  @override
  Future<dz.Either<Failure, dz.Unit>> cacheSong(MediaItem song) async {
    try {
      await _songs.put(song.id, SongModel.fromMediaItem(song));
      return const dz.Right(dz.unit);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to cache song: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, SongEntity?>> getCachedSong(
      String songId) async {
    try {
      final model = _songs.get(songId);
      return dz.Right(model?.toMediaItem().toEntity());
    } catch (e) {
      return dz.Left(CacheFailure('Failed to get cached song: $e'));
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
    final raw = _settings.get(HiveSettingsKeys.lastSongId);
    final songId = raw is String ? raw : null;

    final rawPos =
        _settings.get(HiveSettingsKeys.lastPosition, defaultValue: 0);
    final positionMs = rawPos is int ? rawPos : 0;

    return (songId: songId, positionMs: positionMs);
  }
}