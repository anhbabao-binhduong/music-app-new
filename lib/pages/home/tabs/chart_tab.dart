import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/chart_top_song.dart';
import '../../../domain/entities/chart_trend_point.dart';
import '../../../presentation/bloc/chart/chart_cubit.dart';
import '../../../presentation/bloc/chart/chart_state.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';

// ── Design tokens ─────────────────────────────────────────────────────
const _kBg = Colors.transparent;
const _kCard = Color(0xFF161626);
const _kDivider = Color(0xFF2A2A2E);
const _kAccentGlow = Color(0xFFEC4899);

// Line colors for top 3 songs (updated brand colors)
const _kLine1 = Color(0xFF9333EA); // Brand primary
const _kLine2 = Color(0xFFEC4899); // Brand accent
const _kLine3 = Color(0xFF06B6D4); // Cyan/teal

class ChartTab extends StatelessWidget {
  const ChartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChartCubit>(),
      child: const _ChartView(),
    );
  }
}

class _ChartView extends StatefulWidget {
  const _ChartView();
  @override
  State<_ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<_ChartView> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  static const _lineColors = [_kLine1, _kLine2, _kLine3];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────
  void _play(BuildContext ctx, int idx, List<ChartTopSong> songs) {
    if (songs.isEmpty) return;
    final q = songs.map((e) {
      final s = e.song;
      return MediaItem(
        id: s.id, title: s.title, artist: s.artist, album: s.album,
        artUri: s.artUrl != null ? Uri.tryParse(s.artUrl!) : null,
        duration: Duration(milliseconds: s.durationMs),
        extras: {
          'url': s.audioUrl,
          'songDbId': s.id, // ID số từ bảng songs → dùng để đếm lượt nghe
        },
      );
    }).toList();
    ctx.read<PlayerBloc>().add(LoadPlaylistEvent(q, startIndex: idx));
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // ── build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF3F4F8) : _kBg,
      body: BlocConsumer<ChartCubit, ChartState>(
        listener: (_, __) { _anim.reset(); _anim.forward(); },
        builder: (ctx, state) {
          return FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _header(ctx, state.filter),
                if (state is ChartLoading) _shimmer(),
                if (state is ChartError) _error(state.message),
                if (state is ChartLoaded) ...[
                  _lineChartCard(state),
                  _rankHeader(),
                  _rankList(state),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _header(BuildContext ctx, ChartFilter filter) {
    final theme = Theme.of(ctx);
    final onSurface = theme.colorScheme.onSurface;
    final isLight = theme.brightness == Brightness.light;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? [
                    const Color(0xFF6D28D9),
                    const Color(0xFF8B5CF6),
                    Colors.transparent,
                  ]
                : [const Color(0xFF3A1078), const Color(0xFF1A0537), _kBg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('#zingchart', style: TextStyle(
            fontSize: 34, fontWeight: FontWeight.w900, color: isLight ? Colors.white : onSurface,
            letterSpacing: 1, shadows: [
              Shadow(color: _kAccentGlow.withValues(alpha: 0.7), blurRadius: 20),
              Shadow(color: _kAccentGlow.withValues(alpha: 0.4), blurRadius: 40),
            ],
          )),
          const SizedBox(height: 20),
          Row(children: [
            _pill(ctx, ChartFilter.today, 'Hôm nay', filter),
            const SizedBox(width: 10),
            _pill(ctx, ChartFilter.week, 'Tuần', filter),
            const SizedBox(width: 10),
            _pill(ctx, ChartFilter.month, 'Tháng', filter),
          ]),
        ]),
      ),
    );
  }

  Widget _pill(BuildContext ctx, ChartFilter f, String label, ChartFilter cur) {
    final on = f == cur;
    final theme = Theme.of(ctx);
    final onSurface = theme.colorScheme.onSurface;
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () => ctx.read<ChartCubit>().loadChart(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          gradient: on ? const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFEC4899)]) : null,
          color: on
              ? null
              : (isLight ? Colors.white.withValues(alpha: 0.82) : Colors.transparent),
          borderRadius: BorderRadius.circular(24),
          border: on
              ? null
              : Border.all(
                  color: isLight
                      ? onSurface.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.15),
                ),
        ),
        child: Text(label, style: TextStyle(
          color: on ? Colors.white : (isLight ? onSurface : Colors.white.withValues(alpha: 0.5)),
          fontWeight: on ? FontWeight.w700 : FontWeight.w500, fontSize: 13.5,
        )),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SHIMMER
  // ═══════════════════════════════════════════════════════════════════
  Widget _shimmer() => SliverToBoxAdapter(
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isLight = theme.brightness == Brightness.light;

        return Shimmer.fromColors(
          baseColor: isLight
              ? colorScheme.surfaceContainerHighest
              : const Color(0xFF1E1E22),
          highlightColor: isLight
              ? colorScheme.surface
              : const Color(0xFF2C2C32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                ...List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(width: 32, height: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        const CircleAvatar(radius: 24, backgroundColor: Colors.white),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 14, width: 150, color: Colors.white),
                              const SizedBox(height: 8),
                              Container(height: 12, width: 100, color: Colors.white),
                            ],
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
      },
    ),
  );

  Widget _error(String msg) => SliverFillRemaining(
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isLight = theme.brightness == Brightness.light;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: colorScheme.onSurface.withValues(alpha: isLight ? 0.28 : 0.15),
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: isLight ? 0.65 : 0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  // ═══════════════════════════════════════════════════════════════════
  //  LINE CHART CARD  (stock-style)
  // ═══════════════════════════════════════════════════════════════════
  Widget _lineChartCard(ChartLoaded state) {
    if (state.topSongs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final top3 = state.topSongs.take(3).toList();

    // Group trend data by songId
    final Map<String, List<ChartTrendPoint>> bySong = {};
    for (var t in state.trends) {
      bySong.putIfAbsent(t.songId, () => []);
      bySong[t.songId]!.add(t);
    }

    // Generate full slot labels for X-axis
    final slots = _slots(state.filter);

    // Build line data for each song
    double maxY = 0;
    final List<LineChartBarData> lines = [];

    for (int i = 0; i < top3.length; i++) {
      final sid = top3[i].song.id;
      final pts = bySong[sid] ?? [];
      final List<FlSpot> spots = [];

      for (int x = 0; x < slots.length; x++) {
        final label = slots[x];
        final match = pts.where((p) => _match(p.dateLabel, label, state.filter));
        // Sum all matches for this slot (in case multiple entries)
        double val = 0;
        for (var m in match) { val += m.playCount; }
        if (val > maxY) maxY = val;
        spots.add(FlSpot(x.toDouble(), val));
      }

      final color = _lineColors[i];
      lines.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.35,
        preventCurveOverShooting: true,
        color: color,
        barWidth: 3.0,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 0,
              color: Colors.transparent,
              strokeWidth: 0,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ));
    }

    double ceilingY = maxY <= 1 ? 10 : (maxY * 1.15).ceilToDouble();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF8F6FF) : _kCard,
            borderRadius: BorderRadius.circular(16),
            border: isLight
                ? Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.08))
                : Border.all(color: Colors.white.withValues(alpha: 0.04)),
            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.07),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Xu hướng nghe',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isLight ? colorScheme.onSurface : Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0, maxY: ceilingY,
                  lineBarsData: lines,
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: (ceilingY / 3).ceilToDouble().clamp(1, double.infinity),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: isLight
                          ? const Color(0xFF1A1730).withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.10),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28, interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= slots.length) return const SizedBox.shrink();
                        
                        final label = slots[idx];
                        if (state.filter == ChartFilter.today) {
                          // Only show specific 6 milestones
                          const milestones = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
                          if (!milestones.contains(label)) return const SizedBox.shrink();
                        } else {
                          int labelInterval = slots.length > 14 ? 3 : (slots.length > 8 ? 2 : 1);
                          if (idx % labelInterval != 0 && idx != slots.length - 1) {
                            return const SizedBox.shrink();
                          }
                        }

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _displayLabel(label, state.filter),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: isLight
                                  ? const Color(0xFF6B5EA8)
                                  : const Color(0xFF8B8AA8),
                            ),
                          ),
                        );
                      },
                    )),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          const FlLine(color: Colors.transparent),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 8,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: barData.color ?? Colors.white,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => isLight
                          ? Colors.white
                          : const Color(0xF0222228),
                      fitInsideHorizontally: true, fitInsideVertically: true,
                      getTooltipItems: (spots) => spots.map((s) {
                        if (s.barIndex >= top3.length) return null;
                        final name = top3[s.barIndex].song.title;
                        final time = _displayLabel(slots[s.x.toInt()], state.filter);
                        return LineTooltipItem(
                          '$name\n',
                          TextStyle(color: _lineColors[s.barIndex], fontWeight: FontWeight.w700, fontSize: 12),
                          children: [TextSpan(
                            text: '${s.y.toInt()} lượt · $time',
                            style: TextStyle(
                              color: isLight
                                  ? colorScheme.onSurface.withValues(alpha: 0.72)
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          )],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 14),
            _legend(top3),
          ]),
        ),
      ),
    );
  }

  // ── slot generation ─────────────────────────────────────────────────
  List<String> _slots(ChartFilter f) {
    final now = DateTime.now();
    switch (f) {
      case ChartFilter.today:
        return List.generate(24, (h) => '${h.toString().padLeft(2, '0')}:00');
      case ChartFilter.week:
        return List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        });
      case ChartFilter.month:
        return List.generate(30, (i) {
          final d = now.subtract(Duration(days: 29 - i));
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        });
    }
  }

  bool _match(String dbLabel, String slot, ChartFilter f) {
    switch (f) {
      case ChartFilter.today:
        // dbLabel "2026-04-11 08:00", slot "08:00"
        return dbLabel.endsWith(slot);
      case ChartFilter.week:
      case ChartFilter.month:
        // dbLabel "2026-04-11", slot "2026-04-11"
        return dbLabel == slot;
    }
  }

  String _displayLabel(String slot, ChartFilter f) {
    switch (f) {
      case ChartFilter.today:
        return slot; // "08:00"
      case ChartFilter.week:
      case ChartFilter.month:
        // "2026-04-11" → "11/04"
        final p = slot.split('-');
        return '${p[2]}/${p[1]}';
    }
  }

  Widget _legend(List<ChartTopSong> top3) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: List.generate(
        top3.length,
        (i) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _lineColors[i],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                top3[i].song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isLight
                      ? const Color(0xFF6B5EA8)
                      : const Color(0xFF8B8AA8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TOP 10 RANKING
  // ═══════════════════════════════════════════════════════════════════
  Widget _rankHeader() => SliverToBoxAdapter(
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isLight = theme.brightness == Brightness.light;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                children: [
                  if (isLight) ...[
                    Container(
                      width: 4,
                      height: 22,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                  Text(
                    'Bảng Xếp Hạng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isLight
                          ? colorScheme.onSurface
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _rankList(ChartLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    if (state.topSongs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Không có dữ liệu',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: isLight ? 0.55 : 0.3),
              ),
            ),
          ),
        ),
      );
    }

    // Light mode: wrap the whole list in a card with soft shadow
    if (isLight) {
      return SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: List.generate(state.topSongs.length, (i) {
                      final item = state.topSongs[i];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _rankItem(context, i, item, state.topSongs),
                          ),
                          if (i < state.topSongs.length - 1)
                            Divider(
                              color: colorScheme.onSurface.withValues(alpha: 0.06),
                              height: 1,
                              thickness: 0.5,
                              indent: 70,
                              endIndent: 16,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final item = state.topSongs[i];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Column(
                  children: [
                    _rankItem(ctx, i, item, state.topSongs),
                    if (i < state.topSongs.length - 1)
                      Divider(
                        color: _kDivider,
                        height: 1,
                        thickness: 0.5,
                        indent: 56,
                        endIndent: 8,
                      ),
                  ],
                ),
              ),
            );
          },
          childCount: state.topSongs.length,
        ),
      ),
    );
  }

  Widget _rankItem(BuildContext ctx, int idx, ChartTopSong item, List<ChartTopSong> all) {
    final theme = Theme.of(ctx);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    // Rank style
    Color rc;
    double rs;
    if (idx == 0) {
      rc = const Color(0xFFFFD700);
      rs = 26;
    } else if (idx == 1) {
      rc = const Color(0xFFC0C0C0);
      rs = 24;
    } else if (idx == 2) {
      rc = const Color(0xFFCD7F32);
      rs = 22;
    } else {
      rc = colorScheme.onSurface.withValues(alpha: isLight ? 0.42 : 0.35);
      rs = 18;
    }

    // Trend
    IconData ti;
    Color tc;
    if (item.trend == ChartTrend.up) {
      ti = Icons.arrow_drop_up_rounded;
      tc = const Color(0xFF4CAF50);
    } else if (item.trend == ChartTrend.down) {
      ti = Icons.arrow_drop_down_rounded;
      tc = const Color(0xFFE53935);
    } else {
      ti = Icons.remove_rounded;
      tc = colorScheme.onSurface.withValues(alpha: isLight ? 0.28 : 0.2);
    }

    // Thumb border
    final border = idx < 3
        ? [_lineColors[idx], _lineColors[idx].withValues(alpha: 0.3)]
        : [
            colorScheme.onSurface.withValues(alpha: isLight ? 0.12 : 0.1),
            colorScheme.onSurface.withValues(alpha: isLight ? 0.06 : 0.05),
          ];

    final thumbBg = isLight ? const Color(0xFFF3F4F8) : _kCard;
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurface.withValues(alpha: isLight ? 0.55 : 0.4);
    // play count: purple accent in light mode
    const accentPurple = Color(0xFF7C3AED);
    final countColor = isLight ? accentPurple : colorScheme.onSurface.withValues(alpha: 0.7);
    final iconColor = isLight ? accentPurple.withValues(alpha: 0.45) : colorScheme.onSurface.withValues(alpha: 0.25);

    return InkWell(
      onTap: () => _play(ctx, idx, all),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Text(
                    '${idx + 1}',
                    style: TextStyle(
                      fontSize: rs,
                      fontWeight: FontWeight.w900,
                      color: rc,
                      height: 1,
                      shadows: idx < 3
                          ? [Shadow(color: rc.withValues(alpha: 0.4), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  Icon(ti, color: tc, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: border,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: item.song.artUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: thumbBg),
                    errorWidget: (_, __, ___) => Container(
                      color: thumbBg,
                      child: Icon(
                        Icons.music_note_rounded,
                        color: colorScheme.onSurface.withValues(alpha: isLight ? 0.28 : 0.2),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isLight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headset_rounded, size: 11, color: iconColor),
                        const SizedBox(width: 4),
                        Text(
                          _compact(item.playCount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: countColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    _compact(item.playCount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: countColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(Icons.headset_rounded, size: 13, color: iconColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
