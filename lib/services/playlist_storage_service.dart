import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/playlist_model.dart';

class PlaylistStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _requireUid() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để dùng danh sách phát');
    }
    return uid;
  }

  Future<List<PlaylistModel>> fetchPlaylists() async {
    final uid = _requireUid();

    final playlistRows = await _supabase
        .from('playlists')
        .select('id, name, cover_art_url, created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final playlists = <PlaylistModel>[];

    for (final row in (playlistRows as List)) {
      final playlistId = row['id'].toString();
      final songRows = await _supabase
          .from('playlist_songs')
          .select('song_id, position')
          .eq('playlist_id', playlistId)
          .order('position', ascending: true);

      playlists.add(
        PlaylistModel(
          id: playlistId,
          name: (row['name'] ?? 'Untitled Playlist').toString(),
          songIds: (songRows as List)
              .map((e) => e['song_id']?.toString())
              .whereType<String>()
              .toList(),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
              DateTime.now(),
          coverArtUrl: row['cover_art_url']?.toString(),
        ),
      );
    }

    return playlists;
  }

  Future<String> createPlaylist(String name) async {
    final uid = _requireUid();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Tên danh sách phát không được để trống');
    }

    final existing = await _supabase
        .from('playlists')
        .select('id')
        .eq('user_id', uid)
        .eq('name_lower', trimmedName.toLowerCase())
        .limit(1);

    if ((existing as List).isNotEmpty) {
      throw Exception('Danh sách phát đã tồn tại');
    }

    final inserted = await _supabase
        .from('playlists')
        .insert({
          'user_id': uid,
          'name': trimmedName,
          'name_lower': trimmedName.toLowerCase(),
          'visibility': 'private',
        })
        .select('id')
        .single();

    return inserted['id'].toString();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _ensurePlaylistOwned(playlistId);

    final existing = await _supabase
        .from('playlist_songs')
        .select('id')
        .eq('playlist_id', playlistId)
        .eq('song_id', songId)
        .limit(1);

    if ((existing as List).isNotEmpty) return;

    final rows = await _supabase
        .from('playlist_songs')
        .select('position')
        .eq('playlist_id', playlistId)
        .order('position', ascending: false)
        .limit(1);

    final nextPosition = (rows as List).isEmpty
        ? 0
        : ((rows.first['position'] as num?)?.toInt() ?? 0) + 1;

    await _supabase.from('playlist_songs').insert({
      'playlist_id': playlistId,
      'song_id': songId,
      'position': nextPosition,
    });

    await _touchPlaylist(playlistId);
  }

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    await _ensurePlaylistOwned(playlistId);

    final rows = await _supabase
        .from('playlist_songs')
        .select('id, song_id, position')
        .eq('playlist_id', playlistId)
        .order('position', ascending: true);

    final items = List<Map<String, dynamic>>.from(rows as List);
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;

    if (newIndex > oldIndex) newIndex -= 1;

    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    for (var i = 0; i < items.length; i++) {
      await _supabase
          .from('playlist_songs')
          .update({'position': i})
          .eq('id', items[i]['id']);
    }

    await _touchPlaylist(playlistId);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _ensurePlaylistOwned(playlistId);

    await _supabase
        .from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('song_id', songId);

    await _normalizePositions(playlistId);
    await _touchPlaylist(playlistId);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _ensurePlaylistOwned(playlistId);
    await _supabase.from('playlists').delete().eq('id', playlistId);
  }

  Future<void> _ensurePlaylistOwned(String playlistId) async {
    final uid = _requireUid();
    final rows = await _supabase
        .from('playlists')
        .select('id')
        .eq('id', playlistId)
        .eq('user_id', uid)
        .limit(1);

    if ((rows as List).isEmpty) {
      throw Exception('Không tìm thấy danh sách phát');
    }
  }

  Future<void> _touchPlaylist(String playlistId) async {
    await _supabase
        .from('playlists')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', playlistId);
  }

  Future<void> _normalizePositions(String playlistId) async {
    final rows = await _supabase
        .from('playlist_songs')
        .select('id')
        .eq('playlist_id', playlistId)
        .order('position', ascending: true);

    final items = List<Map<String, dynamic>>.from(rows as List);
    for (var i = 0; i < items.length; i++) {
      await _supabase
          .from('playlist_songs')
          .update({'position': i})
          .eq('id', items[i]['id']);
    }
  }
}
