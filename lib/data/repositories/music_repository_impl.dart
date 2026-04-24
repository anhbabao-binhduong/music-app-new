import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:dartz/dartz.dart' as dz;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/hive_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/category_entity.dart';       // 👈 THÊM
import '../../domain/entities/album_entity.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/entities/chart_top_song.dart';
import '../../domain/entities/chart_trend_point.dart';
import '../models/album_model.dart';
import '../models/history_entry_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../models/category_model.dart';                   // 👈 THÊM

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

  // ─── Supabase client ────────────────────────────────────
  final SupabaseClient _supabase;

  // Constructor: nhận supabaseClient (có thể từ DI), nếu không thì dùng instance mặc định
  MusicRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

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

  // ─── Categories (Supabase) ──────────────────────────────────────────────
  @override
  Future<dz.Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('display_order', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json).toEntity())
          .toList();

      return dz.Right(categories);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to fetch categories: $e'));
    }
  }

  // Thay thế toàn bộ phương thức getAllSongs
@override
Future<dz.Either<Failure, List<SongEntity>>> getAllSongs() async {
  try {
    final response = await _supabase
        .from('songs')
        .select('*')
        .not('audio_path', 'is', null)   // loại bỏ bài không có audio
        .neq('audio_path', '')            // loại bỏ audio_path rỗng
        .order('title', ascending: true);
    final songs = (response as List).map((json) => SongEntity(
      id: json['id'].toString(),
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown',
      album: json['album'] ?? 'Unknown',
      artUrl: json['art_url'],
      audioUrl: json['audio_path'],
      durationMs: ((json['duration_seconds'] as num?)?.toInt() ?? 0) * 1000,
    )).toList();
    return dz.Right(songs);
  } catch (e) {
    return dz.Left(CacheFailure('Failed to fetch songs: $e'));
  }
}
  
  @override
