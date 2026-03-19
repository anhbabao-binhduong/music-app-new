import 'package:audio_service/audio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<MediaItem> localPlaylist = [];

MediaItem? findSongById(String songId) {
  for (final song in localPlaylist) {
    if (song.id == songId) return song;
  }
  return null;
}

class SongRepository {
  final _supabase = Supabase.instance.client;

  Future<List<MediaItem>> fetchSongsFromSupabase() async {
    try {
      final List<dynamic> response = await _supabase.from('songs').select();

      return response.map((song) {
        return MediaItem(
          id: song['audio_url'],
          title: song['title'],
          artist: song['artist'],
          album: song['album'],
          artUri: Uri.parse(song['art_url'] ?? 'https://picsum.photos/400'),
          duration: Duration(seconds: song['duration_seconds'] ?? 0),
        );
      }).toList();
    } catch (e) {
      print('Lỗi khi tải nhạc: $e');
      return [];
    }
  }
}
