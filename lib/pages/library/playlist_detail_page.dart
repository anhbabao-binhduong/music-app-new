import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../presentation/bloc/playlist/playlist_cubit.dart';
import '../../../presentation/bloc/player/player_bloc.dart';
import '../../../presentation/bloc/player/player_event.dart';
import '../../../data/local_music_data.dart'; // Import để tra cứu thông tin bài hát từ ID

class PlaylistDetailPage extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailPage({super.key, required this.playlistId});

  // Dialog xác nhận xóa
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xóa danh sách?", style: TextStyle(color: Colors.white)),
        content: const Text("Bạn có chắc chắn muốn xóa danh sách phát này không?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              // Gọi Cubit để xóa
              context.read<PlaylistCubit>().deletePlaylist(playlistId);
              Navigator.pop(ctx); // Đóng dialog
              Navigator.pop(context); // Thoát về trang Library
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Nền đen sâu
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmDialog(context),
          )
        ],
      ),
      body: BlocBuilder<PlaylistCubit, PlaylistState>(
        builder: (context, state) {
          if (state is! PlaylistLoaded) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          // Tìm playlist hiện tại trong danh sách của State
          final playlist = state.playlists.firstWhere(
            (p) => p.id == playlistId, 
            orElse: () => state.playlists.first, // Fallback an toàn
          );

          // Nếu bị xóa hoặc rỗng
          if (playlist.id != playlistId) {
             return const Center(child: Text("Danh sách không tồn tại", style: TextStyle(color: Colors.white)));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER PLAYLIST
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  playlist.name,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "${playlist.songIds.length} bài hát",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),

              // DANH SÁCH BÀI HÁT
              Expanded(
                child: playlist.songIds.isEmpty
                  ? const Center(child: Text("Danh sách này chưa có bài hát nào", style: TextStyle(color: Colors.grey)))
                  : Theme(
                      // Chỉnh theme cho ReorderableListView đỡ bị nền trắng khi kéo
                      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
                      child: ReorderableListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: playlist.songIds.length,
                        onReorder: (oldIndex, newIndex) {
                          context.read<PlaylistCubit>().reorderSongs(playlistId, oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final songId = playlist.songIds[index];
                          
                          // Tìm thông tin bài hát gốc từ mảng localPlaylist dựa vào ID
                          final song = localPlaylist.firstWhere(
                            (s) => s.id == songId, 
                            orElse: () => localPlaylist[0], // Tránh lỗi null
                          );

                          return Dismissible(
                            key: ValueKey(songId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.redAccent,
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              context.read<PlaylistCubit>().removeSongFromPlaylist(playlistId, songId);
                            },
                            child: ListTile(
                              key: ValueKey(songId),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: song.artUri?.toString() ?? '',
                                  width: 50, height: 50, fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 50, height: 50, color: Colors.white12,
                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                  ),
                                ),
                              ),
                              title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(song.artist ?? 'Unknown', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.drag_handle_rounded, color: Colors.white24),
                              onTap: () {
                                // Ấn vào thì phát luôn bài này
                                context.read<PlayerBloc>().add(PlayNextEvent(song));
                              },
                            ),
                          );
                        },
                      ),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}