import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/data/models/user_song_model.dart';
import 'package:music_app/pages/admin/admin_theme.dart';
import 'package:music_app/pages/admin/widgets/admin_widgets.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_state.dart';

class PendingReviewPage extends StatefulWidget {
  final bool standalone;
  const PendingReviewPage({super.key, this.standalone = true});

  @override
  State<PendingReviewPage> createState() => _PendingReviewPageState();
}

class _PendingReviewPageState extends State<PendingReviewPage> {
  int _filter = 0; // 0=Tất cả 1=Pending 2=Approved 3=Rejected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kABg,
      appBar: widget.standalone
          ? AppBar(
              backgroundColor: kABg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: kAWhite, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Kiểm duyệt nhạc',
                  style: TextStyle(
                      color: kAWhite, fontWeight: FontWeight.w800, fontSize: 17)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: kAWhite70, size: 20),
                  onPressed: () => context.read<AdminCubit>().loadPendingSongs(),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 12),
          // ── Filter tabs ───────────────────────────────────────────
          BlocBuilder<AdminCubit, AdminState>(
            builder: (context, state) {
              int pending = 0, approved = 0, rejected = 0;
              if (state is AdminLoaded) {
                pending = state.pendingSongs.length;
                approved = state.approvedSongs.length;
                rejected = state.rejectedSongs.length;
              }
              return AFilterChips(
                labels: const ['Tất cả', 'Pending', 'Approved', 'Rejected'],
                counts: [null, pending, approved, rejected],
                selected: _filter,
                onChanged: (i) => setState(() => _filter = i),
              );
            },
          ),
          const SizedBox(height: 12),
          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<AdminCubit, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) { return const ALoadingPage(); }
                if (state is AdminError) {
                  return AErrorPage(
                    message: state.message,
                    onRetry: () => context.read<AdminCubit>().loadPendingSongs(),
                  );
                }
                if (state is AdminLoaded) {
                  final songs = switch (_filter) {
                    0 => state.allUserSongs,
                    1 => state.pendingSongs,
                    2 => state.approvedSongs,
                    3 => state.rejectedSongs,
                    _ => state.allUserSongs,
                  };

                  if (songs.isEmpty) {
                    return AEmptyState(
                      icon: _filter == 1
                          ? Icons.check_circle_outline_rounded
                          : Icons.queue_music_rounded,
                      title: switch (_filter) {
                        0 => 'Chưa có bài nào',
                        1 => 'Không có bài chờ duyệt',
                        2 => 'Không có bài đã duyệt',
                        3 => 'Không có bài bị từ chối',
                        _ => 'Không có dữ liệu',
                      },
                      subtitle: _filter == 1 ? 'Tất cả bài đã được xử lý!' : 'Tải lại để xem toàn bộ danh sách',
                    );
                  }

                  return RefreshIndicator(
                    color: kAAccent,
                    backgroundColor: kACard,
                    onRefresh: () => context.read<AdminCubit>().loadPendingSongs(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: songs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SongCard(song: songs[i]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final UserSongModel song;
  const _SongCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kACardDecor(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // ── Top row: thumbnail + info + badge ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AThumb(url: song.artUrl, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          style: const TextStyle(
                              color: kAWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(song.artist,
                          style: const TextStyle(
                              color: kAWhite70, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 11, color: kAMuted),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(song.createdAt),
                          style: const TextStyle(
                              color: kAMuted, fontSize: 11),
                        ),
                        if (song.fileSize != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.folder_rounded,
                              size: 11, color: kAMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${(song.fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
                            style: const TextStyle(
                                color: kAMuted, fontSize: 11),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 6),
                      _UploaderChip(song: song),
                    ],
                  ),
                ),
                AStatusBadge(status: song.status),
              ],
            ),
            // ── Reject reason ──────────────────────────────────────
            if (song.isRejected && song.rejectReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kADanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kADanger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: kADanger, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lý do từ chối: ${song.rejectReason}',
                        style: const TextStyle(
                            color: kADanger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ── Actions ────────────────────────────────────────────
            if (song.isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectSheet(context, song),
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: kAWhite70),
                      label: const Text('Từ chối',
                          style: TextStyle(color: kAWhite70)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kAWhite.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AdminCubit>().approveSong(song.id);
                      },
                      icon: const Icon(Icons.check_rounded,
                          size: 16, color: kAWhite),
                      label: const Text('Duyệt ngay',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: kAWhite)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kASuccess,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showRejectSheet(BuildContext context, UserSongModel song) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kABg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kABorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Lý do từ chối',
                    style: TextStyle(
                        color: kAWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Row(children: [
                  AThumb(url: song.artUrl, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title,
                            style: const TextStyle(
                                color: kAWhite70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(song.artist,
                            style: const TextStyle(
                                color: kAMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 3,
                  style: const TextStyle(color: kAWhite, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nhập lý do (VD: vi phạm bản quyền…)',
                    hintStyle: const TextStyle(color: kAMuted, fontSize: 13),
                    filled: true,
                    fillColor: kACard,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kABorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kABorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kADanger),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kABorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Huỷ',
                          style: TextStyle(color: kAWhite70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final reason = ctrl.text.trim();
                        Navigator.pop(ctx);
                        context.read<AdminCubit>().rejectSong(
                              song.id,
                              reason.isEmpty ? 'Vi phạm nội dung' : reason,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kADanger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Xác nhận từ chối',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

// ── Uploader chip ─────────────────────────────────────────────────────────────
class _UploaderChip extends StatelessWidget {
  final UserSongModel song;
  const _UploaderChip({required this.song});

  @override
  Widget build(BuildContext context) {
    final name = song.uploaderName ?? song.uploaderEmail ?? song.userId.substring(0, 8);
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kACardAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kABorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: kAAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: song.uploaderAvatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      song.uploaderAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color: kAAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  )
                : Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: kAAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.person_outline_rounded, size: 11, color: kAMuted),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              name,
              style: const TextStyle(color: kAWhite70, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (song.uploaderEmail != null && song.uploaderName != null) ...[
            const SizedBox(width: 4),
            Text(
              '· ${song.uploaderEmail}',
              style: const TextStyle(color: kAMuted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
