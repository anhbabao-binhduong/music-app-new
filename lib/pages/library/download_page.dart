import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/pages/player/player_page.dart';
import 'package:music_app/data/local_music_data.dart';
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

  Widget _buildSongCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<DownloadCubit, List<String>>(
        builder: (context, downloadedIds) {
          String normalize(String url) => url.split('/').last;

          final downloadedSongs = downloadedIds.isEmpty ? <MediaItem>[] : localPlaylist.where((song) {
            final songFile = normalize(song.id);
            return downloadedIds.any((id) => normalize(id) == songFile);
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    backgroundColor: const Color(0xFF121212),
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                      title: const Text(
                        'Nhạc đã tải',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF121212)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF004D40).withValues(alpha: 0.3),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (downloadedSongs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Icon(Icons.download_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Chưa có bài hát nào trong máy',
                              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text('Tải nhạc để nghe khi không có mạng', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = downloadedSongs[index];
                            return _buildSongCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: item.artUri != null
                                        ? Image.network(item.artUri.toString(), width: 52, height: 52, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _placeholder())
                                        : _placeholder(),
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.artist ?? 'Unknown Artist',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 22),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: const Color(0xFF1E1E1E),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: const Text("Xóa khỏi máy?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        content: Text("Bạn có chắc chắn muốn xóa bài hát đã tải này không?", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                                        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text("Hủy", style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                                              foregroundColor: Colors.redAccent,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
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
                                            child: const Text("Xóa", style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                onTap: () => _playSongs(downloadedSongs, index),
                              ),
                            );
                          },
                          childCount: downloadedSongs.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2A3E), Color(0xFF1C1C2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.music_note_rounded,
            color: Colors.white.withValues(alpha: 0.2), size: 24),
      );
}
