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

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _scheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;

  Color get _bg => _theme.scaffoldBackgroundColor;
  Color get _card => _scheme.surface;
  Color get _textPrimary => _scheme.onSurface;
  Color get _textSecondary => _scheme.onSurface.withValues(alpha: 0.66);
  Color get _divider => _scheme.outline.withValues(alpha: _isDark ? 0.35 : 0.5);
  Color get _accent => _scheme.primary;

  Widget _libraryThumbnail({
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
            color: colors.first.withValues(alpha: 0.35),
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
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tạo danh sách mới',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _textPrimary),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên danh sách...',
            hintStyle: TextStyle(color: _textSecondary),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
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
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đổi tên danh sách',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _textPrimary),
          autofocus: true,
          onTap: () => controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle: TextStyle(color: _textSecondary),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == playlist.name) {
                Navigator.pop(ctx);
                return;
              }

              final error =
                  await context.read<PlaylistCubit>().renamePlaylist(playlist.id, newName);

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
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: _divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _libraryThumbnail(
                    colors: const [Color(0xFF4A148C), Color(0xFF1A237E)],
                    icon: Icons.queue_music_rounded,
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlist.songIds.length} bài hát',
                          style: TextStyle(color: _textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _divider, height: 1),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: _accent),
              title: Text('Đổi tên', style: TextStyle(color: _textPrimary)),
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

  Widget _buildLibraryCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: _isDark ? 0.16 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
      backgroundColor: _bg,
      body: BlocConsumer<PlaylistCubit, PlaylistState>(
        listener: (context, state) {
          if (state is PlaylistError) {
            _showSnack(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _refreshPlaylists,
            color: _accent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // ── Header ────────────────────────────────────────────
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      backgroundColor: _bg,
                      elevation: 0,
                      iconTheme: IconThemeData(color: _textPrimary),
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                        title: Text(
                          'Thư viện',
                          style: TextStyle(
                            color: _isDark ? Colors.white : _textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _scheme.primary.withValues(alpha: _isDark ? 0.62 : 0.42),
                                    _scheme.secondary.withValues(alpha: _isDark ? 0.46 : 0.26),
                                    _bg,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              right: -50,
                              top: -50,
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                   color: (_isDark ? Colors.white : _scheme.primary)
                                       .withValues(alpha: _isDark ? 0.15 : 0.12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(Icons.refresh_rounded, color: _textPrimary, size: 24),
                          onPressed: _refreshPlaylists,
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded, color: _textPrimary, size: 26),
                          onPressed: _showCreatePlaylistDialog,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),

                    // ── Nội dung ──────────────────────────────────────────
                    if (state is PlaylistInitial)
                      SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: _accent)),
                      )
                    else if (state is PlaylistError)
                      SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Colors.redAccent, size: 42),
                                const SizedBox(height: 12),
                                Text(
                                  state.message,
                                  style: const TextStyle(color: Colors.redAccent),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _refreshPlaylists,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
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
                                  final itemCount = 5 +
                                      (_isPlaylistExpanded
                                          ? (playlists.isEmpty ? 1 : playlists.length)
                                          : 0);

                                  return SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          if (index == 0) {
                                            return _buildLibraryCard(
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                 leading: _libraryThumbnail(
                                                  colors: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
                                                  icon: Icons.history_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                 title: Text(
                                                   'Lịch sử nghe',
                                                   style: TextStyle(
                                                     color: _textPrimary,
                                                     fontSize: 16,
                                                     fontWeight: FontWeight.w700,
                                                   ),
                                                 ),
                                                subtitle: Text(
                                                  history.isEmpty
                                                      ? 'Chưa có bài nào'
                                                      : '${history.length} bài gần đây',
                                                   style: TextStyle(
                                                     color: _textSecondary,
                                                     fontSize: 13,
                                                     fontWeight: FontWeight.w500,
                                                   ),
                                                ),
                                                 trailing: Icon(Icons.arrow_forward_ios_rounded,
                                                     color: _textSecondary, size: 16),
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
                                                contentPadding:
                                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                 leading: _libraryThumbnail(
                                                  colors: const [Color(0xFFD81B60), Color(0xFF880E4F)],
                                                  icon: Icons.favorite_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                 title: Text(
                                                   'Bài hát yêu thích',
                                                   style: TextStyle(
                                                     color: _textPrimary,
                                                     fontSize: 16,
                                                     fontWeight: FontWeight.w700,
                                                   ),
                                                 ),
                                                subtitle: Text(
                                                  '${favoriteIds.length} bài hát',
                                                  style: TextStyle(
                                                    color: _textSecondary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                trailing: Icon(Icons.arrow_forward_ios_rounded,
                                                    color: _textSecondary, size: 16),
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
                                                contentPadding:
                                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                 leading: _libraryThumbnail(
                                                  colors: const [Color(0xFF2E7D32), Color(0xFF004D40)],
                                                  icon: Icons.download_done_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                 title: Text(
                                                   'Nhạc đã tải',
                                                   style: TextStyle(
                                                     color: _textPrimary,
                                                     fontSize: 16,
                                                     fontWeight: FontWeight.w700,
                                                   ),
                                                 ),
                                                subtitle: Text(
                                                  '${downloadIds.length} bài hát',
                                                  style: TextStyle(
                                                    color: _textSecondary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                trailing: Icon(Icons.arrow_forward_ios_rounded,
                                                    color: _textSecondary, size: 16),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const DownloadPage()),
                                                ),
                                              ),
                                            );
                                          }

                                          if (index == 3) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              child: Divider(color: _divider, height: 1),
                                            );
                                          }

                                          if (index == 4) {
                                            return _buildLibraryCard(
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                 leading: _libraryThumbnail(
                                                  colors: const [Color(0xFF5E35B1), Color(0xFF311B92)],
                                                  icon: Icons.queue_music_rounded,
                                                  iconColor: Colors.white,
                                                ),
                                                 title: Text(
                                                   'Danh sách phát',
                                                   style: TextStyle(
                                                     color: _textPrimary,
                                                     fontSize: 16,
                                                     fontWeight: FontWeight.w700,
                                                   ),
                                                 ),
                                                subtitle: Text(
                                                  '${playlists.length} danh sách',
                                                  style: TextStyle(
                                                    color: _textSecondary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                trailing: Icon(
                                                  _isPlaylistExpanded
                                                      ? Icons.keyboard_arrow_down_rounded
                                                      : Icons.keyboard_arrow_right_rounded,
                                                  color: _textSecondary,
                                                  size: 28,
                                                ),
                                                onTap: () =>
                                                    setState(() => _isPlaylistExpanded = !_isPlaylistExpanded),
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
                                                           color: _divider,
                                                        ),
                                                         child: Icon(Icons.library_music_rounded,
                                                             size: 48, color: _textSecondary),
                                                      ),
                                                      const SizedBox(height: 16),
                                                       Text(
                                                         'Chưa có danh sách phát nào',
                                                         style: TextStyle(
                                                           color: _textPrimary,
                                                           fontSize: 15,
                                                           fontWeight: FontWeight.w500,
                                                         ),
                                                       ),
                                                      const SizedBox(height: 4),
                                                       Text(
                                                         'Nhấn dấu + ở trên để tạo',
                                                         style: TextStyle(color: _textSecondary, fontSize: 13),
                                                       ),
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
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                  leading: Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(14),
                                                       color: _bg,
                                                       border: Border.all(color: _divider),
                                                    ),
                                                     child: Icon(
                                                       Icons.music_note_rounded,
                                                       color: _textSecondary,
                                                       size: 26,
                                                     ),
                                                  ),
                                                  title: Text(
                                                    playlist.name,
                                                    style: TextStyle(
                                                      color: _textPrimary,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '${playlist.songIds.length} bài hát',
                                                    style: TextStyle(
                                                      color: _textSecondary,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  trailing: IconButton(
                                                     icon: Icon(Icons.more_vert_rounded,
                                                         color: _textSecondary, size: 22),
                                                    onPressed: () => _showPlaylistOptions(playlist),
                                                  ),
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PlaylistDetailPage(playlistId: playlist.id),
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