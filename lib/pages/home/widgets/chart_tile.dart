import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../presentation/bloc/favorite/favorite_cubit.dart';
import '../../../presentation/bloc/playlist/playlist_cubit.dart';
import '../../../presentation/bloc/download/download_cubit.dart';
import '../../../data/models/playlist_model.dart';

class ChartTile extends StatefulWidget {
  final MediaItem item;
  final int rank;
  final VoidCallback onTap;

  const ChartTile({
    super.key,
    required this.item,
    required this.rank,
    required this.onTap,
  });

  @override
  State<ChartTile> createState() => _ChartTileState();
}

class _ChartTileState extends State<ChartTile> {
  bool _isHovered = false;

  Color _getRankColor() {
    switch (widget.rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white.withValues(alpha: 0.7);
    }
  }

  void _showOptionsSheet(BuildContext pageCtx) {
    final pageContext = context;
    final favCubit = context.read<FavoriteCubit>();
    final playlistCubit = context.read<PlaylistCubit>();

    showModalBottomSheet(
      context: pageCtx,
      backgroundColor: const Color(0xFF1E1E28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Song Info Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: widget.item.artUri != null
                              ? Image.network(
                                  widget.item.artUri.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF2A2A2E),
                                    child: const Icon(Icons.music_note_rounded,
                                        color: Colors.white30, size: 24),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF2A2A2E),
                                  child: const Icon(Icons.music_note_rounded,
                                      color: Colors.white30, size: 24),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.item.artist ?? 'Unknown Artist',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 24),

                // Favorite
                StatefulBuilder(builder: (ctx2, setSheetState) {
                  final favState = context.read<FavoriteCubit>().state;
                  final isCurrentlyFav = favState.contains(widget.item.id);
                  return _OptionTile(
                    icon: isCurrentlyFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: isCurrentlyFav
                        ? const Color(0xFFE91E8C)
                        : Colors.white70,
                    label: isCurrentlyFav
                        ? 'Bỏ yêu thích'
                        : 'Thêm vào yêu thích',
                                        onTap: () async {
                      Navigator.pop(ctx);
                      final wasFav = favCubit.state.contains(widget.item.id);
                      try {
                        await favCubit.toggleFavorite(widget.item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(wasFav ? 'Đã bỏ khỏi yêu thích' : 'Đã thêm vào yêu thích'),
                              backgroundColor: wasFav ? Colors.grey.shade700 : const Color(0xFFE91E8C),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  );
                }),

                // Add to playlist
                BlocBuilder<PlaylistCubit, PlaylistState>(
                  bloc: playlistCubit,
                  builder: (context, state) {
                    bool isInAnyPlaylist = false;
                    if (state is PlaylistLoaded) {
                      isInAnyPlaylist = state.playlists.any((pl) => pl.songIds.contains(widget.item.id));
                    }

                    return _OptionTile(
                      icon: isInAnyPlaylist ? Icons.check_circle_rounded : Icons.playlist_add_rounded,
                      iconColor: isInAnyPlaylist ? const Color(0xFF7C3AED) : Colors.white70,
                      label: isInAnyPlaylist ? 'Đã thêm vào playlist' : 'Thêm vào playlist',
                      textColor: isInAnyPlaylist ? const Color(0xFF7C3AED) : Colors.white,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showAddToPlaylistSheet(pageContext, playlistCubit);
                      },
                    );
                  },
                ),

                // Download
                BlocBuilder<DownloadCubit, List<String>>(
                  builder: (context, downloadedIds) {
                    final isDownloaded = downloadedIds.contains(widget.item.id);
                    return _OptionTile(
                      icon: isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                      iconColor: isDownloaded ? const Color(0xFF1DB954) : Colors.white70,
                      label: isDownloaded ? 'Đã tải' : 'Tải nhạc',
                      textColor: isDownloaded ? const Color(0xFF1DB954) : Colors.white,
                                            onTap: () async {
                        Navigator.pop(ctx);
                        final wasDown = downloadedIds.contains(widget.item.id);
                        try {
                          await pageContext.read<DownloadCubit>().toggleDownload(widget.item);
                          if (pageContext.mounted) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(wasDown ? 'Đã xóa khỏi tải về' : 'Đã tải bài hát'),
                                backgroundColor: const Color(0xFF1DB954),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (pageContext.mounted) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),

                // Share
                _OptionTile(
                  icon: Icons.share_rounded,
                  iconColor: Colors.white70,
                  label: 'Chia sẻ',
                  onTap: () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(
                      ShareParams(
                        text: '🎵 Nghe bài "${widget.item.title}" - ${widget.item.artist ?? ''} trên Music App!',
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistSheet(BuildContext pageContext, PlaylistCubit playlistCubit) {
    showModalBottomSheet(
      context: pageContext,
      backgroundColor: const Color(0xFF1E1E28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: BlocBuilder<PlaylistCubit, PlaylistState>(
              builder: (context, state) {
                final playlists = state is PlaylistLoaded ? state.playlists : <PlaylistModel>[];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn playlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (playlists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Bạn chưa có playlist nào',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: playlists.length,
                          itemBuilder: (_, i) {
                            final pl = playlists[i];
                            final isAdded = pl.songIds.contains(widget.item.id);

                            return ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.queue_music_rounded,
                                    color: Color(0xFF7C3AED), size: 20),
                              ),
                              title: Text(
                                pl.name,
                                style: TextStyle(
                                    color: isAdded ? const Color(0xFF7C3AED) : Colors.white, 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${pl.songIds.length} bài',
                                style: TextStyle(
                                    color: isAdded ? const Color(0xFF7C3AED).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.4), 
                                    fontSize: 12),
                              ),
                              trailing: isAdded
                                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 22)
                                  : null,
                              onTap: () async {
                                Navigator.pop(ctx);
                                final err = await playlistCubit.addSongToPlaylist(
                                  pl.id,
                                  widget.item.id,
                                );
                                if (pageContext.mounted) {
                                  ScaffoldMessenger.of(pageContext).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        err == null
                                            ? 'Đã thêm vào "${pl.name}"'
                                            : (err == 'Đã tồn tại'
                                                ? 'Bài hát đã có trong playlist'
                                                : err),
                                      ),
                                      backgroundColor: err == null
                                          ? const Color(0xFF7C3AED)
                                          : Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? const Color(0xFF242424)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Rank number
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: widget.rank <= 3
                          ? _RankBadge(rank: widget.rank, color: _getRankColor())
                          : Text(
                              '${widget.rank}',
                              style: const TextStyle(
                                color: Color(0xFFA3A3A3),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFF2A2A2E),
                          child: widget.item.artUri != null
                              ? Image.network(
                                  widget.item.artUri.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white30,
                                    size: 24,
                                  ),
                                )
                              : const Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white30,
                                  size: 24,
                                ),
                        ),
                        // Play overlay on hover
                        if (_isHovered)
                          Container(
                            width: 56,
                            height: 56,
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.artist ?? 'Unknown Artist',
                          style: const TextStyle(
                            color: Color(0xFFA3A3A3),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Duration
                  Text(
                    _formatDuration(widget.item.duration),
                    style: const TextStyle(
                      color: Color(0xFFA3A3A3),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // More button - always visible, brighter on hover
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => _showOptionsSheet(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      splashRadius: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? textColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          _getIcon(),
          color: color,
          size: 16,
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.workspace_premium_rounded;
      case 3:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }
}

