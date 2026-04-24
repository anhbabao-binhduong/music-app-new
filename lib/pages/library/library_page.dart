import 'dart:ui';
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

  Widget _LibraryThumbnail({
    required List<Color> colors,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 26),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tạo danh sách mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên danh sách...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5)),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            child: const Text('Tạo', style: TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi tên danh sách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          onTap: () => controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5)),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == playlist.name) {
                Navigator.pop(ctx);
                return;
              }

              final error = await context.read<PlaylistCubit>().renamePlaylist(playlist.id, newName);

              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (error == null) {
                _showSnack('Đã đổi tên thành "$newName"');
              } else {
                _showSnack(error, isError: true);
              }
            },
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(PlaylistModel playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _LibraryThumbnail(
                    colors: const [Color(0xFF4A148C), Color(0xFF1A237E)],
                    icon: Icons.queue_music_rounded,
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(playlist.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${playlist.songIds.length} bài hát',
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
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

  Widget _buildLibraryCard({
    required Widget child,
  }) {
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
      body: BlocConsumer<PlaylistCubit, PlaylistState>(
        listener: (context, state) {
          if (state is PlaylistError) {
            _showSnack(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _refreshPlaylists,
            color: const Color(0xFF1976D2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // ── Màn hình nền mờ Header ───────────────────────────────────────────
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      backgroundColor: const Color(0xFF121212),
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.white),
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                        title: const Text(
                          'Thư viện',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background gradient nghệ thuật
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0D47A1), Color(0xFF121212)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // Thêm chi tiết trang trí mờ
                            Positioned(
                              right: -50,
                              top: -50,
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1976D2).withValues(alpha: 0.2),
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
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                          onPressed: _refreshPlaylists,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 26),
                          onPressed: _showCreatePlaylistDialog,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),

                    // Nội dung
                    if (state is PlaylistInitial)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF1976D2))),
                      )
                    else if (state is PlaylistError)
                      SliverFillRemaining(
                        child: Center(
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
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _refreshPlaylists,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white12,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Tải lại'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (state is PlaylistLoaded)
                      BlocBuilder<HistoryCubit, List<MediaItem>>(
                        builder: (context, history) {
                          return BlocBuilder<FavoriteCubit, List<String>>(
                            builder: (context, favoriteIds) {
                              return BlocBuilder<DownloadCubit, List<String>>(
                                builder: (context, downloadIds) {
                                  final playlists = state.playlists.reversed.toList();
                                  final itemCount = 5 + (_isPlaylistExpanded ? (playlists.isEmpty ? 1 : playlists.length) : 0);

                                  return SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          if (index == 0) {
                                            return _buildLibraryCard(
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: _LibraryThumbnail(
                                                  colors: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
                                                  icon: Icons.history_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                title: const Text('Lịch sử nghe',
                                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                                subtitle: Text(
                                                  history.isEmpty ? 'Chưa có bài nào' : '${history.length} bài gần đây',
                                                  style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                                                ),
                                              ),
                                            );
                                          }

                                          if (index == 1) {
                                            return _buildLibraryCard(
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: _LibraryThumbnail(
                                                  colors: const [Color(0xFFD81B60), Color(0xFF880E4F)],
                                                  icon: Icons.favorite_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                title: const Text('Bài hát yêu thích',
                                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                                subtitle: Text('${favoriteIds.length} bài hát',
                                                    style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                                                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const FavoritePage()),
                                                ),
                                              ),
                                            );
                                          }

                                          if (index == 2) {
                                            return _buildLibraryCard(
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: _LibraryThumbnail(
                                                  colors: const [Color(0xFF2E7D32), Color(0xFF004D40)],
                                                  icon: Icons.download_done_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                title: const Text('Nhạc đã tải',
                                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                                subtitle: Text('${downloadIds.length} bài hát',
                                                    style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                                                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const DownloadPage()),
                                                ),
                                              ),
                                            );
                                          }

                                          if (index == 3) {
                                            return const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 16),
                                              child: Divider(color: Colors.white12, height: 1),
                                            );
                                          }

                                          if (index == 4) {
                                            return _buildLibraryCard(
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: _LibraryThumbnail(
                                                  colors: const [Color(0xFF5E35B1), Color(0xFF311B92)],
                                                  icon: Icons.queue_music_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                title: const Text('Danh sách phát',
                                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                                subtitle: Text('${playlists.length} danh sách',
                                                    style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                                                trailing: Icon(
                                                  _isPlaylistExpanded
                                                      ? Icons.keyboard_arrow_down_rounded
                                                      : Icons.keyboard_arrow_right_rounded,
                                                  color: Colors.white54,
                                                  size: 28,
                                                ),
                                                onTap: () => setState(() => _isPlaylistExpanded = !_isPlaylistExpanded),
                                              ),
                                            );
                                          }

                                          if (_isPlaylistExpanded) {
                                            if (playlists.isEmpty) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 24, bottom: 48),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(20),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Colors.white.withValues(alpha: 0.05),
                                                        ),
                                                        child: Icon(Icons.library_music_rounded,
                                                            size: 48, color: Colors.white.withValues(alpha: 0.2)),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      const Text('Chưa có danh sách phát nào',
                                                          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
                                                      const SizedBox(height: 4),
                                                      const Text('Nhấn dấu + ở trên để tạo',
                                                          style: TextStyle(color: Colors.white38, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }

                                            final playlist = playlists[index - 5];
                                            return Padding(
                                              padding: const EdgeInsets.only(left: 24),
                                              child: _buildLibraryCard(
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                  leading: _LibraryThumbnail(
                                                    colors: const [Color(0xFF2A2A3E), Color(0xFF1C1C2E)],
                                                    icon: Icons.music_note_rounded,
                                                    iconColor: Colors.white54,
                                                  ),
                                                  title: Text(playlist.name,
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w600)),
                                                  subtitle: Text('${playlist.songIds.length} bài hát',
                                                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                                                  trailing: IconButton(
                                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 22),
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
                                              ),
                                            );
                                          }

                                          return const SizedBox.shrink();
                                        },
                                        childCount: itemCount,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}