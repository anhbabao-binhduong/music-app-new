import 'package:audio_service/audio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<MediaItem> localPlaylist = [];

MediaItem? findSongById(String idOrUrl) {
  for (final song in localPlaylist) {
    // ✅ match theo ID
    if (song.id == idOrUrl) return song;

    // ✅ fallback cho dữ liệu cũ (Cloudinary)
    if (song.extras?['url'] == idOrUrl) return song;
  }
  return null;
}

class SongRepository {
  final _supabase = Supabase.instance.client;

  String resolveAudioUrl(String audioPath) {
    if (audioPath.startsWith('http')) return audioPath.trim();
    return _supabase.storage.from('songs').getPublicUrl(audioPath.trim());
  }

  Future<List<MediaItem>> fetchSongsFromSupabase() async {
    try {
      final List<dynamic> response =
          await _supabase.from('songs').select();

      final songs = response.map<MediaItem?>((song) {
        final audioPath = song['audio_path'];

        if (audioPath == null || audioPath.toString().isEmpty) {
          return null;
        }

        final publicUrl = resolveAudioUrl(audioPath.toString());
        print('🎵 Resolved URL: $publicUrl');

        if (publicUrl.isEmpty) {
          print("❌ URL rỗng: $audioPath");
          return null;
        }

        final artUrl = (song['art_url'] != null &&
                song['art_url'].toString().isNotEmpty)
            ? song['art_url']
            : 'https://picsum.photos/400';

        return MediaItem(
          id: song['id'].toString(), // ✅ QUAN TRỌNG
          title: song['title'] ?? '',
          artist: song['artist'] ?? '',
          album: song['album'] ?? '',
          artUri: Uri.parse(artUrl),
          duration: Duration(
              seconds: song['duration_seconds'] ?? 0),

          extras: {
            'url': publicUrl, // ✅ URL audio thật
          },
        );
      }).whereType<MediaItem>().toList();

      localPlaylist = songs;

      return songs;
    } catch (e) {
      print('Lỗi khi tải nhạc: $e');
      return [];
    }
  }
}