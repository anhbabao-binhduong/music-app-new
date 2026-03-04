import 'package:audio_service/audio_service.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/song_entity.dart';

/// Pure abstract contract — zero Flutter/Hive imports here.
/// Presentation layer depends ONLY on this interface.
abstract class MusicRepository {
  // ── Favorites ──────────────────────────────────────────
  Future<Either<Failure, List<SongEntity>>> getFavorites();
  Future<Either<Failure, Unit>>    addFavorite(MediaItem song);
  Future<Either<Failure, Unit>>    removeFavorite(String songId);
  Future<bool>                     isFavorite(String songId);

  // ── History ────────────────────────────────────────────
  Future<Either<Failure, List<SongEntity>>> getHistory({int limit = 50});
  Future<Either<Failure, Unit>>    addToHistory(MediaItem song, {int playedMs = 0});
  Future<Either<Failure, Unit>>    clearHistory();

  // ── Playlists ──────────────────────────────────────────
  Future<Either<Failure, List<PlaylistEntity>>> getPlaylists();
  Future<Either<Failure, Unit>>    createPlaylist(String name);
  Future<Either<Failure, Unit>>    deletePlaylist(String playlistId);
  Future<Either<Failure, Unit>>    addSongToPlaylist(String playlistId, MediaItem song);
  Future<Either<Failure, Unit>>    removeSongFromPlaylist(String playlistId, String songId);
  Future<Either<Failure, List<SongEntity>>> getPlaylistSongs(String playlistId);

  // ── Local Song Cache ───────────────────────────────────
  Future<Either<Failure, Unit>>    cacheSong(MediaItem song);
  Future<Either<Failure, SongEntity?>> getCachedSong(String songId);

  // ── Settings ───────────────────────────────────────────
  Future<void> saveLastPlayed(String songId, int positionMs);
  Future<({String? songId, int positionMs})> getLastPlayed();
}