import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/services/playlist_storage_service.dart';
import 'package:music_app/data/models/playlist_model.dart';

part 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  final PlaylistStorageService _storageService =
      getIt<PlaylistStorageService>();

  PlaylistCubit() : super(PlaylistLoaded([])) {
  loadPlaylists();
}

  Future<void> loadPlaylists() async {
    try {
      final playlists = await _storageService.fetchPlaylists();
      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError(e.toString()));
    }
  }

  /// ✅ CREATE ONLY
  Future<String?> createNewPlaylist(String name) async {
    try {
      final newId = await _storageService.createPlaylist(name);

      final current = state;
      if (current is PlaylistLoaded) {
        final newPlaylist = PlaylistModel(
          id: newId,
          name: name,
          songIds: [],
        );

        emit(PlaylistLoaded([...current.playlists, newPlaylist]));
      }

      return null;
    } catch (e) {
      final message = e.toString();
      emit(PlaylistError(message));
      return message;
    }
  }

  /// ✅ CREATE + ADD SONG
  Future<String?> createPlaylistAndAddSong(
      String name, String songId) async {
    try {
      final newId = await _storageService.createPlaylist(name);
      await _storageService.addSongToPlaylist(newId, songId);

      final current = state;
      if (current is PlaylistLoaded) {
        final newPlaylist = PlaylistModel(
          id: newId,
          name: name,
          songIds: [songId],
        );

        emit(PlaylistLoaded([...current.playlists, newPlaylist]));
      }

      return null;
    } catch (e) {
      final message = e.toString();
      emit(PlaylistError(message));
      return message;
    }
  }

  /// 🔥 ADD SONG (QUAN TRỌNG NHẤT)
  Future<String?> addSongToPlaylist(
      String playlistId, String songId) async {
    try {
      final current = state;

      if (current is! PlaylistLoaded) return "State lỗi";

      final playlists = List<PlaylistModel>.from(current.playlists);

      final index =
          playlists.indexWhere((p) => p.id == playlistId);

      if (index == -1) return "Không tìm thấy playlist";

      final playlist = playlists[index];

      if (playlist.songIds.contains(songId)) {
        return "Đã tồn tại";
      }

      /// 🔥 UPDATE FIRESTORE
      await _storageService.addSongToPlaylist(
          playlistId, songId);

      /// 🔥 UPDATE LOCAL
      final updatedPlaylist = playlist.copyWith(
        songIds: [...playlist.songIds, songId],
      );

      playlists[index] = updatedPlaylist;

      /// 🔥 EMIT NGAY → UI UPDATE
      emit(PlaylistLoaded(playlists));

      return null;
    } catch (e) {
      final message = 'Lỗi khi thêm bài hát: $e';
      emit(PlaylistError(message));
      return message;
    }
  }

  /// REMOVE SONG
  Future<String?> removeSongFromPlaylist(
      String playlistId, String songId) async {
    try {
      final current = state;

      if (current is! PlaylistLoaded) return "State lỗi";

      final playlists = List<PlaylistModel>.from(current.playlists);

      final index =
          playlists.indexWhere((p) => p.id == playlistId);

      if (index == -1) return "Không tìm thấy playlist";

      final playlist = playlists[index];

      await _storageService.removeSongFromPlaylist(
          playlistId, songId);

      final updatedPlaylist = playlist.copyWith(
        songIds: playlist.songIds
            .where((id) => id != songId)
            .toList(),
      );

      playlists[index] = updatedPlaylist;

      emit(PlaylistLoaded(playlists));

      return null;
    } catch (e) {
      final message = 'Lỗi khi xóa bài hát: $e';
      emit(PlaylistError(message));
      return message;
    }
  }

  /// REORDER
  Future<String?> reorderSongs(
      String playlistId, int oldIndex, int newIndex) async {
    try {
      final current = state;

      if (current is! PlaylistLoaded) return "State lỗi";

      final playlists = List<PlaylistModel>.from(current.playlists);

      final index =
          playlists.indexWhere((p) => p.id == playlistId);

      if (index == -1) return "Không tìm thấy playlist";

      final playlist = playlists[index];

      final newSongIds = List<String>.from(playlist.songIds);

      final item = newSongIds.removeAt(oldIndex);
      newSongIds.insert(newIndex, item);

      await _storageService.reorderSongs(
          playlistId, oldIndex, newIndex);

      playlists[index] =
          playlist.copyWith(songIds: newSongIds);

      emit(PlaylistLoaded(playlists));

      return null;
    } catch (e) {
      final message = 'Lỗi khi sắp xếp: $e';
      emit(PlaylistError(message));
      return message;
    }
  }

  /// RENAME
  Future<String?> renamePlaylist(String playlistId, String newName) async {
    try {
      final current = state;
      if (current is! PlaylistLoaded) return "State lỗi";

      await _storageService.renamePlaylist(playlistId, newName);

      final playlists = List<PlaylistModel>.from(current.playlists);
      final index = playlists.indexWhere((p) => p.id == playlistId);
      if (index == -1) return "Không tìm thấy playlist";

      playlists[index] = playlists[index].copyWith(name: newName);
      emit(PlaylistLoaded(playlists));

      return null;
    } catch (e) {
      final message = e.toString();
      emit(PlaylistError(message));
      return message;
    }
  }

  /// DELETE
  Future<String?> deletePlaylist(String playlistId) async {
    try {
      final current = state;

      if (current is! PlaylistLoaded) return "State lỗi";

      await _storageService.deletePlaylist(playlistId);

      final updated = current.playlists
          .where((p) => p.id != playlistId)
          .toList();

      emit(PlaylistLoaded(updated));

      return null;
    } catch (e) {
      final message = 'Lỗi khi xóa playlist: $e';
      emit(PlaylistError(message));
      return message;
    }
  }
}