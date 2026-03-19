import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/playlist_model.dart';
import '../../../presentation/bloc/playlist/playlist_cubit.dart';
import 'playlist_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlaylistCubit>().loadPlaylists();
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tạo danh sách mới', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final error = await context.read<PlaylistCubit>().createNewPlaylist(name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (error == null) {
                _showSnack('Đã tạo "$name"');
              } else {
                _showSnack(error, isError: true);
              }
            },
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPlaylists() async {
    context.read<PlaylistCubit>().loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Thư viện', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 24),
            onPressed: _refreshPlaylists,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: _showCreatePlaylistDialog,
          ),
        ],
      ),
      body: BlocConsumer<PlaylistCubit, PlaylistState>(
        listener: (context, state) {
          if (state is PlaylistError) {
            _showSnack(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is PlaylistInitial) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          if (state is PlaylistLoaded) {
            final playlists = state.playlists.reversed.toList();

            return RefreshIndicator(
              onRefresh: _refreshPlaylists,
              child: playlists.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.library_music_rounded, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                const Text('Chưa có danh sách phát nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                const SizedBox(height: 8),
                                const Text('Nhấn dấu + để tạo hoặc kéo xuống để tải lại', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 30),
                            ),
                            title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${playlist.songIds.length} bài hát', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaylistDetailPage(playlistId: playlist.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            );
          }

          if (state is PlaylistError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42),
                    const SizedBox(height: 12),
                    Text(state.message, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refreshPlaylists,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tải lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
