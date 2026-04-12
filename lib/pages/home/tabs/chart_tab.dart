import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/chart_top_song.dart';
import '../../../domain/entities/chart_trend_point.dart';
import '../../../presentation/bloc/chart/chart_cubit.dart';
import '../../../presentation/bloc/chart/chart_state.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';

// ── Design tokens ─────────────────────────────────────────────────────
const _kBg = Color(0xFF0D0D0D);
const _kCard = Color(0xFF161618);
const _kDivider = Color(0xFF2A2A2E);
const _kAccentGlow = Color(0xFFAB47BC);

// Line colors for top 3 songs
const _kLine1 = Color(0xFF4A90E2); // Blue
const _kLine2 = Color(0xFF1DB954); // Green
const _kLine3 = Color(0xFFFF6B6B); // Orange/Red

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
        extras: {'url': s.audioUrl},
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
    return Scaffold(
      backgroundColor: _kBg,
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
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A1078), Color(0xFF1A0537), _kBg],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('#zingchart', style: TextStyle(
            fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white,
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
    return GestureDetector(
      onTap: () => ctx.read<ChartCubit>().loadChart(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          gradient: on ? const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)]) : null,
          borderRadius: BorderRadius.circular(24),
          border: on ? null : Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(label, style: TextStyle(
          color: on ? Colors.white : Colors.white.withValues(alpha: 0.5),
          fontWeight: on ? FontWeight.w700 : FontWeight.w400, fontSize: 13.5,
        )),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SHIMMER
  // ═══════════════════════════════════════════════════════════════════
  Widget _shimmer() => SliverToBoxAdapter(
    child: Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E22), highlightColor: const Color(0xFF2C2C32),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
        Container(height: 200, margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ...List.generate(5, (_) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
          Container(width: 32, height: 20, color: Colors.white), const SizedBox(width: 12),
          const CircleAvatar(radius: 24, backgroundColor: Colors.white), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 14, width: 150, color: Colors.white), const SizedBox(height: 8),
            Container(height: 12, width: 100, color: Colors.white),
          ])),
        ]))),
      ])),
    ),
  );

  Widget _error(String msg) => SliverFillRemaining(child: Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: Colors.white.withValues(alpha: 0.15), size: 56),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
    ],
  )));

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
        barWidth: 1.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4, // 4px dot
              color: Colors.white,
              strokeWidth: 1.5,
              strokeColor: color,
            );
          },
        ),
        belowBarData: BarAreaData(show: false),
      ));
    }

    double ceilingY = maxY <= 1 ? 10 : (maxY * 1.15).ceilToDouble();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 14),
              child: Text('Xu hướng nghe', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0, maxY: ceilingY,
                  lineBarsData: lines,
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: (ceilingY / 3).ceilToDouble().clamp(1, double.infinity),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withValues(alpha: 0.04), strokeWidth: 0.8),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 26, interval: 1,
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

                        return SideTitleWidget(meta: meta, child: Text(
                          _displayLabel(label, state.filter),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
                        ));
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
                                radius: 7, // 7px on touch
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
                      getTooltipColor: (_) => const Color(0xF0222228),
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
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w400),
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
    return Wrap(spacing: 16, runSpacing: 6, children: List.generate(top3.length, (i) => Row(
      mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(
          color: _lineColors[i], shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _lineColors[i].withValues(alpha: 0.4), blurRadius: 4)],
        )),
        const SizedBox(width: 6),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 100), child: Text(
          top3[i].song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5),
        )),
      ],
    )));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TOP 10 RANKING
  // ═══════════════════════════════════════════════════════════════════
  Widget _rankHeader() => SliverToBoxAdapter(child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Text('Bảng Xếp Hạng', style: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
  ));

  Widget _rankList(ChartLoaded state) {
    if (state.topSongs.isEmpty) return SliverToBoxAdapter(child: Padding(
      padding: const EdgeInsets.all(32), child: Center(child: Text(
        'Không có dữ liệu', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))))));

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final item = state.topSongs[i];
          return Column(children: [
            _rankItem(ctx, i, item, state.topSongs),
            if (i < state.topSongs.length - 1)
              Divider(color: _kDivider, height: 1, thickness: 0.5, indent: 56, endIndent: 8),
          ]);
        },
        childCount: state.topSongs.length,
      )),
    );
  }

  Widget _rankItem(BuildContext ctx, int idx, ChartTopSong item, List<ChartTopSong> all) {
    // Rank style
    Color rc; double rs;
    if (idx == 0)      { rc = const Color(0xFFFFD700); rs = 26; }
    else if (idx == 1) { rc = const Color(0xFFC0C0C0); rs = 24; }
    else if (idx == 2) { rc = const Color(0xFFCD7F32); rs = 22; }
    else               { rc = Colors.white.withValues(alpha: 0.35); rs = 18; }

    // Trend
    IconData ti; Color tc;
    if (item.trend == ChartTrend.up)        { ti = Icons.arrow_drop_up_rounded; tc = const Color(0xFF4CAF50); }
    else if (item.trend == ChartTrend.down) { ti = Icons.arrow_drop_down_rounded; tc = const Color(0xFFE53935); }
    else                                    { ti = Icons.remove_rounded; tc = Colors.white.withValues(alpha: 0.2); }

    // Thumb border
    final border = idx < 3
        ? [_lineColors[idx], _lineColors[idx].withValues(alpha: 0.3)]
        : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)];

    return InkWell(
      onTap: () => _play(ctx, idx, all),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          // Rank + trend
          SizedBox(width: 36, child: Column(children: [
            Text('${idx + 1}', style: TextStyle(fontSize: rs, fontWeight: FontWeight.w900, color: rc, height: 1,
              shadows: idx < 3 ? [Shadow(color: rc.withValues(alpha: 0.4), blurRadius: 6)] : null)),
            Icon(ti, color: tc, size: 18),
          ])),
          const SizedBox(width: 12),
          // Thumb
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: border, begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: ClipOval(child: SizedBox(width: 48, height: 48, child: CachedNetworkImage(
              imageUrl: item.song.artUrl ?? '', fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: _kCard),
              errorWidget: (_, __, ___) => Container(color: _kCard,
                child: Icon(Icons.music_note_rounded, color: Colors.white.withValues(alpha: 0.2), size: 24)),
            ))),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
            const SizedBox(height: 3),
            Text(item.song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
          ])),
          const SizedBox(width: 8),
          // Count
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_compact(item.playCount), style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 2),
            Icon(Icons.headset_rounded, size: 13, color: Colors.white.withValues(alpha: 0.25)),
          ]),
        ]),
      ),
    );
  }
}
