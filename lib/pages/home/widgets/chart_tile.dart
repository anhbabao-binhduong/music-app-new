import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/presentation/bloc/playlist/playlist_cubit.dart';
import 'package:music_app/data/models/playlist_model.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';

import '../home_page.dart';
import 'song_cards.dart';

class ChartTile extends StatelessWidget {
  final MediaItem item;
  final int rank;
  final VoidCallback onTap;

  const ChartTile({
    super.key,
    required this.item,
    required this.rank,
    required this.onTap,
  });

  void _showFastSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: isError ? 1800 : 1000),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPlaylistSelection(BuildContext context) {
    void showCreateDialog() {
      final TextEditingController nameController = TextEditingController();
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tạo danh sách phát', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: TextField(
            controller: nameController,
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
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final error = await context.read<PlaylistCubit>().createPlaylistAndAddSong(name, item.id);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (error == null) {
                  _showFastSnackBar(context, 'Đã tạo "$name" và thêm bài hát!');
                } else {
                  _showFastSnackBar(context, error, isError: true);
                }
              },
              child: const Text('Tạo mới', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: BlocBuilder<PlaylistCubit, PlaylistState>(
          builder: (context, state) {
            final playlists = (state is PlaylistLoaded) ? state.playlists : <PlaylistModel>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Thêm vào danh sách phát', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                  title: const Text('Tạo danh sách phát mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: showCreateDialog,
                ),
                const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Bạn chưa có danh sách phát nào', style: TextStyle(color: Colors.grey)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final p = playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.playlist_play_rounded, color: Colors.white70),
                          title: Text(p.name, style: const TextStyle(color: Colors.white)),
                          onTap: () async {
                            final error = await context.read<PlaylistCubit>().addSongToPlaylist(p.id, item.id);
                            if (!context.mounted) return;
                            Navigator.pop(context);

                            if (error == null) {
                              _showFastSnackBar(context, 'Đã thêm vào "${p.name}"');
                            } else {
                              _showFastSnackBar(context, error, isError: true);
                            }
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: BlocBuilder<FavoriteCubit, List<String>>(
            builder: (context, favoriteIds) {
              final isFavorite = favoriteIds.contains(item.id);
              final isDownloaded = context.watch<DownloadCubit>().state.contains(item.id);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ArtImage(uri: item.artUri, size: 48),
                ),
                title: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.artist ?? 'Unknown Artist', style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Divider(color: Colors.white12),
              _MenuActionTile(
                icon: Icons.queue_music_rounded,
                title: 'Phát tiếp theo',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<PlayerBloc>().add(PlayNextEvent(item));
                  _showFastSnackBar(context, 'Đã thêm vào hàng đợi');
                },
              ),
              _MenuActionTile(
                icon: Icons.playlist_add_rounded,
                title: 'Thêm vào danh sách phát',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showPlaylistSelection(context);
                },
              ),
              _MenuActionTile(
                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: isFavorite ? Colors.redAccent : Colors.white,
                title: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  try {
                    await context.read<FavoriteCubit>().toggleFavorite(item.id);
                    if (!context.mounted) return;
                    _showFastSnackBar(context, isFavorite ? 'Đã xóa khỏi yêu thích' : 'Đã thêm vào yêu thích');
                  } catch (e) {
                    if (!context.mounted) return;
                    _showFastSnackBar(
                      context,
                      e.toString().replaceFirst('Exception: ', ''),
                      isError: true,
                    );
                  }
                },
              ),
              _MenuActionTile(
                icon: isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                title: isDownloaded ? 'Bỏ khỏi Nhạc đã tải' : 'Lưu vào Nhạc đã tải',
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  try {
                    await context.read<DownloadCubit>().toggleDownload(item);
                    if (!context.mounted) return;
                    _showFastSnackBar(
                      context,
                      isDownloaded ? 'Đã bỏ khỏi Nhạc đã tải' : 'Đã lưu vào Nhạc đã tải',
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    _showFastSnackBar(
                      context,
                      e.toString().replaceFirst('Exception: ', ''),
                      isError: true,
                    );
                  }
                },
              ),
              _MenuActionTile(
                icon: Icons.share_rounded,
                title: 'Chia sẻ',
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final shareText = 'Cùng nghe bài hát ${item.title} của ${item.artist} trên app của tôi nhé!\nLink: ${item.id}';
                  await Share.share(shareText);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
            },
          ),
        );
      },
    );
  }

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.grey;
  }

  String get _durationText {
    final d = item.duration;
    if (d == null) return '';
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _rankColor,
                        fontSize: rank <= 3 ? 18 : 14,
                        fontWeight: rank <= 3 ? FontWeight.w900 : FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              Hero(
                tag: 'chart-${item.id}',
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ArtImage(uri: item.artUri, size: 52)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(item.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              if (_durationText.isNotEmpty) ...[
                Text(_durationText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                onPressed: () => _showOptionsBottomSheet(context),
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }
}
