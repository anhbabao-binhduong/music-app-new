import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/services/lyrics_service.dart';

class LyricsPage extends StatefulWidget {
  final MediaItem song;
  final LyricsService lyricsService;
  final Stream<Duration> positionStream;
  final void Function(Duration position)? onSeek;

  const LyricsPage({
    super.key,
    required this.song,
    required this.lyricsService,
    required this.positionStream,
    this.onSeek,
  });

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late Future<LyricsData?> _lyricsFuture;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didUpdateWidget(covariant LyricsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) _fetchLyrics();
  }

  void _fetchLyrics() {
    setState(() {
      _lyricsFuture = widget.lyricsService.getLyrics(
        artist: widget.song.artist ?? 'Unknown',
        title: widget.song.title,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<LyricsData?>(
      future: _lyricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đang tải lời bài hát...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;

        if (data == null || !data.hasAnyLyrics) {
          return _NoLyrics(title: widget.song.title, onRetry: _fetchLyrics);
        }

        if (data.isSynced) {
          return _SyncedLyricsBody(
            lyrics: data.syncedLyrics!,
            positionStream: widget.positionStream,
            onSeek: widget.onSeek,
          );
        }

        return _PlainLyricsBody(lyrics: data.plainLyrics!);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Synced Lyrics
// ─────────────────────────────────────────────────────────────

class _SyncedLyricsBody extends StatefulWidget {
  final List<LyricLine> lyrics;
  final Stream<Duration> positionStream;
  final void Function(Duration position)? onSeek;

  const _SyncedLyricsBody({
    required this.lyrics,
    required this.positionStream,
    this.onSeek,
  });

  @override
  State<_SyncedLyricsBody> createState() => _SyncedLyricsBodyState();
}

class _SyncedLyricsBodyState extends State<_SyncedLyricsBody> {
  final ScrollController _scrollController = ScrollController();

  // Dùng GlobalKey để đo vị trí thực của từng item
  final Map<int, GlobalKey> _keys = {};

  int _lastScrolledIndex = -2;

  int _findActiveIndex(Duration position) {
    final lyrics = widget.lyrics;
    if (lyrics.isEmpty) return -1;
    if (lyrics[0].time > position) return -1;

    int lo = 0, hi = lyrics.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lyrics[mid].time <= position) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  void _scrollToIndex(int index) {
    if (index < 0 || index == _lastScrolledIndex) return;
    _lastScrolledIndex = index;

    final key = _keys[index];
    if (key?.currentContext == null) return;

    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      alignment: 0.38, // dòng active nằm 38% từ trên → tự nhiên hơn center
    );
  }

  GlobalKey _keyFor(int index) {
    return _keys.putIfAbsent(index, () => GlobalKey());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return StreamBuilder<Duration>(
      stream: widget.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final activeIndex = _findActiveIndex(position);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(activeIndex);
        });

        return ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.12, 0.88, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              vertical: screenH * 0.38,
              horizontal: 28,
            ),
            itemCount: widget.lyrics.length,
            itemBuilder: (context, index) {
              final line = widget.lyrics[index];
              final isActive = index == activeIndex;

              // Dòng trống → spacer nhỏ
              if (line.text.isEmpty) {
                return const SizedBox(height: 18);
              }

              // Khoảng cách xa active → mờ hơn
              final distance = (index - activeIndex).abs();
              final opacity = activeIndex < 0
                  ? 0.5
                  : isActive
                      ? 1.0
                      : distance == 1
                          ? 0.45
                          : distance == 2
                              ? 0.28
                              : 0.18;

              return GestureDetector(
                key: _keyFor(index),
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onSeek?.call(line.time),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isActive ? 10 : 7,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: isActive ? 26 : 18,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w500,
                      height: 1.45,
                      letterSpacing: isActive ? 0.2 : 0.0,
                      color: Colors.white.withValues(alpha: opacity),
                      shadows: isActive
                          ? [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.25),
                                blurRadius: 20,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      line.text,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Plain Lyrics
// ─────────────────────────────────────────────────────────────

class _PlainLyricsBody extends StatelessWidget {
  final String lyrics;
  const _PlainLyricsBody({required this.lyrics});

  @override
  Widget build(BuildContext context) {
    final lines = lyrics.split('\n');
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.06, 0.94, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          children: lines.map((line) {
            if (line.trim().isEmpty) return const SizedBox(height: 18);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                line.trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────

class _NoLyrics extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const _NoLyrics({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 52,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 20),
            Text(
              'Không có lời bài hát',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Text(
                      'Thử lại',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}