import 'package:music_app/core/constants/app_theme.dart';
import 'package:music_app/services/music_player_service.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';   
import 'package:music_app/presentation/bloc/player/player_event.dart'; 
import 'package:music_app/presentation/bloc/player/player_state.dart';   
import 'package:music_app/widgets/progress_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';            // Để sửa lỗi: BlocBuilder not found
import 'package:audio_service/audio_service.dart';          // Để sửa lỗi: MediaItem not found
import 'package:cached_network_image/cached_network_image.dart'; // Để sửa lỗi: CachedNetworkImage not found
class PlayerPage extends StatelessWidget {
  final MediaItem song;
  const PlayerPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final currentSong = switch (state) {
            PlayerPlaying s => s.song,
            PlayerPaused  s => s.song,
            PlayerLoading s => s.song ?? song,
            _               => song,
          };
          final isPlaying   = state is PlayerPlaying;
          final isShuffle   = state is PlayerPlaying ? state.isShuffle
                            : state is PlayerPaused  ? state.isShuffle
                            : false;
          final repeatMode  = state is PlayerPlaying ? state.repeatMode
                            : state is PlayerPaused  ? state.repeatMode
                            : RepeatMode.none;

          return _PlayerBackground(
            artUrl: currentSong.artUri?.toString(),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top Bar ──────────────────────────────
                  _TopBar(),
                  const SizedBox(height: 24),

                  // ── Album Art ────────────────────────────
                  Expanded(
                    flex: 5,
                    child: _AlbumArt(
                      artUrl: currentSong.artUri?.toString(),
                      heroTag: 'album-art-${currentSong.id}',
                      isPlaying: isPlaying,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Song Info ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _SongInfo(song: currentSong),
                  ),
                  const SizedBox(height: 28),

                  // ── Progress Bar via StreamBuilder ────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ProgressBarWidget(
                      service: context.read<MusicPlayerService>(),
                      onSeek: (pos) =>
                          context.read<PlayerBloc>().add(SeekEvent(pos)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Controls ─────────────────────────────
                  _Controls(
                    isPlaying: isPlaying,
                    isShuffle: isShuffle,
                    repeatMode: repeatMode,
                    onPlay:     () => context.read<PlayerBloc>().add(const PlayEvent()),
                    onPause:    () => context.read<PlayerBloc>().add(const PauseEvent()),
                    onNext:     () => context.read<PlayerBloc>().add(const NextEvent()),
                    onPrevious: () => context.read<PlayerBloc>().add(const PreviousEvent()),
                    onShuffle:  () => context.read<PlayerBloc>().add(const ToggleShuffleEvent()),
                    onRepeat:   () => context.read<PlayerBloc>().add(const CycleRepeatEvent()),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _PlayerBackground extends StatelessWidget {
  final String? artUrl;
  final Widget child;
  const _PlayerBackground({this.artUrl, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.playerGradient(
          Theme.of(context).colorScheme.primary,
        ),
      ),
      child: child,
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text('NOW PLAYING',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 2, fontSize: 11,
                    )),
              ],
            ),
          ),
          _IconBtn(icon: Icons.more_vert_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final String? artUrl;
  final String heroTag;
  final bool isPlaying;

  const _AlbumArt({
    this.artUrl,
    required this.heroTag,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPlaying ? 1.0 : 0.88,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Hero(
          tag: heroTag,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: artUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ArtPlaceholder(),
                        errorWidget: (_, __, ___) => _ArtPlaceholder(),
                      )
                    : _ArtPlaceholder(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded,
          size: 64, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _SongInfo extends StatelessWidget {
  final MediaItem song;
  const _SongInfo({required this.song});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.title,
                  style: tt.displayMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(song.artist ?? 'Unknown Artist',
                  style: tt.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        _IconBtn(
          icon: Icons.favorite_border_rounded,
          onTap: () {},
          size: 28,
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final bool isPlaying, isShuffle;
  final RepeatMode repeatMode;
  final VoidCallback onPlay, onPause, onNext, onPrevious, onShuffle, onRepeat;

  const _Controls({
    required this.isPlaying,
    required this.isShuffle,
    required this.repeatMode,
    required this.onPlay,
    required this.onPause,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          _IconBtn(
            icon: Icons.shuffle_rounded,
            onTap: onShuffle,
            color: isShuffle ? cs.primary : null,
            size: 24,
          ),

          // Previous
          _IconBtn(
            icon: Icons.skip_previous_rounded,
            onTap: onPrevious,
            size: 36,
            color: cs.onSurface,
          ),

          // Play/Pause
          _PlayButton(
            isPlaying: isPlaying,
            onPlay: onPlay,
            onPause: onPause,
          ),

          // Next
          _IconBtn(
            icon: Icons.skip_next_rounded,
            onTap: onNext,
            size: 36,
            color: cs.onSurface,
          ),

          // Repeat
          _IconBtn(
            icon: repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            onTap: onRepeat,
            color: repeatMode != RepeatMode.none ? cs.primary : null,
            size: 24,
          ),
        ],
      ),
    );
  }
}
class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay, onPause;
  const _PlayButton({
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isPlaying ? onPause : onPlay,
        customBorder: const CircleBorder(),
        splashColor: cs.onPrimary.withValues(alpha: 0.2),
        child: SizedBox.square(
          dimension: 68,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              key: ValueKey(isPlaying),
              color: cs.onPrimary,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).iconTheme.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: c, size: size),
        ),
      ),
    );
  }
}