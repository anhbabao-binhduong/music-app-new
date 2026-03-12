import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/services/playlist_storage_service.dart';
import 'package:music_app/data/models/playlist_model.dart';

part 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  // Lấy ra service lưu trữ của bạn thông qua getIt
  final PlaylistStorageService _storageService = getIt<PlaylistStorageService>();

  PlaylistCubit() : super(PlaylistInitial()) {
    loadPlaylists(); // Tự động load danh sách khi khởi tạo Cubit
  }

  // 1. Tải toàn bộ danh sách phát từ Database
  void loadPlaylists() {
    try {
      final playlists = _storageService.allPlaylists;
      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError(e.toString()));
    }
  }

  // 2. Tạo một danh sách phát (Playlist) HOÀN TOÀN MỚI
  Future<void> createNewPlaylist(String name) async {
    try {
      await _storageService.createPlaylist(name);
      loadPlaylists(); 
    } catch (e) {
      emit(PlaylistError("Lỗi khi tạo danh sách phát"));
    }
  }

  // 3. Vừa tạo danh sách phát mới VÀ thêm bài hát ngay lập tức
  Future<void> createPlaylistAndAddSong(String name, String songId) async {
    try {
      // Nhận ID từ hàm tạo mới
      final newId = await _storageService.createPlaylist(name);
      
      // Thêm bài hát vào đúng ID đó
      await _storageService.addSongToPlaylist(newId, songId);
      
      loadPlaylists(); 
    } catch (e) {
      emit(PlaylistError("Không thể tạo danh sách phát"));
    }
  }

  // 4. Chỉ thêm bài hát vào một playlist đã có sẵn
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _storageService.addSongToPlaylist(playlistId, songId);
      loadPlaylists(); // Refresh lại nếu cần
    } catch (e) {
      emit(PlaylistError("Lỗi khi thêm bài hát"));
    }
  }

  // 5. Xóa 1 bài hát khỏi playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _storageService.removeSongFromPlaylist(playlistId, songId);
      loadPlaylists();
    } catch (e) {
      emit(PlaylistError("Lỗi khi xóa bài hát"));
    }
  }

  // 6. Kéo thả đổi vị trí bài hát
  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    try {
      await _storageService.reorderSongs(playlistId, oldIndex, newIndex);
      loadPlaylists();
    } catch (e) {
      emit(PlaylistError("Lỗi khi sắp xếp"));
    }
  }

  // 7. Xóa toàn bộ Playlist
  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _storageService.deletePlaylist(playlistId);
      loadPlaylists();
    } catch (e) {
      emit(PlaylistError("Lỗi khi xóa danh sách phát"));
    }
  }
}