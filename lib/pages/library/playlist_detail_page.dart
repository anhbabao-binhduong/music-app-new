import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local_music_data.dart';
import '../../data/models/user_song_model.dart';
import '../../presentation/bloc/player/player_bloc.dart';
import '../../presentation/bloc/player/player_event.dart';
import '../../presentation/bloc/playlist/playlist_cubit.dart';
import '../../presentation/bloc/favorite/favorite_cubit.dart';
import '../../presentation/bloc/download/download_cubit.dart';
import '../player/player_page.dart';

// ─── Helper: kiểm tra ID có phải UUID không ──────────────────────────────────
bool _isUuid(String id) => RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(id);

// ─── PlaylistDetailPage ───────────────────────────────────────────────────────
class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  /// Cache: userSongId (UUID) → MediaItem, tải từ Supabase khi mở trang
  final Map<String, MediaItem> _userSongMap = {};
  bool _loadingUserSongs = false;

  @override
  void initState() {
    super.initState();
    // Lên lịch fetch sau frame đầu tiên để context đã có PlaylistCubit
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserSongs());
  }

  /// Lấy metadata của community songs (UUID IDs) trực tiếp từ Supabase
  Future<void> _fetchUserSongs() async {
    final state = context.read<PlaylistCubit>().state;
    if (state is! PlaylistLoaded) return;

    final matchIndex =
        state.playlists.indexWhere((p) => p.id == widget.playlistId);
    if (matchIndex == -1) return;

    final uuidIds = state.playlists[matchIndex].songIds
        .where(_isUuid)
        .toList();

    if (uuidIds.isEmpty) return;

    setState(() => _loadingUserSongs = true);

    try {
      final response = await Supabase.instance.client
          .from('user_songs')
          .select()
          .inFilter('id', uuidIds);

      final fetched = <String, MediaItem>{};
      for (final row in (response as List)) {
        try {
          final model = UserSongModel.fromJson(row);
          fetched[model.id] = model.toMediaItem();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _userSongMap.addAll(fetched);
          _loadingUserSongs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUserSongs = false);
    }
  }

  /// Tìm MediaItem từ songId:
  /// 1. Nếu là UUID → tìm trong _userSongMap (đã fetch từ Supabase)
  /// 2. Nếu là integer string → tìm trong localPlaylist / userSongsCache
  MediaItem? _resolveSong(String songId) {
    if (_isUuid(songId)) return _userSongMap[songId];
    return findSongById(songId);
  }

  // Dialog xác nhận xóa playlist
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa danh sách?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Bạn có chắc chắn muốn xóa danh sách phát này không?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<PlaylistCubit>().deletePlaylist(widget.playlistId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child:
                const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<PlaylistCubit, PlaylistState>(
        builder: (context, state) {
          if (state is! PlaylistLoaded) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          final matchIndex = state.playlists
              .indexWhere((p) => p.id == widget.playlistId);
          if (matchIndex == -1) {
            return const Center(
              child: Text('Danh sách không tồn tại',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final playlist = state.playlists[matchIndex];

          // Xây danh sách MediaItem có thể phát (bỏ qua null)
          final playableSongs = playlist.songIds
              .map(_resolveSong)
              .whereType<MediaItem>()
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Text(
                  playlist.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${playlist.songIds.length} bài hát',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 14),
                    ),
                    if (_loadingUserSongs) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white38),
                      ),
                    ],
                  ],
                ),
              ),

              // ── NÚT PHÁT TẤT CẢ ─────────────────────────────────────
              if (playableSongs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () {
                      context.read<PlayerBloc>().add(
                            LoadPlaylistEvent(playableSongs, startIndex: 0),
                          );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PlayerPage(song: playableSongs[0]),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill_rounded,
                            color: Colors.greenAccent, size: 36),
                        SizedBox(width: 8),
                        Text(
                          'Phát tất cả',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── DANH SÁCH BÀI HÁT ────────────────────────────────────
              Expanded(
                child: playlist.songIds.isEmpty
                    ? const Center(
                        child: Text(
                          'Danh sách này chưa có bài hát nào',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Theme(
                        data: Theme.of(context)
                            .copyWith(canvasColor: Colors.transparent),
                        child: ReorderableListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: playlist.songIds.length,
                          onReorder: (oldIndex, newIndex) {
                            context
                                .read<PlaylistCubit>()
                                .reorderSongs(widget.playlistId,
                                    oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final songId = playlist.songIds[index];
                            final song = _resolveSong(songId);

                            // ── Bài hát không khả dụng ───────────────
                            if (song == null) {
                              return ListTile(
                                key: ValueKey(songId),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 4),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                      Icons.music_off_rounded,
                                      color: Colors.white54),
                                ),
                                title: const Text(
                                  'Bài hát không còn khả dụng',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  _isUuid(songId) && _loadingUserSongs
                                      ? 'Đang tải...'
                                      : 'ID: $songId',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 18),
                                      onPressed: () =>
                                          _showRemoveConfirm(
                                              context,
                                              songId,
                                              widget.playlistId),
                                    ),
                                    const Icon(
                                        Icons.drag_handle_rounded,
                                        color: Colors.white24),
                                  ],
                                ),
                              );
                            }

                            // ── Bài hát bình thường ──────────────────
                            final songIndex = playableSongs
                                .indexWhere((s) => s.id == song.id);

                            return ListTile(
                              key: ValueKey(songId),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      song.artUri?.toString() ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.white12,
                                    child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white54),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song.artist ?? 'Unknown',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white54,
                                        size: 20),
                                    onPressed: () => _showSongOptions(
                                        context,
                                        song,
                                        songId,          // ← ID thực lưu trong DB
                                        widget.playlistId),
                                  ),
                                  const Icon(
                                      Icons.drag_handle_rounded,
                                      color: Colors.white24),
                                ],
                              ),
                              onTap: () {
                                context.read<PlayerBloc>().add(
                                      LoadPlaylistEvent(playableSongs,
                                          startIndex: songIndex != -1
                                              ? songIndex
                                              : 0),
                                    );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlayerPage(song: song),
                                  ),
                                );
                              },
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

  void _showSongOptions(
      BuildContext context, MediaItem song, String playlistSongId, String pId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            _OptionTile(
              icon: Icons.play_arrow_rounded,
              label: 'Phát ngay',
              onTap: () {
                Navigator.pop(context);
                context
                    .read<PlayerBloc>()
                    .add(LoadPlaylistEvent([song], startIndex: 0));
              },
            ),
            BlocBuilder<FavoriteCubit, List<String>>(
              builder: (context, favorites) {
                final isFav = favorites.contains(song.id);
                return _OptionTile(
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: isFav
                      ? const Color(0xFFE91E8C)
                      : Colors.white70,
                  label: isFav ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                  onTap: () async {
                    Navigator.pop(context);
                    await context
                        .read<FavoriteCubit>()
                        .toggleFavorite(song.id);
                  },
                );
              },
            ),
            BlocBuilder<DownloadCubit, List<String>>(
              builder: (context, downloads) {
                final isDownloaded = downloads.contains(song.id);
                return _OptionTile(
                  icon: isDownloaded
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                  iconColor: isDownloaded
                      ? const Color(0xFF1DB954)
                      : Colors.white70,
                  label: isDownloaded ? 'Đã tải' : 'Tải nhạc',
                  textColor: isDownloaded
                      ? const Color(0xFF1DB954)
                      : Colors.white,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await context
                          .read<DownloadCubit>()
                          .toggleDownload(song);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                );
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              iconColor: Colors.redAccent,
              label: 'Xóa khỏi playlist',
              textColor: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                // Dùng playlistSongId (ID lưu trong DB) thay vì song.id (audioUrl)
                _showRemoveConfirm(context, playlistSongId, pId);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirm(
      BuildContext context, String sId, String pId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa bài hát?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Bạn có chắc chắn muốn xóa bài hát này khỏi danh sách phát không?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () {
              context
                  .read<PlaylistCubit>()
                  .removeSongFromPlaylist(pId, sId);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Option Tile ─────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70),
      title: Text(label,
          style:
              TextStyle(color: textColor ?? Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }
}