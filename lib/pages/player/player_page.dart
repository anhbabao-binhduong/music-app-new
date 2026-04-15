// pages/player/player_page.dart
import 'dart:math' as math;
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
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/data/models/lyric_line.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_app/presentation/bloc/comment/comment_cubit.dart';
import 'package:music_app/presentation/bloc/comment/comment_state.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';

class PlayerPage extends StatefulWidget {
  final MediaItem song;
  const PlayerPage({super.key, required this.song});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final Stream<Duration> _positionStream;

  @override
  void initState() {
    super.initState();
    _positionStream = context.read<MusicPlayerService>().positionStream;
  }

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
              child: Text("Danh sách đang phát",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.queue.length,
                itemBuilder: (context, index) {
                  final item = state.queue[index];
                  final isCurrent = state.currentIndex == index;

                  return Dismissible(
                    key: ValueKey('queue_${item.id}_$index'),
                    direction: isCurrent
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) =>
                        context.read<PlayerBloc>().add(RemoveFromQueueEvent(index)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: item.artUri?.toString() ?? '',
                          width: 45, height: 45, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.music_note),
                        ),
                      ),
                      title: Text(item.title,
                        style: TextStyle(
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight:
                              isCurrent ? FontWeight.bold : null),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item.artist ?? "Unknown",
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: isCurrent
                          ? Icon(Icons.equalizer,
                              color: Theme.of(context).colorScheme.primary)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("${index + 1}",
                                    style:
                                        const TextStyle(color: Colors.grey)),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded,
                                      size: 20, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'up') {
                                      context
                                          .read<PlayerBloc>()
                                          .add(PrioritizeSongEvent(index));
                                    } else if (value == 'download') {
                                      context
                                          .read<DownloadCubit>()
                                          .toggleDownload(item);
                                    } else if (value == 'delete') {
                                      context
                                          .read<PlayerBloc>()
                                          .add(RemoveFromQueueEvent(index));
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
                                        child: Row(children: [
                                          Icon(Icons.vertical_align_top_rounded,
                                              size: 20),
                                          SizedBox(width: 12),
                                          Text('Ưu tiên phát')
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: 'download',
                                        child: Row(children: [
                                          Icon(
                                            isDownloaded
                                                ? Icons.download_done_rounded
                                                : Icons.download_rounded,
                                            size: 20,
                                            color: isDownloaded
                                                ? const Color(0xFF1DB954)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            isDownloaded ? 'Đã tải' : 'Tải nhạc',
                                            style: TextStyle(
                                              color: isDownloaded
                                                  ? const Color(0xFF1DB954)
                                                  : null,
                                            ),
                                          )
                                        ]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          Icon(Icons.delete_outline_rounded,
                                              size: 20, color: Colors.redAccent),
                                          SizedBox(width: 12),
                                          Text('Xóa khỏi danh sách',
                                              style: TextStyle(
                                                  color: Colors.redAccent))
                                        ]),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                      onTap: () => context
                          .read<PlayerBloc>()
                          .add(SkipToIndexEvent(index)),
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

  void _goToLyrics() => _pageController.animateToPage(1,
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  void _goToPlayer() => _pageController.animateToPage(0,
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  void _showComments(BuildContext context, String songId) {
    context.read<CommentCubit>().loadComments(songId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<CommentCubit>(),
        child: _CommentsSheet(songId: songId),
      ),
    );
  }

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
          if (currentSong == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isPlaying = state is PlayerPlaying;
          final isShuffle = state is PlayerPlaying
              ? state.isShuffle
              : (state is PlayerPaused ? state.isShuffle : false);
          final repeatMode = state is PlayerPlaying
              ? state.repeatMode
              : (state is PlayerPaused ? state.repeatMode : RepeatMode.none);

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
                        // ── Page 1: Player ──────────────────────────────
                        Column(
                          children: [
                            _TopBar(
                                isOnPlayerPage: true,
                                onActionTap: _goToLyrics,
                                title: currentSong.title), // ✅ truyền title
                            const SizedBox(height: 16),
                            Expanded(
                              flex: 5,
                              child: _VinylDisc(
                                artUrl: currentSong.artUri?.toString(),
                                heroTag: 'album-art-${currentSong.id}',
                                isPlaying: isPlaying,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: _SongInfo(song: currentSong),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: ProgressBarWidget(
                                service:
                                    context.read<MusicPlayerService>(),
                                onSeek: (pos) => context
                                    .read<PlayerBloc>()
                                    .add(SeekEvent(pos)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _Controls(
                              isPlaying: isPlaying,
                              isShuffle: isShuffle,
                              repeatMode: repeatMode,
                              onPlay: () => context
                                  .read<PlayerBloc>()
                                  .add(const PlayEvent()),
                              onPause: () => context
                                  .read<PlayerBloc>()
                                  .add(const PauseEvent()),
                              onNext: () => context
                                  .read<PlayerBloc>()
                                  .add(const NextEvent()),
                              onPrevious: () => context
                                  .read<PlayerBloc>()
                                  .add(const PreviousEvent()),
                              onShuffle: () => context
                                  .read<PlayerBloc>()
                                  .add(const ToggleShuffleEvent()),
                              onRepeat: () => context
                                  .read<PlayerBloc>()
                                  .add(const CycleRepeatEvent()),
                              onQueueTap: () => _showQueue(context, state),
                              onCommentTap: () => _showComments(context, currentSong.id),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                        // ── Page 2: Lyrics ───────────────────────────────
                        Column(
                          children: [
                            _TopBar(
                                isOnPlayerPage: false,
                                onActionTap: _goToPlayer,
                                title: currentSong.title), // ✅ truyền title
                            Expanded(
                              child: LyricsPage(
                                  song: currentSong,
                                  lyricsService: getIt<LyricsService>(),
                                  positionStream: getIt<MusicPlayerService>().positionStream,
                                  onSeek: (position) => context.read<PlayerBloc>().add(SeekEvent(position)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Page indicator dots
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withValues(alpha: 0.3),
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
// Vinyl Disc — thay thế _AlbumArt
// ─────────────────────────────────────────────────────────────

class _VinylDisc extends StatefulWidget {
  final String? artUrl;
  final String heroTag;
  final bool isPlaying;

  const _VinylDisc({
    this.artUrl,
    required this.heroTag,
    required this.isPlaying,
  });

  @override
  State<_VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<_VinylDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.isPlaying) _spinCtrl.repeat();
  }

  @override
  void didUpdateWidget(_VinylDisc old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.isPlaying && _spinCtrl.isAnimating) {
      _spinCtrl.stop();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final discSize =
        (MediaQuery.of(context).size.width * 0.72).clamp(0.0, 300.0);
    final artSize = discSize * 0.42;
    final tonearmAngle = widget.isPlaying ? -0.13 : -0.42;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _spinCtrl,
          builder: (_, child) => Transform.rotate(
            angle: _spinCtrl.value * 2 * math.pi,
            child: child,
          ),
          child: Hero(
            tag: widget.heroTag,
            child: SizedBox.square(
              dimension: discSize,
              child: CustomPaint(
                painter: _VinylPainter(color: cs.primary),
                child: Center(
                  child: ClipOval(
                    child: SizedBox.square(
                      dimension: artSize,
                      child: widget.artUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.artUrl!,
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
          ),
        ),
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surface,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          ),
        ),
        Positioned(
          top: 0,
          right: discSize * 0.08,
          child: AnimatedRotation(
            turns: tonearmAngle / (2 * math.pi),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: const Alignment(1.0, -1.0),
            child: _TonearmPainter(size: discSize * 0.52),
          ),
        ),
      ],
    );
  }
}

class _VinylPainter extends CustomPainter {
  final Color color;
  _VinylPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final bgPaint = Paint()..color = const Color(0xFF111122);
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double frac in [0.95, 0.88, 0.80, 0.72, 0.64, 0.56]) {
      canvas.drawCircle(Offset(cx, cy), r * frac, groovePaint);
    }

    final labelPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.48, labelPaint);

    final labelBorder = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), r * 0.48, labelBorder);
  }

  @override
  bool shouldRepaint(_VinylPainter old) => old.color != color;
}

class _TonearmPainter extends StatelessWidget {
  final double size;
  const _TonearmPainter({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.38, size),
      painter: _TonearmCustomPainter(),
    );
  }
}

class _TonearmCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pivotX = size.width * 0.85;
    final pivotY = size.height * 0.05;
    final tipX = size.width * 0.10;
    final tipY = size.height * 0.92;

    final basePaint = Paint()..color = const Color(0xFF4a4a7a);
    canvas.drawCircle(Offset(pivotX, pivotY), size.width * 0.22, basePaint);
    final baseBorder = Paint()
      ..color = const Color(0xFF8080c0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(pivotX, pivotY), size.width * 0.22, baseBorder);
    final innerDot = Paint()..color = const Color(0xFF7070b0);
    canvas.drawCircle(Offset(pivotX, pivotY), size.width * 0.10, innerDot);

    final armPaint = Paint()
      ..color = const Color(0xFF9090c0)
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pivotX, pivotY + size.width * 0.2),
        Offset(tipX + size.width * 0.1, tipY - size.height * 0.06), armPaint);

    final shellRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(tipX + size.width * 0.08, tipY - size.height * 0.04),
        width: size.width * 0.45,
        height: size.height * 0.1,
      ),
      const Radius.circular(3),
    );
    final shellPaint = Paint()..color = const Color(0xFF4a4a7c);
    canvas.drawRRect(shellRect, shellPaint);
    final shellBorder = Paint()
      ..color = const Color(0xFF7070b0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(shellRect, shellBorder);

    final needlePaint = Paint()
      ..color = const Color(0xFFc0c0e0)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(tipX + size.width * 0.08, tipY + size.height * 0.03),
      Offset(tipX + size.width * 0.08, tipY + size.height * 0.09),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PlayerBackground extends StatelessWidget {
  final String? artUrl;
  final Widget child;
  const _PlayerBackground({this.artUrl, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            AppTheme.playerGradient(Theme.of(context).colorScheme.primary),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ✅ SỬA _TopBar: thêm tham số title
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isOnPlayerPage;
  final VoidCallback onActionTap;
  final String title; // ✅ thêm dòng này

  const _TopBar({
    required this.isOnPlayerPage,
    required this.onActionTap,
    required this.title, // ✅ required
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOnPlayerPage ? 'NOW PLAYING' : 'LỜI BÀI HÁT',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title, // ✅ dùng biến thay vì hardcode
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          _IconBtn(
            icon: isOnPlayerPage
                ? Icons.lyrics_outlined
                : Icons.music_note_rounded,
            onTap: onActionTap,
          ),
        ],
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
          size: 40, color: Theme.of(context).colorScheme.primary),
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
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          onTap: () async {
            try {
              await context.read<FavoriteCubit>().toggleFavorite(song.id);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(
                      e.toString().replaceFirst('Exception: ', '')),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ));
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
  final VoidCallback onPlay, onPause, onNext, onPrevious, onShuffle, onRepeat,
      onQueueTap, onCommentTap;

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
    required this.onQueueTap,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Xác định icon và màu sắc cho RepeatMode
    IconData repeatIcon = Icons.repeat_rounded;
    Color? repeatColor;
    if (repeatMode == RepeatMode.all) {
      repeatColor = cs.primary;
    } else if (repeatMode == RepeatMode.one) {
      repeatIcon = Icons.repeat_one_rounded;
      repeatColor = cs.primary;
    }

    return Column(
      children: [
        // HÀNG 1: Trộn bài, Trở lại, Phát/Dừng, Tiếp theo, Lặp lại
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBtn(
                  icon: Icons.shuffle_rounded,
                  onTap: onShuffle,
                  color: isShuffle ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                  size: 26),
              _IconBtn(
                  icon: Icons.skip_previous_rounded,
                  onTap: onPrevious,
                  size: 40,
                  color: cs.onSurface),
              _PlayButton(
                  isPlaying: isPlaying, onPlay: onPlay, onPause: onPause),
              _IconBtn(
                  icon: Icons.skip_next_rounded,
                  onTap: onNext,
                  size: 40,
                  color: cs.onSurface),
              _IconBtn(
                  icon: repeatIcon,
                  onTap: onRepeat,
                  color: repeatColor ?? cs.onSurface.withValues(alpha: 0.5),
                  size: 26),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // HÀNG 2: Form Bình luận và Danh sách phát (Queue)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Nút Danh sách phát
              Material(
                color: cs.surfaceTint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onQueueTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Icon(Icons.queue_music_rounded, size: 24, color: cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nút Bình luận hình form nhập liệu
              Expanded(
                child: Material(
                  color: cs.surfaceTint.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onCommentTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 22, color: cs.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 12),
                          Text('Viết bình luận...', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay, onPause;
  const _PlayButton(
      {required this.isPlaying,
      required this.onPlay,
      required this.onPause});

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
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
  const _IconBtn(
      {required this.icon,
      required this.onTap,
      this.color,
      this.size = 24});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).iconTheme.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        splashColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: c, size: size)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Public helper: mở bình luận từ bất kỳ nơi nào trong app
// ─────────────────────────────────────────────────────────────
void showSongComments(BuildContext context, String songId, {String? songTitle}) {
  final cubit = getIt<CommentCubit>()..loadComments(songId);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => BlocProvider.value(
      value: cubit,
      child: _CommentsSheet(songId: songId, songTitle: songTitle),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// _CommentsSheet – bottom sheet bình luận
// ─────────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String songId;
  final String? songTitle;
  const _CommentsSheet({required this.songId, this.songTitle});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để bình luận'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final displayName = (user.userMetadata?['name'] as String?)?.isNotEmpty == true
        ? user.userMetadata!['name'] as String
        : (user.email ?? 'Anonymous');

    context.read<CommentCubit>().addComment(
          songId: widget.songId,
          userId: user.id,
          displayName: displayName,
          content: content,
        );
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bình luận',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (widget.songTitle != null)
                        Text(
                          widget.songTitle!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments list
          Expanded(
            child: BlocBuilder<CommentCubit, CommentState>(
              builder: (context, state) {
                if (state is CommentLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CommentError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (state is CommentLoaded) {
                  if (state.comments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Chưa có bình luận nào',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.comments.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final comment = state.comments[index];
                      final isOwner = comment.userId == currentUserId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            comment.displayName.isNotEmpty
                                ? comment.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                comment.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeAgo(comment.createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(comment.content),
                        ),
                        trailing: isOwner
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.redAccent),
                                onPressed: () {
                                  context.read<CommentCubit>().deleteComment(
                                        comment.id,
                                        comment.userId,
                                        widget.songId,
                                      );
                                },
                              )
                            : null,
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Input area
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 500,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(context),
                    decoration: InputDecoration(
                      hintText: 'Thêm bình luận...',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _send(context),
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}