import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/pages/library/favorite_page.dart';
import 'package:music_app/pages/library/download_page.dart';
import 'package:music_app/pages/library/history_page.dart';
import '../../../data/models/playlist_model.dart';
import '../../../presentation/bloc/playlist/playlist_cubit.dart';
import '../../../presentation/bloc/favorite/favorite_cubit.dart';
import '../../../presentation/bloc/download/download_cubit.dart';
import '../../../presentation/bloc/history/history_cubit.dart';
import 'playlist_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _isPlaylistExpanded = true;

  // ignore: non_constant_identifier_names
  Widget _LibraryThumbnail({
    required List<Color> colors,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }

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

  Future<void> _showRenamePlaylistDialog(PlaylistModel playlist) async {
    final controller = TextEditingController(text: playlist.name);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đổi tên danh sách', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          onTap: () => controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          ),
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
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
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == playlist.name) {
                Navigator.pop(ctx);
                return;
              }

              final error = await context
                  .read<PlaylistCubit>()
                  .renamePlaylist(playlist.id, newName);

              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (error == null) {
                _showSnack('Đã đổi tên thành "$newName"');
              } else {
                _showSnack(error, isError: true);
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(PlaylistModel playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(playlist.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${playlist.songIds.length} bài hát',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white70),
              title: const Text('Đổi tên', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showRenamePlaylistDialog(playlist);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
        title: const Text('Thư viện',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
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

            return BlocBuilder<HistoryCubit, List<MediaItem>>(
              builder: (context, history) {
                return BlocBuilder<FavoriteCubit, List<String>>(
                  builder: (context, favoriteIds) {
                    return BlocBuilder<DownloadCubit, List<String>>(
                      builder: (context, downloadIds) {
                        return RefreshIndicator(
                          onRefresh: _refreshPlaylists,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: 5 + (_isPlaylistExpanded ? (playlists.isEmpty ? 1 : playlists.length) : 0),
                            itemBuilder: (context, index) {
                              // index 0: Lịch sử nghe
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _LibraryThumbnail(
                                      colors: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
                                      icon: Icons.history_rounded,
                                      iconColor: Colors.white,
                                    ),
                                    title: const Text('Lịch sử nghe',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      history.isEmpty ? 'Chưa có bài nào' : '${history.length} bài gần đây',
                                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HistoryPage(),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // index 1: Bài hát yêu thích
                              if (index == 1) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _LibraryThumbnail(
                                      colors: const [Color(0xFFB71C1C), Color(0xFF880E4F)],
                                      icon: Icons.favorite_rounded,
                                      iconColor: Colors.white,
                                    ),
                                    title: const Text('Bài hát yêu thích',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    subtitle: Text('${favoriteIds.length} bài hát',
                                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const FavoritePage()),
                                    ),
                                  ),
                                );
                              }

                              // index 2: Nhạc đã tải
                              if (index == 2) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _LibraryThumbnail(
                                      colors: const [Color(0xFF1B5E20), Color(0xFF00695C)],
                                      icon: Icons.download_done_rounded,
                                      iconColor: Colors.white,
                                    ),
                                    title: const Text('Nhạc đã tải',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    subtitle: Text('${downloadIds.length} bài hát',
                                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const DownloadPage()),
                                    ),
                                  ),
                                );
                              }

                              // index 3: Divider
                              if (index == 3) {
                                return const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Divider(color: Colors.white12),
                                    SizedBox(height: 8),
                                  ],
                                );
                              }

                              // index 4: Header Danh sách phát
                              if (index == 4) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _LibraryThumbnail(
                                    colors: const [Color(0xFF4A148C), Color(0xFF1A237E)],
                                    icon: Icons.queue_music_rounded,
                                    iconColor: Colors.white,
                                  ),
                                  title: const Text('Danh sách phát',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('${playlists.length} danh sách',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ),
                                  trailing: Icon(
                                    _isPlaylistExpanded
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_right_rounded,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                  onTap: () => setState(() => _isPlaylistExpanded = !_isPlaylistExpanded),
                                );
                              }

                              // index 5+: playlist con
                              if (_isPlaylistExpanded) {
                                if (playlists.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.library_music_rounded,
                                              size: 48, color: Colors.white.withValues(alpha: 0.2)),
                                          const SizedBox(height: 12),
                                          const Text('Chưa có danh sách phát nào',
                                              style: TextStyle(color: Colors.grey, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          const Text('Nhấn dấu + để tạo',
                                              style: TextStyle(color: Colors.white38, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final playlist = playlists[index - 5];
                                return Padding(
                                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _LibraryThumbnail(
                                      colors: const [Color(0xFF1C1C2E), Color(0xFF2A2A3E)],
                                      icon: Icons.music_note_rounded,
                                      iconColor: Colors.white54,
                                    ),
                                    title: Text(playlist.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('${playlist.songIds.length} bài hát',
                                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                                      onPressed: () => _showPlaylistOptions(playlist),
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlaylistDetailPage(playlistId: playlist.id),
                                      ),
                                    ),
                                    onLongPress: () => _showPlaylistOptions(playlist),
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
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
                    Text(state.message,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center),
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