import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/data/models/playlist_model.dart';
import 'package:music_app/pages/player/player_page.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/presentation/bloc/player/player_state.dart';
import 'package:music_app/presentation/bloc/playlist/playlist_cubit.dart';
import 'package:music_app/services/supabase_auth_service.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/data/local_music_data.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      // ✅ FIX 1: Bỏ buildWhen cũ — phải lắng nghe TẤT CẢ state kể cả PlayerInitial
      // để khi reset (logout) bar mới ẩn đi đúng cách
      builder: (context, state) {
        // ✅ FIX 2: Kiểm tra auth TRONG builder để reactive khi logout
        final authService = SupabaseAuthService();
        if (authService.currentUser == null) {
          return const SizedBox.shrink();
        }

        // Ẩn nếu không có bài đang phát
        if (state is! PlayerPlaying && state is! PlayerPaused) {
          return const SizedBox.shrink();
        }

        // Nếu mới mở app, queue được load nhưng chưa từng phát nhạc (position = 0s)
        if (state is PlayerPaused && state.position.inMilliseconds == 0) {
          return const SizedBox.shrink();
        }

        // Ẩn nếu queue rỗng
        final queue = (state is PlayerPlaying)
            ? state.queue
            : (state as PlayerPaused).queue;

        if (queue.isEmpty) {
          return const SizedBox.shrink();
        }

        late final MediaItem song;
        late final Duration position;
        late final Duration duration;
        late final bool isPlaying;

        if (state is PlayerPlaying) {
          song = state.song!;
          position = state.position;
          duration = state.duration;
          isPlaying = true;
        } else {
          final paused = state as PlayerPaused;
          song = paused.song!;
          position = paused.position;
          duration = paused.duration;
          isPlaying = false;
        }

        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isLight = theme.brightness == Brightness.light;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, _, __) => PlayerPage(song: song),
                transitionsBuilder: (context, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
          },
          child: Container(
            height: 74,
            decoration: BoxDecoration(
              color: isLight
                  ? cs.surface.withValues(alpha: 0.92)
                  : cs.surfaceContainerHigh.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: cs.onSurface.withValues(alpha: isLight ? 0.16 : 0.2),
                  width: 0.6,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2.5,
                  color: cs.primary,
                  backgroundColor:
                      cs.primary.withValues(alpha: isLight ? 0.14 : 0.18),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                         ClipRRect(
                           borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: song.artUri?.toString() ?? '',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.music_note_rounded,
                                  color: cs.primary, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                 song.title,
                                 style: GoogleFonts.plusJakartaSans(
                                   color: cs.onSurface,
                                   fontSize: 13,
                                   fontWeight: FontWeight.w700,
                                   height: 1.2,
                                   letterSpacing: -0.1,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                               Text(
                                 song.artist ?? 'Unknown Artist',
                                 style: GoogleFonts.dmSans(
                                   color: cs.onSurface.withValues(alpha: 0.68),
                                   fontSize: 11,
                                   fontWeight: FontWeight.w500,
                                   height: 1.2,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                            ],
                          ),
                        ),
                        _MiniBtn(
                          icon: Icons.skip_previous_rounded,
                          onTap: () => context
                              .read<PlayerBloc>()
                              .add(const PreviousEvent()),
                        ),
                        _MiniBtn(
                          icon: isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          primary: true,
                          onTap: () => context.read<PlayerBloc>().add(
                                isPlaying
                                    ? const PauseEvent()
                                    : const PlayEvent(),
                              ),
                        ),
                        _MiniBtn(
                          icon: Icons.skip_next_rounded,
                          onTap: () =>
                              context.read<PlayerBloc>().add(const NextEvent()),
                        ),
                        _MiniBtn(
                          icon: Icons.queue_music_rounded,
                          onTap: () => showQueueBottomSheet(context),
                        ),
                        _MiniBtn(
                          icon: Icons.playlist_add_rounded,
                          onTap: () => showAddToPlaylistSheet(context, song),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Mở bottom sheet chọn playlist để thêm bài hát đang phát.
void showAddToPlaylistSheet(BuildContext context, MediaItem song) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isLight = theme.brightness == Brightness.light;

  // Dùng resolvePlaylistSongId để hỗ trợ cả community songs (UUID) lẫn regular songs (integer)
  final songId = resolvePlaylistSongId(song);
  final controller = TextEditingController();

    void showSnack(String msg, {bool isError = false}) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            msg,
            style: GoogleFonts.dmSans(
              color: cs.onInverseSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          backgroundColor: isError ? cs.error : cs.inverseSurface,
          behavior: SnackBarBehavior.floating,
        ));
    }

  void showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? cs.surface : cs.surfaceContainerHigh,
        title: Text(
          'Tạo danh sách phát mới',
          style: GoogleFonts.plusJakartaSans(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.dmSans(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập tên playlist...',
            hintStyle: GoogleFonts.dmSans(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.25)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Huỷ',
              style: GoogleFonts.dmSans(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                showSnack('Đã tạo playlist "$name" và thêm bài hát');
              } else {
                showSnack(result, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
            ),
            child: Text(
              'Tạo',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: isLight ? cs.surface : cs.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    isScrollControlled: true,
    builder: (sheetCtx) => SafeArea(
      child: BlocBuilder<PlaylistCubit, PlaylistState>(
        builder: (bCtx, state) {
          final playlists =
              state is PlaylistLoaded ? state.playlists : <PlaylistModel>[];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle ────────────────────────────────────────────
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Header: thumbnail + tên bài hát ──────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: song.artUri?.toString() ?? '',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.2,
                            ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist ?? 'Unknown Artist',
                              style: GoogleFonts.dmSans(
                                color: cs.onSurface.withValues(alpha: 0.62),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.playlist_add_rounded,
                        color: cs.onSurface.withValues(alpha: 0.38),
                      ),
                    ],
                  ),
                ),
                 Divider(
                   color: cs.onSurface.withValues(alpha: 0.1),
                   height: 1,
                 ),
                // ── Tạo playlist mới ──────────────────────────────────
                ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.add_rounded, color: cs.primary),
                          ),
                  title: Text(
                    'Tạo danh sách phát mới',
                    style: GoogleFonts.dmSans(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    Future.microtask(() => showCreateDialog());
                  },
                ),
                // ── Danh sách playlist hiện có ────────────────────────
                if (playlists.isNotEmpty) ...[
                  Divider(color: cs.onSurface.withValues(alpha: 0.1), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Danh sách phát của bạn',
                        style: GoogleFonts.dmSans(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (_, index) {
                        final p = playlists[index];
                        final isAdded = p.songIds.contains(songId);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isAdded
                                  ? const Color(0xFF1DB954).withValues(alpha: 0.14)
                                  : cs.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isAdded
                                  ? Icons.check_rounded
                                  : Icons.playlist_play_rounded,
                              color: isAdded
                                  ? const Color(0xFF1DB954)
                                  : cs.onSurface.withValues(alpha: 0.55),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: GoogleFonts.dmSans(
                              color: cs.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          subtitle: Text(
                            '${p.songIds.length} bài',
                            style: GoogleFonts.dmSans(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                          trailing: isAdded
                              ? Text(
                                  'Đã thêm',
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF1DB954),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                )
                              : null,
                          onTap: () async {
                            if (isAdded) {
                              showSnack('Bài hát đã có trong playlist');
                              Navigator.pop(sheetCtx);
                              return;
                            }
                            final result = await bCtx
                                .read<PlaylistCubit>()
                                .addSongToPlaylist(p.id, songId);
                            if (!bCtx.mounted) return;
                            Navigator.pop(sheetCtx);
                            if (result == null) {
                              showSnack('Đã thêm vào "${p.name}"');
                            } else {
                              showSnack(result, isError: true);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Divider(color: cs.onSurface.withValues(alpha: 0.1), height: 1),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Chưa có danh sách phát nào',
                      style: GoogleFonts.dmSans(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}

void showQueueBottomSheet(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isLight = theme.brightness == Brightness.light;

  showModalBottomSheet(
    context: context,
    backgroundColor: isLight ? cs.surface : cs.surfaceContainerHigh,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return BlocBuilder<PlayerBloc, PlayerState>(
            builder: (context, state) {
              final List<MediaItem> queue = (state is PlayerPlaying)
                  ? state.queue
                  : (state is PlayerPaused ? state.queue : []);

              final int currentIndex = (state is PlayerPlaying)
                  ? state.currentIndex
                  : (state is PlayerPaused ? state.currentIndex : 0);

              if (queue.isEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Danh sách đang phát",
                        style: GoogleFonts.plusJakartaSans(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Không có bài hát trong danh sách",
                          style: GoogleFonts.dmSans(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Danh sách đang phát",
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isCurrentlyPlaying = index == currentIndex;

                        return Dismissible(
                          key: ValueKey('queue_mini_${item.id}_$index'),
                          direction: isCurrentlyPlaying
                              ? DismissDirection.none
                              : DismissDirection.endToStart,
                           background: Container(
                             alignment: Alignment.centerRight,
                             padding: const EdgeInsets.only(right: 20),
                             color: cs.error,
                             child: Icon(Icons.delete_outline, color: cs.onError),
                           ),
                          onDismissed: (_) {
                            context
                                .read<PlayerBloc>()
                                .add(RemoveFromQueueEvent(index));
                          },
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: item.artUri?.toString() ?? '',
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                                 errorWidget: (_, __, ___) => Container(
                                     color: cs.surfaceContainerHighest,
                                     width: 45,
                                     height: 45,
                                     child: Icon(
                                       Icons.music_note,
                                       color: cs.onSurface.withValues(alpha: 0.5),
                                     )),
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                color:
                                    isCurrentlyPlaying ? cs.primary : cs.onSurface,
                                fontWeight:
                                    isCurrentlyPlaying ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 14,
                                height: 1.2,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.artist ?? "Unknown",
                              style: GoogleFonts.dmSans(
                                color: cs.onSurface.withValues(alpha: 0.62),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isCurrentlyPlaying
                                ? Icon(Icons.bar_chart_rounded, color: cs.primary)
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${index + 1}",
                                        style: GoogleFonts.dmSans(
                                          color: cs.onSurface.withValues(alpha: 0.32),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          size: 20,
                                          color: cs.onSurface.withValues(alpha: 0.52),
                                        ),
                                        onSelected: (value) {
                                          if (value == 'up') {
                                            context.read<PlayerBloc>().add(
                                                PrioritizeSongEvent(index));
                                          } else if (value == 'download') {
                                            context
                                                .read<DownloadCubit>()
                                                .toggleDownload(item);
                                          } else if (value == 'delete') {
                                            context.read<PlayerBloc>().add(
                                                RemoveFromQueueEvent(index));
                                          }
                                        },
                                        itemBuilder: (context) {
                                          final isDownloaded = context
                                              .read<DownloadCubit>()
                                              .state
                                              .contains(item.id);
                                          return [
                                            const PopupMenuItem(
                                              value: 'up',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .vertical_align_top_rounded,
                                                      size: 20),
                                                  SizedBox(width: 12),
                                                  Text('Ưu tiên phát'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'download',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isDownloaded
                                                        ? Icons
                                                            .download_done_rounded
                                                        : Icons.download_rounded,
                                                    size: 20,
                                                    color: isDownloaded
                                                        ? const Color(0xFF1DB954)
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    isDownloaded
                                                        ? 'Đã tải'
                                                        : 'Tải nhạc',
                                                    style: TextStyle(
                                                      color: isDownloaded
                                                          ? const Color(
                                                              0xFF1DB954)
                                                          : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      size: 20,
                                                      color: Colors.redAccent),
                                                  SizedBox(width: 12),
                                                  Text('Xóa khỏi danh sách',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .redAccent)),
                                                ],
                                              ),
                                            ),
                                          ];
                                        },
                                      ),
                                    ],
                                  ),
                            onTap: () {
                              context
                                  .read<PlayerBloc>()
                                  .add(SkipToIndexEvent(index));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _MiniBtn(
      {required this.icon, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        icon,
        size: primary ? 28 : 22,
        color: primary
            ? cs.primary
            : cs.onSurface.withValues(alpha: isLight ? 0.82 : 0.74),
      ),
    );
  }
}