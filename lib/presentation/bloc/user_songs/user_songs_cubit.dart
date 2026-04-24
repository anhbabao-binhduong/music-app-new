import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_app/data/models/user_song_model.dart';
import 'package:music_app/data/local_music_data.dart';

class UserSongsCubit extends Cubit<List<UserSongModel>> {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserSongsCubit() : super([]);

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Load bài hát của user hiện tại (tất cả status)
  Future<void> loadMySongs() async {
    final uid = _uid;
    if (uid == null) {
      emit([]);
      return;
    }
    try {
      final response = await _supabase
          .from('user_songs')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final songs = (response as List)
          .map((e) => UserSongModel.fromJson(e))
          .toList();
      emit(songs);
    } catch (_) {
      emit([]);
    }
  }

  /// Load bài hát đã được approved (dùng cho Explore section)
  Future<List<UserSongModel>> loadApprovedSongs({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('user_songs')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(limit);

      final songs = (response as List)
          .map((e) => UserSongModel.fromJson(e))
          .toList();

      // Điền userSongsCache để findSongById có thể tìm thấy khi hiển thị trong playlist
      userSongsCache = songs.map((s) => s.toMediaItem()).toList();

      return songs;
    } catch (_) {
      return [];
    }
  }

  /// Xóa bài hát (chỉ chủ nhân mới được xóa)
  Future<void> deleteSong(UserSongModel song) async {
    try {
      // Xóa file từ Storage
      final audioPath = Uri.parse(song.audioUrl).pathSegments
          .skipWhile((s) => s != 'user-audio')
          .skip(1)
          .join('/');
      if (audioPath.isNotEmpty) {
        await _supabase.storage.from('user-audio').remove([audioPath]);
      }
      if (song.artUrl != null) {
        final coverPath = Uri.parse(song.artUrl!).pathSegments
            .skipWhile((s) => s != 'user-covers')
            .skip(1)
            .join('/');
        if (coverPath.isNotEmpty) {
          await _supabase.storage.from('user-covers').remove([coverPath]);
        }
      }

      // Xóa record trong DB
      await _supabase.from('user_songs').delete().eq('id', song.id);

      // Cập nhật state local
      emit(state.where((s) => s.id != song.id).toList());
    } catch (_) {
      // Lỗi im lặng – UI hiển thị SnackBar qua try/catch ở tầng UI
      rethrow;
    }
  }
}
