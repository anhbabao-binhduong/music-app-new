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
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    }
  }

  void _showOptionsSheet(BuildContext pageCtx) {
    final pageContext = context;
    final favCubit = context.read<FavoriteCubit>();
    final playlistCubit = context.read<PlaylistCubit>();

    showModalBottomSheet(
      context: pageCtx,
      backgroundColor: Theme.of(pageCtx).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
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
                    color: cs.onSurface.withValues(alpha: 0.2),
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
                                    color: cs.surfaceContainerHighest,
                                    child: Icon(Icons.music_note_rounded,
                                        color: cs.onSurface.withValues(alpha: 0.3),
                                        size: 24),
                                  ),
                                )
                              : Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(Icons.music_note_rounded,
                                      color: cs.onSurface.withValues(alpha: 0.3),
                                      size: 24),
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
                              style: tt.titleMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.item.artist ?? 'Unknown Artist',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.7),
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
                Divider(color: cs.onSurface.withValues(alpha: 0.1), height: 24),

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
                        : cs.onSurface.withValues(alpha: 0.7),
                    label: isCurrentlyFav ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final wasFav = favCubit.state.contains(widget.item.id);
                      try {
                        await favCubit.toggleFavorite(widget.item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(wasFav
                                  ? 'Đã bỏ khỏi yêu thích'
                                  : 'Đã thêm vào yêu thích'),
                              backgroundColor: wasFav
                                  ? Colors.grey.shade700
                                  : const Color(0xFFE91E8C),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
                      isInAnyPlaylist = state.playlists
                          .any((pl) => pl.songIds.contains(widget.item.id));
                    }
                    return _OptionTile(
                      icon: isInAnyPlaylist
                          ? Icons.check_circle_rounded
                          : Icons.playlist_add_rounded,
                      iconColor: isInAnyPlaylist
                          ? const Color(0xFF7C3AED)
                          : cs.onSurface.withValues(alpha: 0.7),
                      label: isInAnyPlaylist
                          ? 'Đã thêm vào playlist'
                          : 'Thêm vào playlist',
                      textColor:
                          isInAnyPlaylist ? const Color(0xFF7C3AED) : null,
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
                      icon: isDownloaded
                          ? Icons.download_done_rounded
                          : Icons.download_rounded,
                      iconColor: isDownloaded
                          ? const Color(0xFF1DB954)
                          : cs.onSurface.withValues(alpha: 0.7),
                      label: isDownloaded ? 'Đã tải' : 'Tải nhạc',
                      textColor:
                          isDownloaded ? const Color(0xFF1DB954) : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final wasDown = downloadedIds.contains(widget.item.id);
                        try {
                          await pageContext
                              .read<DownloadCubit>()
                              .toggleDownload(widget.item);
                          if (pageContext.mounted) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(wasDown
                                    ? 'Đã xóa khỏi tải về'
                                    : 'Đã tải bài hát'),
                                backgroundColor: const Color(0xFF1DB954),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (pageContext.mounted) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                    e.toString().replaceFirst('Exception: ', '')),
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
                  iconColor: cs.onSurface.withValues(alpha: 0.7),
                  label: 'Chia sẻ',
                  onTap: () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            '🎵 Nghe bài "${widget.item.title}" - ${widget.item.artist ?? ''} trên Music App!',
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

  void _showAddToPlaylistSheet(
      BuildContext pageContext, PlaylistCubit playlistCubit) {
    showModalBottomSheet(
      context: pageContext,
      backgroundColor:
          Theme.of(pageContext).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: BlocBuilder<PlaylistCubit, PlaylistState>(
              builder: (context, state) {
                final playlists =
                    state is PlaylistLoaded ? state.playlists : <PlaylistModel>[];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn playlist',
                          style: tt.titleMedium?.copyWith(
                            color: cs.onSurface,
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
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
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
                            final isAdded =
                                pl.songIds.contains(widget.item.id);
                            return ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.queue_music_rounded,
                                    color: Color(0xFF7C3AED), size: 20),
                              ),
                              title: Text(
                                pl.name,
                                style: tt.bodyMedium?.copyWith(
                                  color: isAdded
                                      ? const Color(0xFF7C3AED)
                                      : cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${pl.songIds.length} bài',
                                style: tt.bodySmall?.copyWith(
                                  color: isAdded
                                      ? const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.7)
                                      : cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              trailing: isAdded
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF7C3AED), size: 22)
                                  : null,
                              onTap: () async {
                                Navigator.pop(ctx);
                                final err =
                                    await playlistCubit.addSongToPlaylist(
                                  pl.id,
                                  widget.item.id,
                                );
                                if (pageContext.mounted) {
                                  ScaffoldMessenger.of(pageContext)
                                      .showSnackBar(
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
                                          borderRadius:
                                              BorderRadius.circular(12)),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Spotify-style card: dark #1A1A1A / #282828 hover; light #F5F5F5 / #EAEAEA hover
    final cardColor = isLight
        ? (_isHovered ? const Color(0xFFEAEAEA) : const Color(0xFFF5F5F5))
        : (_isHovered ? const Color(0xFF282828) : const Color(0xFF1A1A1A));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Rank number
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: widget.rank <= 3
                          ? _RankBadge(
                              rank: widget.rank, color: _getRankColor())
                          : Text(
                              '${widget.rank}',
                              style: tt.bodyLarge?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Thumbnail with subtle shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isLight ? 0.1 : 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            color: cs.surfaceContainerHighest,
                            child: widget.item.artUri != null
                                ? Image.network(
                                    widget.item.artUri.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.music_note_rounded,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.3),
                                      size: 24,
                                    ),
                                  )
                                : Icon(
                                    Icons.music_note_rounded,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.3),
                                    size: 24,
                                  ),
                          ),
                          // Play overlay on hover
                          if (_isHovered)
                            Container(
                              width: 56,
                              height: 56,
                              color: Colors.black.withValues(alpha: 0.45),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
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
                          style: tt.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.artist ?? 'Unknown Artist',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
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
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // More button – always visible, brighter on hover
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: cs.onSurface.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      onPressed: () => _showOptionsSheet(context),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
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

// ─── Option tile in bottom sheet ───────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: tt.bodyMedium?.copyWith(
          color: textColor ?? cs.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── Rank badge (top-3) ─────────────────────────────────────────────────────

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
                ),
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