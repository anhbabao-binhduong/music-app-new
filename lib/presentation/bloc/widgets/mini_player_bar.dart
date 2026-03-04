import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../bloc/player/player_event.dart';
import '../../bloc/player/player_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          curr is PlayerPlaying || curr is PlayerPaused,
      builder: (context, state) {
        if (state is! PlayerPlaying && state is! PlayerPaused) {
          return const SizedBox.shrink();
        }

        final song = state is PlayerPlaying
            ? (state as PlayerPlaying).song
            : (state as PlayerPaused).song;
        final isPlaying = state is PlayerPlaying;
        final position  = state is PlayerPlaying
            ? (state as PlayerPlaying).position
            : (state as PlayerPaused).position;
        final duration  = state is PlayerPlaying
            ? (state as PlayerPlaying).duration
            : (state as PlayerPaused).duration;
        final progress  = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return GestureDetector(
          onTap: () {
            // Navigate up to full player
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, anim, __) =>
                  BlocProvider.value(
                    value: context.read<PlayerBloc>(),
                    child: /* PlayerPage */ Container(), // inject your PlayerPage
                  ),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ));
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(color: cs.outline, width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Thin progress indicator ───────────────
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  color: cs.primary,
                  backgroundColor: cs.outline,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: song.artUri?.toString() ?? '',
                            width: 42, height: 42, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 42, height: 42,
                              color: cs.surfaceVariant,
                              child: Icon(Icons.music_note_rounded,
                                  color: cs.primary, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Song info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title,
                                  style: tt.titleLarge?.copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(song.artist ?? '',
                                  style: tt.titleMedium?.copyWith(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // Prev
                        _MiniBtn(
                          icon: Icons.skip_previous_rounded,
                          onTap: () => context.read<PlayerBloc>()
                              .add(const PreviousEvent()),
                        ),
                        // Play/Pause
                        _MiniBtn(
                          icon: isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: () => context.read<PlayerBloc>().add(
                            isPlaying
                                ? const PauseEvent()
                                : const PlayEvent(),
                          ),
                          primary: true,
                        ),
                        // Next
                        _MiniBtn(
                          icon: Icons.skip_next_rounded,
                          onTap: () => context.read<PlayerBloc>()
                              .add(const NextEvent()),
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

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  const _MiniBtn({required this.icon, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: primary ? 28 : 22,
              color: primary ? cs.primary : cs.onSurface),
        ),
      ),
    );
  }
}