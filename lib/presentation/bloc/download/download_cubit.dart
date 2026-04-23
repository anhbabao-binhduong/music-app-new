import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DownloadCubit extends Cubit<List<String>> {
  final SupabaseClient _supabase = Supabase.instance.client;

  DownloadCubit() : super([]) {
    _loadDownloads();
    _supabase.auth.onAuthStateChange.listen((_) {
      _loadDownloads();
    });
  }

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<void> _loadDownloads() async {
    final uid = _uid;
    if (uid == null) {
      emit([]);
      return;
    }

    try {
      final response = await _supabase
          .from('downloads')
          .select('song_id')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final ids = (response as List)
          .map((row) => row['song_id']?.toString())
          .whereType<String>()
          .toList();

      emit(ids);
    } catch (e) {
      emit([]);
    }
  }

  Future<void> toggleDownload(MediaItem song) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để lưu nhạc đã tải');
    }

    final isDownloaded = state.contains(song.id);

    if (isDownloaded) {
      await _supabase
          .from('downloads')
          .delete()
          .eq('user_id', uid)
          .eq('song_id', song.id);
      await _loadDownloads();
      return;
    }

    await _supabase.from('downloads').insert({
      'user_id': uid,
      'song_id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'art_url': song.artUri?.toString(),
      'status': 'saved',
    });

    await _loadDownloads();
  }

  void clear() => emit([]);
}
