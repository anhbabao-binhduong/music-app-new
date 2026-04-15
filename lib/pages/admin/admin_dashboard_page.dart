import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/pages/admin/admin_theme.dart';
import 'package:music_app/pages/admin/widgets/admin_widgets.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if (state is AdminLoading || state is AdminInitial) {
          return const ALoadingPage();
        }
        if (state is AdminError) {
          return AErrorPage(
            message: state.message,
            onRetry: () => context.read<AdminCubit>().loadAll(),
          );
        }
        if (state is AdminLoaded) { return _DashBody(state: state); }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DashBody extends StatelessWidget {
  final AdminLoaded state;
  const _DashBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome banner ────────────────────────────────────────
          _WelcomeBanner(state: state),
          const SizedBox(height: 20),

          // ── 4 mini stat cards ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ASectionHeader(title: 'Tổng quan'),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AStatCard(
                    icon: Icons.people_rounded,
                    label: 'Người dùng',
                    value: fmtNum(state.stats.totalUsers),
                    color: kAAccent,
                    width: 122,
                  ),
                  const SizedBox(width: 10),
                  AStatCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Chờ duyệt',
                    value: '${state.stats.pendingSongs}',
                    color: kAWarning,
                    width: 122,
                  ),
                  const SizedBox(width: 10),
                  AStatCard(
                    icon: Icons.headphones_rounded,
                    label: 'Lượt nghe',
                    value: fmtNum(state.stats.totalPlays),
                    color: kAAccentPink,
                    width: 122,
                  ),
                  const SizedBox(width: 10),
                  AStatCard(
                    icon: Icons.music_note_rounded,
                    label: 'Bài duyệt',
                    value: fmtNum(state.stats.approvedSongs),
                    color: kASuccess,
                    width: 122,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Bài chờ duyệt gần đây ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ASectionHeader(
              title: 'Bài chờ duyệt',
              action: state.stats.pendingSongs > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kAWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: kAWarning.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${state.stats.pendingSongs} đang chờ',
                        style: const TextStyle(
                            color: kAWarning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          if (state.pendingSongs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: kACardDecor(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: kASuccess, size: 20),
                    SizedBox(width: 10),
                    Text('Không có bài nào chờ duyệt',
                        style: TextStyle(color: kAWhite70, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...state.pendingSongs.take(5).map((song) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: kACardDecor(),
                    child: Row(
                      children: [
                        AThumb(url: song.artUrl, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                    color: kAWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(song.artist,
                                  style: const TextStyle(
                                      color: kAMuted, fontSize: 11)),
                              Text(timeAgo(song.createdAt),
                                  style: const TextStyle(
                                      color: kAWhite30, fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QuickApproveBtn(songId: song.id),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 24),

          // ── Hoạt động gần đây ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ASectionHeader(title: 'Hoạt động gần đây'),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ActivityTimeline(state: state),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final AdminLoaded state;
  const _WelcomeBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kAAccent.withValues(alpha: 0.25),
            kAAccentPink.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kAAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: kAGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isAdmin ? 'Admin Panel' : 'Moderator Panel',
                  style: const TextStyle(
                      color: kAWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  state.isAdmin
                      ? 'Toàn quyền quản trị hệ thống'
                      : 'Kiểm duyệt nội dung',
                  style: const TextStyle(color: kAWhite70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (state.stats.pendingSongs > 0)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kAWarning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: kAWarning.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  '${state.stats.pendingSongs}',
                  style: const TextStyle(
                      color: kAWarning,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickApproveBtn extends StatelessWidget {
  final String songId;
  const _QuickApproveBtn({required this.songId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AdminCubit>().approveSong(songId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: kASuccess.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kASuccess.withValues(alpha: 0.3)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_rounded, color: kASuccess, size: 14),
          SizedBox(width: 4),
          Text('Duyệt',
              style: TextStyle(
                  color: kASuccess, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  final AdminLoaded state;
  const _ActivityTimeline({required this.state});

  @override
  Widget build(BuildContext context) {
    // Build timeline từ approved/rejected songs + user list
    final lines = <_TimelineItem>[];

    // Recent approved songs from full list
    final approvedRecent = state.users
        .where((u) =>
            u.createdAt != null &&
            DateTime.now().difference(u.createdAt!).inDays < 7)
        .take(3)
        .map((u) => _TimelineItem(
              color: kAAccent,
              icon: Icons.person_add_rounded,
              text: '${u.name ?? u.email ?? 'User mới'} đã đăng ký',
              time: u.createdAt!,
            ))
        .toList();
    lines.addAll(approvedRecent);

    // Pending songs as "mới upload"
    final recentPending = state.pendingSongs
        .where((s) => DateTime.now().difference(s.createdAt).inDays < 3)
        .take(3)
        .map((s) => _TimelineItem(
              color: kAWarning,
              icon: Icons.upload_rounded,
              text: '"${s.title}" chờ duyệt',
              time: s.createdAt,
            ))
        .toList();
    lines.addAll(recentPending);

    lines.sort((a, b) => b.time.compareTo(a.time));

    if (lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: kACardDecor(),
        child: const Center(
          child: Text('Chưa có hoạt động gần đây',
              style: TextStyle(color: kAMuted, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: kACardDecor(),
      child: Column(
        children: List.generate(lines.length, (i) {
          final item = lines[i];
          final isLast = i == lines.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 0, 0),
                child: Column(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: item.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(item.icon, color: item.color, size: 13),
                  ),
                  if (!isLast)
                    Container(
                      width: 1,
                      height: 28,
                      color: kABorder,
                    ),
                ]),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      12, 16, 14, isLast ? 16 : 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.text,
                            style: const TextStyle(
                                color: kAWhite70, fontSize: 12)),
                      ),
                      Text(timeAgo(item.time),
                          style: const TextStyle(
                              color: kAWhite30, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TimelineItem {
  final Color color;
  final IconData icon;
  final String text;
  final DateTime time;
  _TimelineItem({
    required this.color,
    required this.icon,
    required this.text,
    required this.time,
  });
}
