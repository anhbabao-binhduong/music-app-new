import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/pages/player/player_page.dart'; 
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/presentation/bloc/player/player_state.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => curr is PlayerPlaying || curr is PlayerPaused,
      builder: (context, state) {
        if (state is! PlayerPlaying && state is! PlayerPaused) {
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

        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

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
            height: 72,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(color: cs.outline.withValues(alpha: 0.2), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  color: cs.primary,
                  backgroundColor: cs.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: song.artUri?.toString() ?? '',
                            width: 44, height: 44, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 44, height: 44, color: cs.surfaceContainerHighest,
                              child: Icon(Icons.music_note_rounded, color: cs.primary, size: 20),
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
                                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist ?? 'Unknown Artist',
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _MiniBtn(
                          icon: Icons.skip_previous_rounded,
                          onTap: () => context.read<PlayerBloc>().add(const PreviousEvent()),
                        ),
                        _MiniBtn(
                          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          primary: true,
                          onTap: () => context.read<PlayerBloc>().add(
                                isPlaying ? const PauseEvent() : const PlayEvent(),
                              ),
                        ),
                        _MiniBtn(
                          icon: Icons.skip_next_rounded,
                          onTap: () => context.read<PlayerBloc>().add(const NextEvent()),
                        ),
                        _MiniBtn(
                          icon: Icons.queue_music_rounded,
                          onTap: () => showQueueBottomSheet(context),
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

// --- CÁC HÀM VÀ CLASS BÊN DƯỚI NẰM RIÊNG BIỆT ---

void showQueueBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1B1B1B),
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

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Danh sách đang phát", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isCurrentlyPlaying = index == currentIndex;

                        // Bọc ListTile bằng Dismissible để vuốt xóa
                        return Dismissible(
                          key: ValueKey('queue_mini_${item.id}_$index'),
                          // Chặn xóa bài đang phát
                          direction: isCurrentlyPlaying ? DismissDirection.none : DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            context.read<PlayerBloc>().add(RemoveFromQueueEvent(index));
                          },
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: item.artUri?.toString() ?? '',
                                width: 45, height: 45, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(color: Colors.grey, width: 45, height: 45, child: const Icon(Icons.music_note)),
                              ),
                            ),
                            title: Text(item.title, 
                              style: TextStyle(
                                color: isCurrentlyPlaying ? Colors.greenAccent : Colors.white, 
                                fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(item.artist ?? "Unknown", 
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                            
                            // CẬP NHẬT: Thêm Nút 3 chấm (Menu ưu tiên / Xóa)
                            trailing: isCurrentlyPlaying 
                                ? const Icon(Icons.bar_chart_rounded, color: Colors.greenAccent)
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("${index + 1}", style: const TextStyle(color: Colors.white24)),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.white54),
                                        onSelected: (value) {
                                          if (value == 'up') {
                                            context.read<PlayerBloc>().add(PrioritizeSongEvent(index));
                                          } else if (value == 'delete') {
                                            context.read<PlayerBloc>().add(RemoveFromQueueEvent(index));
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'up',
                                            child: Row(
                                              children: [
                                                Icon(Icons.vertical_align_top_rounded, size: 20),
                                                SizedBox(width: 12),
                                                Text('Ưu tiên phát'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                                SizedBox(width: 12),
                                                Text('Xóa khỏi danh sách', style: TextStyle(color: Colors.redAccent)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                            onTap: () {
                              context.read<PlayerBloc>().add(SkipToIndexEvent(index));
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

  const _MiniBtn({required this.icon, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        icon,
        size: primary ? 30 : 24,
        color: primary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}