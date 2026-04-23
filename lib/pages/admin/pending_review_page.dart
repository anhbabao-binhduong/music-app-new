import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:music_app/data/models/user_song_model.dart';
import 'package:music_app/pages/admin/admin_theme.dart';
import 'package:music_app/pages/admin/widgets/admin_widgets.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_state.dart';
import 'package:music_app/services/music_player_service.dart';

// ── Quick reject presets ───────────────────────────────────────────────────
const _kRejectReasons = [
  'Vi phạm bản quyền',
  'Nội dung không phù hợp',
  'Chất lượng âm thanh kém',
  'File bị lỗi / không phát được',
  'Tiêu đề / thông tin sai',
  'Trùng bài đã có',
];

class PendingReviewPage extends StatefulWidget {
  final bool standalone;
  const PendingReviewPage({super.key, this.standalone = true});

  @override
  State<PendingReviewPage> createState() => _PendingReviewPageState();
}

class _PendingReviewPageState extends State<PendingReviewPage> {
  int _filter = 0; // 0=Tất cả 1=Pending 2=Approved 3=Rejected
  String? _playingId; // ID bài đang preview

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
                      itemBuilder: (_, i) => _SongReviewCard(
                        song: songs[i],
                        isPlaying: _playingId == songs[i].id,
                        onPlay: (song) {
                          setState(() => _playingId = song.id);
                          GetIt.I<MusicPlayerService>().playSong(song.toMediaItem());
                        },
                        onStopPlay: () => setState(() => _playingId = null),
                      ),
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

// ── Song review card ──────────────────────────────────────────────────────────
class _SongReviewCard extends StatefulWidget {
  final UserSongModel song;
  final bool isPlaying;
  final void Function(UserSongModel) onPlay;
  final VoidCallback onStopPlay;

  const _SongReviewCard({
    required this.song,
    required this.isPlaying,
    required this.onPlay,
    required this.onStopPlay,
  });

  @override
  State<_SongReviewCard> createState() => _SongReviewCardState();
}

class _SongReviewCardState extends State<_SongReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kACard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isPlaying
              ? kAAccent.withValues(alpha: 0.6)
              : kABorder,
          width: widget.isPlaying ? 1.5 : 1,
        ),
        boxShadow: widget.isPlaying
            ? [BoxShadow(color: kAAccent.withValues(alpha: 0.15), blurRadius: 12)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail + play overlay
                _PreviewThumb(
                  song: song,
                  isPlaying: widget.isPlaying,
                  onPlay: () => widget.onPlay(song),
                  onStop: widget.onStopPlay,
                ),
                const SizedBox(width: 12),
                // Info
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
                          style: const TextStyle(color: kAWhite70, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      // Meta chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                            icon: Icons.access_time_rounded,
                            label: _fmtDuration(song.durationMs),
                          ),
                          if (song.fileSize != null)
                            _MetaChip(
                              icon: Icons.folder_rounded,
                              label: '${(song.fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
                            ),
                          _MetaChip(
                            icon: Icons.calendar_today_rounded,
                            label: _fmtDate(song.createdAt),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge + expand toggle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AStatusBadge(status: song.status),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: kAMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Uploader chip ─────────────────────────────────────────
            const SizedBox(height: 10),
            _UploaderChip(song: song),

            // ── Expanded details ──────────────────────────────────────
            if (_expanded) ...[
              const SizedBox(height: 12),
              _ExpandedDetails(song: song),
            ],

            // ── Reject reason (if rejected) ───────────────────────────
            if (song.isRejected && song.rejectReason != null) ...[
              const SizedBox(height: 12),
              _RejectReasonBanner(reason: song.rejectReason!),
            ],

            // ── Actions ───────────────────────────────────────────────
            if (song.isPending) ...[
              const SizedBox(height: 14),
              _ActionRow(song: song),
            ],

            // ── Playing indicator ─────────────────────────────────────
            if (widget.isPlaying) ...[
              const SizedBox(height: 12),
              _PlayingIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDuration(int ms) {
    if (ms <= 0) return '--:--';
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Preview thumbnail with play overlay ──────────────────────────────────────
class _PreviewThumb extends StatelessWidget {
  final UserSongModel song;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  const _PreviewThumb({
    required this.song,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPlaying ? onStop : onPlay,
      child: Stack(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: song.artUrl != null
                  ? Image.network(
                      song.artUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumb(),
                    )
                  : _thumb(),
            ),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: isPlaying ? 0.55 : 0.35),
              ),
              child: Center(
                child: isPlaying
                    ? _PulsingIcon()
                    : const Icon(Icons.play_circle_rounded,
                        color: Colors.white, size: 28),
              ),
            ),
          ),
          // Playing badge
          if (isPlaying)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: kAAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _thumb() => Container(
        color: const Color(0xFF1E1E3A),
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 28),
        ),
      );
}