Future<dz.Either<Failure, List<SongEntity>>> getSongsByCategory(String? slug) async {
  try {
    if (slug == null) {
      // Lấy tất cả bài hát từ Supabase
      return await getAllSongs();
    }

      // Bước 1: lấy category_id từ slug
      final catRes = await _supabase
          .from('categories')
          .select('id')
          .eq('slug', slug)
          .maybeSingle();

      if (catRes == null) return const dz.Right([]);

      final categoryId = catRes['id'] as String;

      // Bước 2: lấy song_id từ bảng trung gian
      final joinRes = await _supabase
          .from('song_categories')
          .select('song_id')
          .eq('category_id', categoryId);

            final songIds = (joinRes as List)
          .map((e) => int.tryParse(e['song_id']?.toString() ?? ''))
          .whereType<int>()
          .toList();


      if (songIds.isEmpty) return const dz.Right([]);

      // Bước 3: lấy songs từ Supabase, chỉ lấy bài có audio hợp lệ
      final songsRes = await _supabase
          .from('songs')
          .select()
          .inFilter('id', songIds)
          .not('audio_path', 'is', null)   // loại bỏ bài không có audio
          .neq('audio_path', '');           // loại bỏ audio_path rỗng

      final songs = (songsRes as List).map((json) {
        return SongEntity(
          id:         json['id'].toString(),
          title:      (json['title']  as String?) ?? 'Unknown',
          artist:     (json['artist'] as String?) ?? 'Unknown',
          album:      (json['album']  as String?) ?? 'Unknown',
          artUrl:     json['art_url']    as String?,
          audioUrl:   json['audio_path'] as String?,           // ✅ sửa
          durationMs: ((json['duration_seconds'] as num?)?.toInt() ?? 0) * 1000, // ✅ sửa
        );
      }).toList();

      return dz.Right(songs);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to fetch songs by category: $e'));
    }
  }

  // ── Albums (Supabase) ────────────────────────────────────────────────────
  @override
  Future<List<AlbumEntity>> getAlbums() async {
    final response = await _supabase
        .from('albums')
        .select('*, album_songs(song_id, track_number)')
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => AlbumModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
        .toList();
  }

  @override
  Future<AlbumEntity?> getAlbumById(String albumId) async {
    final response = await _supabase
        .from('albums')
        .select('*, album_songs(song_id, track_number)')
        .eq('id', albumId)
        .maybeSingle();
    if (response == null) return null;
    return AlbumModel.fromJson(Map<String, dynamic>.from(response as Map)).toEntity();
  }

  // ── Chart (Supabase) ───────────────────────────────────────────────────────
  @override
  Future<dz.Either<Failure, List<ChartTopSong>>> getChartTopSongs(int daysAgo) async {
    try {
      final currentRes = await _supabase.rpc('get_chart_top_songs', params: {'days_ago': daysAgo});
      final previousRes = await _supabase.rpc('get_chart_top_songs', params: {'days_ago': daysAgo * 2});

      final prevCountMap = <String, int>{};
      for (final row in (previousRes as List)) {
        prevCountMap[row['song_id'] as String] = row['play_count'] as int;
      }

      final List<String> topSongIds = (currentRes as List).map((r) => r['song_id'] as String).toList();
      final Map<String, SongEntity> songsMap = {};
      
      final validSongIds = topSongIds.map((id) => int.tryParse(id)).whereType<int>().toList();

      if (validSongIds.isNotEmpty) {
        final songsRes = await _supabase.from('songs').select('*').inFilter('id', validSongIds);
        for (var s in songsRes) {
          songsMap[s['id'].toString()] = SongEntity(
            id: s['id'].toString(),
            title: s['title'] ?? 'Unknown',
            artist: s['artist'] ?? 'Unknown',
            album: s['album'] ?? 'Unknown',
            artUrl: s['art_url'],
            audioUrl: s['audio_path'],
            durationMs: ((s['duration_seconds'] as num?)?.toInt() ?? 0) * 1000,
          );
        }
      }

      final List<ChartTopSong> result = [];
      for (final row in currentRes) {
        final id = row['song_id'] as String;
        final count = row['play_count'] as int;
        
        final prevTotal = prevCountMap[id] ?? 0;
        final prevPeriodCount = prevTotal - count;

        ChartTrend trend = ChartTrend.same;
        if (count > prevPeriodCount) {
          trend = ChartTrend.up;
        } else if (count < prevPeriodCount) {
          trend = ChartTrend.down;
        }

        String? audioUrl = id;
        try {
          if (row['song_extras'] != null) {
            final extras = jsonDecode(row['song_extras'] as String);
            if (extras['url'] != null) {
              audioUrl = extras['url'] as String;
            }
          }
        } catch (_) {}

        final song = songsMap[id] ?? SongEntity(
          id: id,
          title: row['song_title'] as String,
          artist: row['song_artist'] as String? ?? 'Unknown',
          album: 'Local Music',
          artUrl: row['song_art_uri'] as String?,
          audioUrl: audioUrl,
          durationMs: (row['song_duration_ms'] as num?)?.toInt() ?? 0,
        );

        result.add(ChartTopSong(
          song: song,
          playCount: count,
          trend: trend,
        ));
      }

      return dz.Right(result);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to fetch chart top songs: $e'));
    }
  }

  @override
  Future<dz.Either<Failure, List<ChartTrendPoint>>> getChartTrends(int daysAgo, List<String> songIds) async {
    try {
      final res = await _supabase.rpc('get_chart_trends', params: {
        'days_ago': daysAgo,
        'song_ids_csv': songIds.join(','),
      });

      // ignore: avoid_print
      print("DEBUG GET_CHART_TRENDS: daysAgo=$daysAgo, songIds=$songIds");
      // ignore: avoid_print
      print("DEBUG GET_CHART_TRENDS RES: $res");

      final List<ChartTrendPoint> result = [];
      for (final row in (res as List)) {
        result.add(ChartTrendPoint(
          songId: row['song_id'] as String,
          dateLabel: row['play_date'] as String,
          playCount: (row['play_count'] as num).toInt(),
        ));
      }
      // ignore: avoid_print
      print("DEBUG GET_CHART_TRENDS RESULT length: ${result.length}");

      return dz.Right(result);
    } catch (e) {
      return dz.Left(CacheFailure('Failed to fetch chart trends: $e'));
    }
  }
}
