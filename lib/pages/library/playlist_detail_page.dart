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

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF3F4F8);
const _kCard = Colors.white;
const _kPrimary = Color(0xFF0D47A1);
const _kAccentGreen = Color(0xFF1DB954);
const _kTextPrimary = Color(0xFF1A1A2E);
const _kTextSecondary = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

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
  final Map<String, MediaItem> _userSongMap = {};
  bool _loadingUserSongs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserSongs());
  }

  Future<void> _fetchUserSongs() async {
    final state = context.read<PlaylistCubit>().state;
    if (state is! PlaylistLoaded) return;

    final matchIndex =
        state.playlists.indexWhere((p) => p.id == widget.playlistId);
    if (matchIndex == -1) return;

    final uuidIds =
        state.playlists[matchIndex].songIds.where(_isUuid).toList();
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

  MediaItem? _resolveSong(String songId) {
    if (_isUuid(songId)) return _userSongMap[songId];
    return findSongById(songId);
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa danh sách?',
            style: TextStyle(
                color: _kTextPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
            'Bạn có chắc chắn muốn xóa danh sách phát này không?',
            style: TextStyle(color: _kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              context
                  .read<PlaylistCubit>()
                  .deletePlaylist(widget.playlistId);
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

  void _showRemoveConfirm(
      BuildContext context, String sId, String pId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa bài hát?',
            style: TextStyle(
                color: _kTextPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
            'Bạn có chắc chắn muốn xóa bài hát này khỏi danh sách phát không?',
            style: TextStyle(color: _kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              context
                  .read<PlaylistCubit>()
                  .removeSongFromPlaylist(pId, sId);
              Navigator.pop(ctx);
            },
            child:
                const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, MediaItem song,
      String playlistSongId, String pId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Song info header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: song.artUri?.toString() ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: _kBorder,
                        child: const Icon(Icons.music_note,
                            color: _kTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title,
                            style: const TextStyle(
                                color: _kTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(song.artist ?? 'Unknown',
                            style: const TextStyle(
                                color: _kTextSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _kBorder, height: 1),
            _OptionTile(
              icon: Icons.play_arrow_rounded,
              iconColor: _kPrimary,
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
                  iconColor:
                      isFav ? const Color(0xFFE91E8C) : _kTextSecondary,
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
                  iconColor:
                      isDownloaded ? _kAccentGreen : _kTextSecondary,
                  label: isDownloaded ? 'Đã tải về' : 'Tải nhạc',
                  textColor:
                      isDownloaded ? _kAccentGreen : _kTextPrimary,
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
                _showRemoveConfirm(context, playlistSongId, pId);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _kTextPrimary),
        title: const Text(
          'Danh sách phát',
          style: TextStyle(
              color: _kTextPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Xóa danh sách',
            onPressed: () => _showDeleteConfirmDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<PlaylistCubit, PlaylistState>(
        builder: (context, state) {
          if (state is! PlaylistLoaded) {
            return const Center(
                child: CircularProgressIndicator(color: _kPrimary));
          }

          final matchIndex =
              state.playlists.indexWhere((p) => p.id == widget.playlistId);
          if (matchIndex == -1) {
            return const Center(
              child: Text('Danh sách không tồn tại',
                  style: TextStyle(color: _kTextSecondary)),
            );
          }

          final playlist = state.playlists[matchIndex];
          final playableSongs = playlist.songIds
              .map(_resolveSong)
              .whereType<MediaItem>()
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ──────────────────────────────────────────
                  Container(
                    margin:
                        const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Playlist icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D47A1),
                                    Color(0xFF1565C0),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.name,
                                    style: const TextStyle(
                                        color: _kTextPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.music_note_rounded,
                                          size: 14,
                                          color: _kTextSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${playlist.songIds.length} bài hát',
                                        style: const TextStyle(
                                            color: _kTextSecondary,
                                            fontSize: 13),
                                      ),
                                      if (_loadingUserSongs) ...[
                                        const SizedBox(width: 10),
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: _kPrimary),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (playableSongs.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<PlayerBloc>().add(
                                      LoadPlaylistEvent(playableSongs,
                                          startIndex: 0),
                                    );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PlayerPage(
                                        song: playableSongs[0]),
                                  ),
                                );
                              },
                              icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 22),
                              label: const Text(
                                'Phát tất cả',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Song list ────────────────────────────────────────────
                  Expanded(
                    child: playlist.songIds.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.queue_music_rounded,
                                    size: 72,
                                    color:
                                        _kTextSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Danh sách này chưa có bài hát nào',
                                  style: TextStyle(
                                      color: _kTextSecondary, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                            ),
                            child: ReorderableListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 120),
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

                                // ── Unavailable song ──────────────────────
                                if (song == null) {
                                  return Container(
                                    key: ValueKey(songId),
                                    margin: const EdgeInsets.only(
                                        bottom: 10),
                                    decoration: BoxDecoration(
                                      color: _kCard,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border:
                                          Border.all(color: _kBorder),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4),
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _kBorder,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                            Icons.music_off_rounded,
                                            color: _kTextSecondary),
                                      ),
                                      title: const Text(
                                        'Bài hát không còn khả dụng',
                                        style: TextStyle(
                                            color: _kTextPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        _isUuid(songId) &&
                                                _loadingUserSongs
                                            ? 'Đang tải...'
                                            : 'ID: $songId',
                                        style: const TextStyle(
                                            color: _kTextSecondary,
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons
                                                    .delete_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 20),
                                            onPressed: () =>
                                                _showRemoveConfirm(
                                                    context,
                                                    songId,
                                                    widget.playlistId),
                                          ),
                                          const Icon(
                                              Icons.drag_handle_rounded,
                                              color: _kBorder),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // ── Normal song ───────────────────────────
                                final songIndex = playableSongs
                                    .indexWhere((s) => s.id == song.id);

                                return Container(
                                  key: ValueKey(songId),
                                  margin: const EdgeInsets.only(
                                      bottom: 10),
                                  decoration: BoxDecoration(
                                    color: _kCard,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(color: _kBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                    leading: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            song.artUri?.toString() ??
                                                '',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            Container(
                                          width: 50,
                                          height: 50,
                                          color: _kBorder,
                                          child: const Icon(
                                              Icons.music_note,
                                              color: _kTextSecondary),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      song.title,
                                      style: const TextStyle(
                                          color: _kTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      song.artist ?? 'Unknown',
                                      style: const TextStyle(
                                          color: _kTextSecondary,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.more_vert_rounded,
                                              color: _kTextSecondary,
                                              size: 22),
                                          onPressed: () => _showSongOptions(
                                              context,
                                              song,
                                              songId,
                                              widget.playlistId),
                                        ),
                                        const Icon(
                                            Icons.drag_handle_rounded,
                                            color: _kBorder),
                                      ],
                                    ),
                                    onTap: () {
                                      context.read<PlayerBloc>().add(
                                            LoadPlaylistEvent(
                                                playableSongs,
                                                startIndex:
                                                    songIndex != -1
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
                                  ),
                                );
                              },
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
}

// ─── Option Tile ──────────────────────────────────────────────────────────────
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
      leading: Icon(icon, color: iconColor ?? _kTextSecondary),
      title: Text(
        label,
        style: TextStyle(
            color: textColor ?? _kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}