// ── Pulsing icon for "now playing" ────────────────────────────────────────────
class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: const Icon(Icons.pause_circle_rounded, color: kAAccent, size: 30),
    );
  }
}

// ── Playing wave indicator ─────────────────────────────────────────────────────
class _PlayingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kAAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kAAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded, color: kAAccent, size: 15),
          const SizedBox(width: 8),
          const Text('Đang phát xem trước — mini player ở phía dưới',
              style: TextStyle(color: kAAccentPink, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => GetIt.I<MusicPlayerService>().pause(),
            child: const Icon(Icons.stop_circle_outlined, color: kAMuted, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Meta chip ───────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: kAMuted),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: kAMuted, fontSize: 11)),
      ],
    );
  }
}

// ── Expanded details section ──────────────────────────────────────────────────
class _ExpandedDetails extends StatelessWidget {
  final UserSongModel song;
  const _ExpandedDetails({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kACardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kABorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết bài hát',
              style: TextStyle(
                  color: kAWhite70, fontSize: 12, fontWeight: FontWeight.w700)),
          const Divider(color: kABorder, height: 16),
          _DetailRow('ID', '${song.id.substring(0, 12)}…'),
          _DetailRow('User ID', '${song.userId.substring(0, 12)}…'),
          if (song.album != null) _DetailRow('Album', song.album!),
          _DetailRow('Audio URL',
              song.audioUrl.length > 40
                  ? '…${song.audioUrl.substring(song.audioUrl.length - 40)}'
                  : song.audioUrl),
          _DetailRow('Status', song.status.toUpperCase()),
          _DetailRow('Ngày upload',
              '${song.createdAt.day}/${song.createdAt.month}/${song.createdAt.year} '
              '${song.createdAt.hour.toString().padLeft(2, '0')}:${song.createdAt.minute.toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: kAMuted, fontSize: 11)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: kAWhite70, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ── Reject reason banner ──────────────────────────────────────────────────────
class _RejectReasonBanner extends StatelessWidget {
  final String reason;
  const _RejectReasonBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Icon(Icons.info_outline_rounded, color: kADanger, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lý do từ chối: $reason',
              style: const TextStyle(
                  color: kADanger, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action row (Approve / Reject) ─────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final UserSongModel song;
  const _ActionRow({required this.song});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRejectSheet(context, song),
            icon: const Icon(Icons.close_rounded, size: 16, color: kAWhite70),
            label: const Text('Từ chối', style: TextStyle(color: kAWhite70)),
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
            onPressed: () => context.read<AdminCubit>().approveSong(song.id),
            icon: const Icon(Icons.check_rounded, size: 16, color: kAWhite),
            label: const Text('Duyệt ngay',
                style: TextStyle(fontWeight: FontWeight.w700, color: kAWhite)),
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
    );
  }

  void _showRejectSheet(BuildContext context, UserSongModel song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RejectSheet(song: song, cubit: context.read<AdminCubit>()),
    );
  }
}

// ── Reject bottom sheet ───────────────────────────────────────────────────────
class _RejectSheet extends StatefulWidget {
  final UserSongModel song;
  final AdminCubit cubit;

  const _RejectSheet({required this.song, required this.cubit});

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _ctrl = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kABg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                        color: kAWhite, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                // Song preview chip
                Row(children: [
                  AThumb(url: widget.song.artUrl, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.song.title,
                            style: const TextStyle(
                                color: kAWhite70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(widget.song.artist,
                            style: const TextStyle(color: kAMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                // Quick reason presets
                const Text('Chọn nhanh:',
                    style: TextStyle(
                        color: kAWhite70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kRejectReasons.map((r) {
                    final selected = _selected == r;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selected = selected ? null : r;
                          _ctrl.text = selected ? '' : r;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? kADanger.withValues(alpha: 0.2)
                              : kACard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? kADanger : kABorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(r,
                            style: TextStyle(
                                color: selected ? kADanger : kAWhite70,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Custom reason field
                const Text('Hoặc nhập chi tiết:',
                    style: TextStyle(
                        color: kAWhite70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  style: const TextStyle(color: kAWhite, fontSize: 14),
                  onChanged: (_) => setState(() => _selected = null),
                  decoration: InputDecoration(
                    hintText: 'Mô tả cụ thể vấn đề của bài hát…',
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
                      onPressed: () => Navigator.pop(context),
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
                        final reason = _ctrl.text.trim();
                        Navigator.pop(context);
                        widget.cubit.rejectSong(
                          widget.song.id,
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
