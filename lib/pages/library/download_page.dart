import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/pages/player/player_page.dart';
import 'package:music_app/data/local_music_data.dart';
import 'package:music_app/pages/home/widgets/song_cards.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nhạc đã tải',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<DownloadCubit, List<String>>(
        builder: (context, downloadedIds) {
          if (downloadedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài hát nào trong mục tải',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          String normalize(String url) => url.split('/').last;

          final downloadedSongs = localPlaylist.where((song) {
            final songFile = normalize(song.id);

            return downloadedIds.any((id) => normalize(id) == songFile);
          }).toList();
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: downloadedSongs.length,
            itemBuilder: (context, index) {
              final item = downloadedSongs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ArtImage(uri: item.artUri, size: 56),
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
                        title: const Text("Xóa khỏi máy?", style: TextStyle(color: Colors.white)),
                        content: const Text("Bạn có chắc chắn muốn xóa bài hát đã tải này không?", style: TextStyle(color: Colors.grey)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () async {
                              try {
                                await context.read<DownloadCubit>().toggleDownload(item);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                  ..removeCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              }
                              if (context.mounted) Navigator.pop(ctx);
                            },
                            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () => _playSongs(downloadedSongs, index),
              );
            },
          );
        },
      ),
    );
  }
}
