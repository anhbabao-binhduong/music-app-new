import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/playlist_model.dart';
import '../core/constants/hive_constants.dart';

class PlaylistStorageService {
  // Sử dụng hằng số từ HiveBoxes để tránh lệch tên Box
  final _box = Hive.box<PlaylistModel>(HiveBoxes.playlists);

  List<PlaylistModel> get allPlaylists {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); 
    return list;
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final playlist = _box.get(playlistId);
    if (playlist != null && !playlist.songIds.contains(songId)) {
      playlist.songIds.add(songId);
      await playlist.save();
    }
  }

  // Chỉ giữ DUY NHẤT một hàm createPlaylist và trả về ID
  Future<String> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newPlaylist = PlaylistModel(
      id: id,
      name: name,
      songIds: [],
      createdAt: DateTime.now(),
    );
    await _box.put(id, newPlaylist);
    return id;
  }

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    final playlist = _box.get(playlistId);
    if (playlist != null) {
      if (newIndex > oldIndex) newIndex -= 1;
      final List<String> newList = List.from(playlist.songIds);
      final String item = newList.removeAt(oldIndex);
      newList.insert(newIndex, item);
      playlist.songIds = newList;
      await playlist.save();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = _box.get(playlistId);
    if (playlist != null) {
      playlist.songIds.remove(songId);
      await playlist.save();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _box.delete(playlistId);
  }
}