import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/pages/player/player_page.dart';

// Import Cubit và biến localPlaylist chứa danh sách nhạc tổng
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:music_app/data/local_music_data.dart'; 
import 'package:music_app/pages/home/widgets/song_cards.dart'; // Để dùng ArtImage nếu có

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  Future<void> _playSongs(List<MediaItem> items, int index) async {
    final validItems = items.where((s) {
      final url = s.extras?['url'] as String?;
      return url != null && url.isNotEmpty;
    }).toList();

    if (validItems.isEmpty) return;

    final targetSong = items[index];
    final newIndex = validItems.indexWhere((s) => s.id == targetSong.id);
    if (newIndex == -1) return;

    context.read<PlayerBloc>().add(LoadPlaylistEvent(validItems, startIndex: newIndex));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerPage(song: validItems[newIndex]),
      ),
    );
  }

  String _normalizeAudioUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url.trim();
    const base = 'https://pdbkojvgjrvnzqmerwmz.supabase.co/storage/v1/object/public/songs/';
    return '$base${url.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Màu kBg của bạn
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Bài hát yêu thích',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      // BlocBuilder giúp màn hình tự động cập nhật nếu bạn bỏ thả tim bài nào đó
      body: BlocBuilder<FavoriteCubit, List<String>>(
        builder: (context, favoriteIds) {
          // Nếu danh sách ID rỗng
          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài hát yêu thích nào',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Phép thuật ở đây: Lọc ra những bài hát trong localPlaylist có ID nằm trong danh sách favoriteIds
          String normalize(String url) => url.split('/').last;

          final favoriteSongs = localPlaylist.where((song) {
            final songFile = normalize(song.id);

            return favoriteIds.any((id) => normalize(id) == songFile);
          }).toList();

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120), // Chừa chỗ cho MiniPlayer
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final item = favoriteSongs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ArtImage(uri: item.artUri, size: 56), // Widget ArtImage của bạn
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.artist ?? 'Unknown Artist',
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF2A2A2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text("Xóa bài hát?", style: TextStyle(color: Colors.white)),
                        content: const Text("Bạn có chắc chắn muốn xóa bài hát này khỏi danh sách yêu thích không?", style: TextStyle(color: Colors.grey)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              context.read<FavoriteCubit>().toggleFavorite(item.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () => _playSongs(favoriteSongs, index),
              );
            },
          );
        },
      ),
    );
  }
}