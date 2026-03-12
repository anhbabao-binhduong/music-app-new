import 'package:audio_service/audio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<MediaItem> localPlaylist = [];
class SongRepository {
  // Lấy instance của Supabase
  final _supabase = Supabase.instance.client;

  Future<List<MediaItem>> fetchSongsFromSupabase() async {
    try {
      // Query toàn bộ dữ liệu từ bảng 'songs'
      final List<dynamic> response = await _supabase.from('songs').select();

      // Chuyển đổi dữ liệu JSON từ Supabase thành List<MediaItem>
      return response.map((song) {
        return MediaItem(
          id: song['audio_url'], // Dùng URL làm ID cho AudioService
          title: song['title'],
          artist: song['artist'],
          album: song['album'],
          artUri: Uri.parse(song['art_url'] ?? 'https://picsum.photos/400'),
          duration: Duration(seconds: song['duration_seconds'] ?? 0),
        );
      }).toList();
      
    } catch (e) {
      print('Lỗi khi tải nhạc: $e');
      return []; // Trả về list rỗng nếu lỗi
    }
  }
}