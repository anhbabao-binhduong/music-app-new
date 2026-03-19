import 'package:music_app/core/constants/app_theme.dart';
import 'package:music_app/services/music_player_service.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/presentation/bloc/player/player_state.dart';
import 'package:music_app/widgets/progress_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_app/pages/player/lyrics_page.dart';
import 'package:music_app/services/lyrics_service.dart';

class PlayerPage extends StatefulWidget {
  final MediaItem song;
  const PlayerPage({super.key, required this.song});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final PageController _pageController = PageController();
  final LyricsService _lyricsService = LyricsService();
  int _currentPage = 0;

  void _showQueue(BuildContext context, PlayerState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Danh sách đang phát", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.queue.length,
                itemBuilder: (context, index) {
                  final item = state.queue[index];
                  final isCurrent = state.currentIndex == index;

                  return Dismissible(
                    key: ValueKey('queue_${item.id}_$index'),
                    direction: isCurrent ? DismissDirection.none : DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      context.read<PlayerBloc>().add(RemoveFromQueueEvent(index));
                    },
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: item.artUri?.toString() ?? '',
                          width: 45, height: 45, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.music_note),
                        ),
                      ),
                      title: Text(item.title, 
                        style: TextStyle(
                          color: isCurrent ? Theme.of(context).colorScheme.primary : null, 
                          fontWeight: isCurrent ? FontWeight.bold : null),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(item.artist ?? "Unknown", maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: isCurrent 
                          ? Icon(Icons.equalizer, color: Theme.of(context).colorScheme.primary) 
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("${index + 1}", style: const TextStyle(color: Colors.grey)),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
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
                                      child: Row(children: [Icon(Icons.vertical_align_top_rounded, size: 20), SizedBox(width: 12), Text('Ưu tiên phát')]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent), SizedBox(width: 12), Text('Xóa khỏi danh sách', style: TextStyle(color: Colors.redAccent))]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                      onTap: () => context.read<PlayerBloc>().add(SkipToIndexEvent(index)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToLyrics() => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  void _goToPlayer() => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final MediaItem? currentSong = state.song ?? widget.song;
          if (currentSong == null) return const Center(child: CircularProgressIndicator());

          final isPlaying = state is PlayerPlaying;
          final isShuffle = state is PlayerPlaying ? state.isShuffle : (state is PlayerPaused ? state.isShuffle : false);
          final repeatMode = state is PlayerPlaying ? state.repeatMode : (state is PlayerPaused ? state.repeatMode : RepeatMode.none);

          return _PlayerBackground(
            artUrl: currentSong.artUri?.toString(),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Column(
                          children: [
                            _TopBar(isOnPlayerPage: true, onActionTap: _goToLyrics),
                            const SizedBox(height: 24),
                            Expanded(
                              flex: 5,
                              child: _AlbumArt(
                                artUrl: currentSong.artUri?.toString(),
                                heroTag: 'album-art-${currentSong.id}', 
                                isPlaying: isPlaying,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: _SongInfo(song: currentSong),
                            ),
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: ProgressBarWidget(
                                service: context.read<MusicPlayerService>(),
                                onSeek: (pos) => context.read<PlayerBloc>().add(SeekEvent(pos)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _Controls(
                              isPlaying: isPlaying,
                              isShuffle: isShuffle,
                              repeatMode: repeatMode,
                              onPlay: () => context.read<PlayerBloc>().add(const PlayEvent()),
                              onPause: () => context.read<PlayerBloc>().add(const PauseEvent()),
                              onNext: () => context.read<PlayerBloc>().add(const NextEvent()),
                              onPrevious: () => context.read<PlayerBloc>().add(const PreviousEvent()),
                              onShuffle: () => context.read<PlayerBloc>().add(const ToggleShuffleEvent()), // Đảm bảo event này đã được định nghĩa trong player_event.dart
                              onRepeat: () => context.read<PlayerBloc>().add(const CycleRepeatEvent()), // Đảm bảo event này đã được định nghĩa
                              onQueueTap: () => _showQueue(context, state), 
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        Column(
                          children: [
                            _TopBar(isOnPlayerPage: false, onActionTap: _goToPlayer),
                            Expanded(
                              child: LyricsPage(
                                song: currentSong,
                                lyricsService: _lyricsService,
                                positionStream: context.read<MusicPlayerService>().positionStream, 
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 20 : 6, height: 6,
                          decoration: BoxDecoration(
                            color: active ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
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
        gradient: AppTheme.playerGradient(Theme.of(context).colorScheme.primary),
      ),
      child: child,
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isOnPlayerPage;
  final VoidCallback onActionTap;

  const _TopBar({required this.isOnPlayerPage, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _IconBtn(icon: Icons.keyboard_arrow_down_rounded, onTap: () => Navigator.pop(context)),
          Expanded(
            child: Column(
              children: [
                Text(isOnPlayerPage ? 'NOW PLAYING' : 'LỜI BÀI HÁT', style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 2, fontSize: 11)),
              ],
            ),
          ),
          _IconBtn(icon: isOnPlayerPage ? Icons.lyrics_outlined : Icons.music_note_rounded, onTap: onActionTap),
        ],
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final String? artUrl;
  final String heroTag;
  final bool isPlaying;

  const _AlbumArt({this.artUrl, required this.heroTag, required this.isPlaying});

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
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 16), spreadRadius: -8)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: artUrl != null
                    ? CachedNetworkImage(imageUrl: artUrl!, fit: BoxFit.cover, placeholder: (_, __) => _ArtPlaceholder(), errorWidget: (_, __, ___) => _ArtPlaceholder())
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
      child: Icon(Icons.music_note_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _SongInfo extends StatelessWidget {
  final MediaItem song;
  const _SongInfo({required this.song});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final favoriteIds = context.watch<FavoriteCubit>().state;
    final isFavorite = favoriteIds.contains(song.id);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.title, style: tt.displayMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(song.artist ?? 'Unknown Artist', style: tt.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        _IconBtn(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          onTap: () async {
            try {
              await context.read<FavoriteCubit>().toggleFavorite(song.id);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          },
          color: isFavorite ? Colors.redAccent : null,
          size: 28,
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final bool isPlaying, isShuffle;
  final RepeatMode repeatMode;
  final VoidCallback onPlay, onPause, onNext, onPrevious, onShuffle, onRepeat, onQueueTap;

  const _Controls({
    required this.isPlaying, required this.isShuffle, required this.repeatMode,
    required this.onPlay, required this.onPause, required this.onNext,
    required this.onPrevious, required this.onShuffle, required this.onRepeat, required this.onQueueTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _IconBtn(icon: Icons.shuffle_rounded, onTap: onShuffle, color: isShuffle ? cs.primary : null, size: 24),
          _IconBtn(icon: Icons.skip_previous_rounded, onTap: onPrevious, size: 36, color: cs.onSurface),
          _PlayButton(isPlaying: isPlaying, onPlay: onPlay, onPause: onPause),
          _IconBtn(icon: Icons.skip_next_rounded, onTap: onNext, size: 36, color: cs.onSurface),
          _IconBtn(icon: Icons.queue_music_rounded, onTap: onQueueTap, color: cs.onSurface.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay, onPause;
  const _PlayButton({required this.isPlaying, required this.onPlay, required this.onPause});

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
            child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, key: ValueKey(isPlaying), color: cs.onPrimary, size: 36),
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
  const _IconBtn({required this.icon, required this.onTap, this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).iconTheme.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: c, size: size)),
      ),
    );
  }
}