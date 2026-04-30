import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                   style: GoogleFonts.dmSans(
                     color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF1A1730).withValues(alpha: 0.6),
                     fontSize: 12,
                     fontWeight: FontWeight.w500,
                     letterSpacing: 0.3,
                     height: 1.35,
                   ),
                 ),
              ],
            ),
          );
        }

        final data = snapshot.data;

         if (data == null || !data.hasAnyLyrics) {
           return _NoLyrics(title: widget.song.title, onRetry: _fetchLyrics, isDark: isDark);
         }

         if (data.isSynced) {
           return _SyncedLyricsBody(
             lyrics: data.syncedLyrics!,
             positionStream: widget.positionStream,
             onSeek: widget.onSeek,
             isDark: isDark,
           );
         }
 
         return _PlainLyricsBody(lyrics: data.plainLyrics!, isDark: isDark);
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
  final bool isDark;

  const _SyncedLyricsBody({
    required this.lyrics,
    required this.positionStream,
    this.onSeek,
    required this.isDark,
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

               // Text color: active = purple accent, inactive = dimmed dark
               final textColor = isActive
                   ? (widget.isDark ? const Color(0xFF9333EA) : const Color(0xFF9333EA))
                   : (widget.isDark
                       ? Colors.white.withValues(alpha: opacity)
                       : const Color(0xFF1A1730).withValues(alpha: opacity));

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
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: isActive ? 26 : 18,
                       fontWeight:
                           isActive ? FontWeight.w800 : FontWeight.w500,
                       height: 1.45,
                       letterSpacing: isActive ? -0.2 : 0.0,
                       color: textColor,
                       shadows: isActive
                           ? [
                               Shadow(
                                 color: widget.isDark
                                     ? Colors.white.withValues(alpha: 0.25)
                                     : const Color(0xFF9333EA).withValues(alpha: 0.3),
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
  final bool isDark;
  const _PlainLyricsBody({required this.lyrics, required this.isDark});

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
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF1A1730).withValues(alpha: 0.7),
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
  final bool isDark;

  const _NoLyrics({required this.title, required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? Colors.transparent : const Color(0xFFF5F3FF);
    
    return Center(
      child: Container(
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lyrics_outlined,
                size: 52,
                color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF6B5EA8).withValues(alpha: 0.35),
              ),
              const SizedBox(height: 20),
              Text(
                'Không có lời bài hát',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF1A1730),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF6B5EA8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
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
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF6B5EA8).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 16,
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B5EA8)),
                      const SizedBox(width: 8),
                      Text(
                        'Thử lại',
                        style: GoogleFonts.dmSans(
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B5EA8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
