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

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: isError ? 2000 : 1500),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlaylistSelection(BuildContext context) {
    final songId = item.id;
    TextEditingController controller = TextEditingController();

    void showCreateDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2E),
          title: const Text('Tạo danh sách phát',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập tên playlist...',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx);
                
                final result = await context
                    .read<PlaylistCubit>()
                    .createPlaylistAndAddSong(name, songId);

                if (result == null) {
                  _showSnackBar(context, 'Đã tạo playlist "$name"');
                } else {
                  _showSnackBar(context, result, isError: true);
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: BlocBuilder<PlaylistCubit, PlaylistState>(
          builder: (context, state) {
            final playlists = state is PlaylistLoaded
                ? state.playlists
                : <PlaylistModel>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Thêm vào danh sách phát',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.white),
                  title: const Text('Tạo danh sách phát mới',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Future.microtask(() => showCreateDialog());
                  },
                ),
                const Divider(color: Colors.white12),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có playlist nào',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final p = playlists[index];
                        final isAdded = p.songIds.contains(songId);

                        return ListTile(
                          leading: Icon(
                            isAdded ? Icons.check_circle : Icons.playlist_play,
                            color: isAdded ? Colors.greenAccent : Colors.white70,
                          ),
                          title: Text(p.name,
                              style: const TextStyle(color: Colors.white)),
                          trailing: isAdded
                              ? const Text("Đã thêm",
                                  style: TextStyle(color: Colors.greenAccent))
                              : null,
                          onTap: () async {
                            if (isAdded) {
                              _showSnackBar(context, "Bài hát đã có trong playlist");
                              Navigator.pop(context);
                              return;
                            }

                            final result = await context
                                .read<PlaylistCubit>()
                                .addSongToPlaylist(p.id, songId);

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            if (result == null) {
                              _showSnackBar(context, 'Đã thêm vào "${p.name}"');
                            } else {
                              _showSnackBar(context, result, isError: true);
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

  void _showSongInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Thông tin bài hát', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Tên bài hát', item.title),
            const SizedBox(height: 8),
            _infoRow('Nghệ sĩ', item.artist ?? 'Không rõ'),
            const SizedBox(height: 8),
            _infoRow('Album', item.album ?? 'Không rõ'),
            const SizedBox(height: 8),
            _infoRow('Thời lượng', _formatDuration(item.duration ?? Duration.zero)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showReportDialog(BuildContext context) {
    final List<String> reasons = [
      'Nội dung không phù hợp',
      'Bản quyền',
      'Thông tin sai lệch',
      'Chất lượng âm thanh kém',
      'Lý do khác',
    ];
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        title: const Text('Báo cáo bài hát', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons.map((reason) => ListTile(
            title: Text(reason, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              _showSnackBar(context, 'Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét.');
            },
          )).toList(),
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
      builder: (ctx) {
        return SafeArea(
          child: BlocBuilder<FavoriteCubit, List<String>>(
            builder: (_, favState) {
              final isFavorite = favState.contains(item.id);
              return BlocBuilder<DownloadCubit, List<String>>(
                builder: (_, downState) {
                  final isDownloaded = downState.contains(item.id);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      _MenuActionTile(
                        icon: Icons.playlist_play,
                        title: 'Phát tiếp theo',
                        onTap: () {
                          Navigator.pop(ctx);
                          // SỬA: dùng đúng tên event PlayNextEvent
                          context.read<PlayerBloc>().add(PlayNextEvent(item));
                          _showSnackBar(context, 'Đã thêm "${item.title}" vào hàng chờ');
                        },
                      ),
                      _MenuActionTile(
                        icon: Icons.queue_music,
                        title: 'Thêm vào playlist',
                        onTap: () {
                          Navigator.pop(ctx);
                          _showPlaylistSelection(context);
                        },
                      ),
                      _MenuActionTile(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        title: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                        iconColor: isFavorite ? Colors.redAccent : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await context.read<FavoriteCubit>().toggleFavorite(item.id);
                            _showSnackBar(context, 
                                isFavorite ? 'Đã xóa khỏi yêu thích' : 'Đã thêm vào yêu thích');
                          } catch (e) {
                            _showSnackBar(context, e.toString(), isError: true);
                          }
                        },
                      ),
                      _MenuActionTile(
                        icon: isDownloaded ? Icons.download_done : Icons.download,
                        title: isDownloaded ? 'Đã tải' : 'Tải nhạc',
                        iconColor: isDownloaded ? Colors.greenAccent : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (isDownloaded) {
                            _showSnackBar(context, 'Bài hát đã được tải');
                          } else {
                            try {
                              await context.read<DownloadCubit>().toggleDownload(item);
                              _showSnackBar(context, 'Đã tải xuống thành công');
                            } catch (e) {
                              _showSnackBar(context, e.toString(), isError: true);
                            }
                          }
                        },
                      ),
                      _MenuActionTile(
                        icon: Icons.share,
                        title: 'Chia sẻ',
                        onTap: () {
                          Navigator.pop(ctx);
                          Share.share(
                            'Nghe bài hát "${item.title}" - ${item.artist} trên Music App',
                            subject: 'Chia sẻ bài hát',
                          );
                        },
                      ),
                      _MenuActionTile(
                        icon: Icons.info_outline,
                        title: 'Thông tin bài hát',
                        onTap: () {
                          Navigator.pop(ctx);
                          _showSongInfoDialog(context);
                        },
                      ),
                      _MenuActionTile(
                        icon: Icons.flag,
                        title: 'Báo cáo',
                        iconColor: Colors.redAccent,
                        onTap: () {
                          Navigator.pop(ctx);
                          _showReportDialog(context);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text('$rank',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      title: Text(item.title,
          style: const TextStyle(color: Colors.white)),
      subtitle: Text(item.artist ?? '',
          style: const TextStyle(color: Colors.grey)),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onPressed: () => _showOptionsBottomSheet(context),
      ),
      onTap: onTap,
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
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}