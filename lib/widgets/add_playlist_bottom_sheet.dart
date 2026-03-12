import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
// Import Cubit của bạn
// import '../presentation/bloc/playlist/playlist_cubit.dart';

void showAddToPlaylistBottomSheet(BuildContext context, MediaItem song) {
  final TextEditingController playlistNameController = TextEditingController();

  // Hàm hiển thị Popup nhập tên
  void showCreateDialog() {
    Navigator.pop(context); // Tắt Bottom Sheet màu xám
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tạo danh sách phát mới', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: playlistNameController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên danh sách...',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              final name = playlistNameController.text.trim();
              if (name.isNotEmpty) {
                // GỌI XUỐNG CUBIT (DB) Ở ĐÂY
                // context.read<PlaylistCubit>().createPlaylistAndAddSong(name, song);
                
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm vào $name!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Tạo & Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Khởi chạy Bottom Sheet
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1B1B1B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      // Dùng BlocBuilder để lắng nghe danh sách playlist từ Cubit
      return BlocBuilder<PlaylistCubit, PlaylistState>(
        builder: (context, state) {
          // Giả sử state.playlists là danh sách lấy từ DB
          // final playlists = state is PlaylistLoaded ? state.playlists : [];
          final playlists = []; // Giả lập rỗng để test

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Thêm vào danh sách phát", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),

                // 1. Nút Tạo mới luôn hiện
                ListTile(
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                  title: const Text('Tạo danh sách phát mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: showCreateDialog, // Mở hộp thoại gõ tên
                ),
                const Divider(color: Colors.white12, indent: 20, endIndent: 20),

                // 2. Hiển thị danh sách Playlist đã có (Nếu rỗng thì báo)
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text('Bạn chưa có danh sách phát nào', style: TextStyle(color: Colors.white54)),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        // final pl = playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.queue_music, color: Colors.grey),
                          // title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                          title: const Text("Tên Playlist DB"),
                          onTap: () {
                             // GỌI HÀM THÊM BÀI VÀO PLAYLIST CŨ TẠI ĐÂY
                             // context.read<PlaylistCubit>().addSongToPlaylist(pl.id, song);
                             Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}