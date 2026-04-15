import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/pages/admin/admin_theme.dart';
import 'package:music_app/pages/admin/widgets/admin_widgets.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_state.dart';

class ReportsPage extends StatelessWidget {
  final bool standalone;
  const ReportsPage({super.key, this.standalone = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kABg,
      appBar: standalone
          ? AppBar(
              backgroundColor: kABg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: kAWhite, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Thống kê',
                  style: TextStyle(
                      color: kAWhite, fontWeight: FontWeight.w800, fontSize: 17)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: kAWhite70, size: 20),
                  onPressed: () => context.read<AdminCubit>().loadAll(),
                ),
              ],
            )
          : null,
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) { return const ALoadingPage(); }
          if (state is AdminError) {
            return AErrorPage(
              message: state.message,
              onRetry: () => context.read<AdminCubit>().loadAll(),
            );
          }
          if (state is AdminLoaded) { return _ReportsBody(state: state); }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final AdminLoaded state;
  const _ReportsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 4 stat cards 2×2 ─────────────────────────────────────
          const ASectionHeader(title: 'Tổng quan'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: AStatCard(
                icon: Icons.people_rounded,
                label: 'Người dùng',
                value: fmtNum(state.stats.totalUsers),
                color: kAAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AStatCard(
                icon: Icons.music_note_rounded,
                label: 'Bài hệ thống',
                value: fmtNum(state.stats.totalSongs),
                color: kAInfo,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: AStatCard(
                icon: Icons.headphones_rounded,
                label: 'Lượt nghe',
                value: fmtNum(state.stats.totalPlays),
                color: kAAccentPink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AStatCard(
                icon: Icons.comment_rounded,
                label: 'Bình luận',
                value: fmtNum(state.stats.totalComments),
                color: kASuccess,
              ),
            ),
          ]),
          const SizedBox(height: 28),

          // ── Donut chart: song status ──────────────────────────────
          const ASectionHeader(title: 'Trạng thái bài hát'),
          const SizedBox(height: 14),
          _SongStatusChart(stats: state.stats),
          const SizedBox(height: 28),

          // ── Moderation bar chart ──────────────────────────────────
          const ASectionHeader(title: 'Kiểm duyệt theo ngày (tuần này)'),
          const SizedBox(height: 14),
          _ModerationBarChart(),
          const SizedBox(height: 28),

          // ── Summary table ─────────────────────────────────────────
          const ASectionHeader(title: 'Tóm tắt kiểm duyệt'),
          const SizedBox(height: 12),
          _ModerationSummary(stats: state.stats),
        ],
      ),
    );
  }
}

// ── Donut chart ───────────────────────────────────────────────────────────────
class _SongStatusChart extends StatefulWidget {
  final AdminStats stats;
  const _SongStatusChart({required this.stats});

  @override
  State<_SongStatusChart> createState() => _SongStatusChartState();
}

class _SongStatusChartState extends State<_SongStatusChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final total =
        s.approvedSongs + s.pendingSongs + s.rejectedSongs;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: kACardDecor(),
        child: const AEmptyState(
          icon: Icons.pie_chart_outline_rounded,
          title: 'Chưa có dữ liệu',
        ),
      );
    }

    final sections = [
      _PieSection(
          value: s.approvedSongs.toDouble(),
          color: kASuccess,
          label: 'Đã duyệt',
          count: s.approvedSongs),
      _PieSection(
          value: s.pendingSongs.toDouble(),
          color: kAWarning,
          label: 'Chờ duyệt',
          count: s.pendingSongs),
      _PieSection(
          value: s.rejectedSongs.toDouble(),
          color: kADanger,
          label: 'Từ chối',
          count: s.rejectedSongs),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kACardDecor(),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                pieTouchData: PieTouchData(
                  touchCallback: (ev, resp) {
                    setState(() {
                      if (!ev.isInterestedForInteractions ||
                          resp == null ||
                          resp.touchedSection == null) {
                        _touched = -1;
                      } else {
                        _touched = resp
                            .touchedSection!.touchedSectionIndex;
                      }
                    });
                  },
                ),
                sections: List.generate(sections.length, (i) {
                  final sec = sections[i];
                  final isTouched = _touched == i;
                  return PieChartSectionData(
                    value: sec.value,
                    color: sec.color,
                    radius: isTouched ? 26 : 20,
                    title: '',
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections.map((s) {
                final pct = total > 0
                    ? (s.value / total * 100).toStringAsFixed(1)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.label,
                              style: const TextStyle(
                                  color: kAWhite70, fontSize: 11)),
                          Text(
                            '${s.count}  ($pct%)',
                            style: TextStyle(
                              color: s.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieSection {
  final double value;
  final Color color;
  final String label;
  final int count;
  const _PieSection({
    required this.value,
    required this.color,
    required this.label,
    required this.count,
  });
}

// ── Bar chart (moderation data) ───────────────────────────────────────────────
class _ModerationBarChart extends StatelessWidget {
  const _ModerationBarChart();

  @override
  Widget build(BuildContext context) {
    // Static demo data (7 days) — replace with real RPC data if available
    final data = [3.0, 7.0, 2.0, 9.0, 4.0, 1.0, 6.0];
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: kACardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bài được duyệt mỗi ngày',
              style: TextStyle(color: kAWhite70, fontSize: 11)),
          const SizedBox(height: 10),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: kABorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        days[v.toInt()],
                        style: const TextStyle(
                            color: kAMuted, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(
                  data.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [kAAccentPink, kAAccent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Moderation summary ────────────────────────────────────────────────────────
class _ModerationSummary extends StatelessWidget {
  final AdminStats stats;
  const _ModerationSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.approvedSongs + stats.pendingSongs + stats.rejectedSongs;

    return Container(
      decoration: kACardDecor(),
      child: Column(
        children: [
          _Row(label: 'Tổng bài upload', value: '$total',
              icon: Icons.upload_rounded, color: kAMuted),
          const Divider(color: kABorder, height: 1),
          _Row(label: 'Đã duyệt', value: '${stats.approvedSongs}',
              icon: Icons.check_circle_rounded, color: kASuccess),
          _Row(label: 'Chờ duyệt', value: '${stats.pendingSongs}',
              icon: Icons.pending_actions_rounded, color: kAWarning),
          _Row(label: 'Từ chối', value: '${stats.rejectedSongs}',
              icon: Icons.cancel_rounded, color: kADanger),
          if (total > 0) ...[
            const Divider(color: kABorder, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        if (stats.approvedSongs > 0)
                          Flexible(
                              flex: stats.approvedSongs,
                              child: Container(height: 8, color: kASuccess)),
                        if (stats.pendingSongs > 0)
                          Flexible(
                              flex: stats.pendingSongs,
                              child: Container(height: 8, color: kAWarning)),
                        if (stats.rejectedSongs > 0)
                          Flexible(
                              flex: stats.rejectedSongs,
                              child: Container(height: 8, color: kADanger)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Leg(color: kASuccess, label: 'Duyệt'),
                      _Leg(color: kAWarning, label: 'Chờ'),
                      _Leg(color: kADanger, label: 'Từ chối'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Row(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: kAWhite70, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _Leg extends StatelessWidget {
  final Color color;
  final String label;
  const _Leg({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(color: kAMuted, fontSize: 11)),
    ]);
  }
}
