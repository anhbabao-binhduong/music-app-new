import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/services/lyrics_service.dart';

class LyricsPage extends StatefulWidget {
  final MediaItem song;
  final LyricsService lyricsService;
  final Stream<Duration> positionStream;

  const LyricsPage({
    super.key,
    required this.song,
    required this.lyricsService,
    required this.positionStream,
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
    if (oldWidget.song.id != widget.song.id) {
      _fetchLyrics();
    }
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
            child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
          );
        }

        final data = snapshot.data;

        // Nếu không có dữ liệu trả về, gọi class _NoLyrics
        if (data == null || !data.hasAnyLyrics) {
          return _NoLyrics(title: widget.song.title, onRetry: _fetchLyrics);
        }

        // Nếu có Synced Lyrics (karaoke)
        if (data.isSynced) {
          return _SyncedLyricsBody(
            lyrics: data.syncedLyrics!,
            positionStream: widget.positionStream,
          );
        }

        // Nếu chỉ có Plain Lyrics tĩnh
        return _PlainLyricsBody(lyrics: data.plainLyrics!);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Synced Lyrics (Karaoke mode) - Màu trắng, đổ bóng đen
// ─────────────────────────────────────────────────────────────

class _SyncedLyricsBody extends StatefulWidget {
  final List<LyricLine> lyrics;
  final Stream<Duration> positionStream;

  const _SyncedLyricsBody({
    required this.lyrics,
    required this.positionStream,
  });

  @override
  State<_SyncedLyricsBody> createState() => _SyncedLyricsBodyState();
}

class _SyncedLyricsBodyState extends State<_SyncedLyricsBody> {
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex(int index) {
    if (index == _activeIndex || index < 0) return;
    _activeIndex = index;

    if (_scrollController.hasClients) {
      final offset = (index * 60.0) - (MediaQuery.of(context).size.height / 3);
      _scrollController.animateTo(
        offset > 0 ? offset : 0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.positionStream,
      builder: (context, snapshot) {
        final currentPosition = snapshot.data ?? Duration.zero;

        int newActiveIndex = -1;
        for (int i = 0; i < widget.lyrics.length; i++) {
          if (widget.lyrics[i].time <= currentPosition &&
              (i == widget.lyrics.length - 1 || widget.lyrics[i + 1].time > currentPosition)) {
            newActiveIndex = i;
            break;
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveIndex(newActiveIndex);
        });

        return ShaderMask(
          shaderCallback: (Rect rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height / 3,
              bottom: MediaQuery.of(context).size.height / 2,
              left: 24,
              right: 24,
            ),
            itemCount: widget.lyrics.length,
            itemBuilder: (context, index) {
              final line = widget.lyrics[index];
              final isActive = index == newActiveIndex;

              if (line.text.isEmpty) return const SizedBox(height: 24);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                        fontSize: isActive ? 28 : 20,
                        height: 1.4,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: isActive ? 0.6 : 0.4),
                            blurRadius: isActive ? 12 : 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                  child: Text(line.text),
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
// Plain Lyrics (Fallback) - Màu trắng, đổ bóng đen
// ─────────────────────────────────────────────────────────────

class _PlainLyricsBody extends StatelessWidget {
  final String lyrics;
  const _PlainLyricsBody({required this.lyrics});

  @override
  Widget build(BuildContext context) {
    final lines = lyrics.split('\n');
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
          stops: [0.0, 0.05, 0.95, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          children: lines.map((line) {
            if (line.trim().isEmpty) return const SizedBox(height: 16);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                line.trim(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
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
// Empty state với nút Thử lại
// ─────────────────────────────────────────────────────────────

class _NoLyrics extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const _NoLyrics({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có lời bài hát',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$title"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}