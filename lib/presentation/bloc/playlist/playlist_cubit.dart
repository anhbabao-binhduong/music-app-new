import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/services/playlist_storage_service.dart';
import 'package:music_app/data/models/playlist_model.dart';

part 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  final PlaylistStorageService _storageService = getIt<PlaylistStorageService>();

  PlaylistCubit() : super(PlaylistInitial()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    try {
      final playlists = await _storageService.fetchPlaylists();
      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<String?> createNewPlaylist(String name) async {
    try {
      await _storageService.createPlaylist(name);
      await loadPlaylists();
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(PlaylistError(message));
      return message;
    }
  }

  Future<String?> createPlaylistAndAddSong(String name, String songId) async {
    try {
      final newId = await _storageService.createPlaylist(name);
      await _storageService.addSongToPlaylist(newId, songId);
      await loadPlaylists();
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(PlaylistError(message));
      return message;
    }
  }

  Future<String?> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _storageService.addSongToPlaylist(playlistId, songId);
      await loadPlaylists();
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', 'Lỗi khi thêm bài hát: ');
      emit(PlaylistError(message));
      return message;
    }
  }

  Future<String?> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _storageService.removeSongFromPlaylist(playlistId, songId);
      await loadPlaylists();
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', 'Lỗi khi xóa bài hát: ');
      emit(PlaylistError(message));
      return message;
    }
  }

  Future<String?> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    try {
      await _storageService.reorderSongs(playlistId, oldIndex, newIndex);
      await loadPlaylists();
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', 'Lỗi khi sắp xếp: ');
      emit(PlaylistError(message));
      return message;
    }
  }

  Future<String?> deletePlaylist(String playlistId) async {
    try {
      await _storageService.deletePlaylist(playlistId);
      await loadPlaylists();
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', 'Lỗi khi xóa danh sách phát: ');
      emit(PlaylistError(message));
      return message;
    }
  }
}
