import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/login_page.dart';
import '../../auth/register_page.dart';
import '../../profile/comment_history_page.dart';
import '../../profile/notifications_page.dart';
import '../../profile/edit_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../presentation/bloc/admin/admin_cubit.dart';
import '../../../presentation/bloc/admin/admin_state.dart';
import '../../admin/admin_dashboard_page.dart';
import '../../../presentation/bloc/player/player_bloc.dart';
import '../../../presentation/bloc/player/player_event.dart';
import '../../../presentation/bloc/user_songs/user_songs_cubit.dart';
import '../../../data/models/user_song_model.dart';
import '../../upload/upload_music_sheet.dart';

class ProfileTab extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final String userEmail;
  final String? userId; // Thêm biến lưu userId
  final String? userAvatarUrl; // Thêm biến lưu avatar
  final Future<void> Function() onLogout;
  final int favoriteCount;
  final int playlistCount;
  final int downloadCount;

  const ProfileTab({
    super.key,
    required this.isLoggedIn,
    required this.userName,
    required this.userEmail,
    this.userId,
    this.userAvatarUrl,
    required this.onLogout,
    this.favoriteCount = 0,
    this.playlistCount = 0,
    this.downloadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return isLoggedIn
        ? _LoggedInProfile(
            userName: userName,
            userEmail: userEmail,
            userId: userId,
            userAvatarUrl: userAvatarUrl,
            onLogout: onLogout,
            favoriteCount: favoriteCount,
            playlistCount: playlistCount,
            downloadCount: downloadCount,
          )
        : const _GuestProfile();
  }
}

// ── Guest ─────────────────────────────────────────────────────────────────────

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 120),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCard,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 2),
                    ),
                    child: Icon(Icons.person_rounded,
                        size: 52, color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Bạn chưa đăng nhập',
                      style:
                          TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text('Đăng nhập để lưu playlist,\ntheo dõi nghệ sĩ và nhiều hơn nữa',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kSubText, fontSize: 14, height: 1.6)),
                  const SizedBox(height: 36),
                  _AuthButton(
                    label: 'Đăng nhập',
                    isPrimary: true,
                    onTap: () => Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (_, anim, __) => const LoginPage(),
                      transitionsBuilder: (_, anim, __, child) => SlideTransition(
                        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    )),
                  ),
                  const SizedBox(height: 14),
                  _AuthButton(
                    label: 'Tạo tài khoản mới',
                    isPrimary: false,
                    onTap: () => Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (_, anim, __) => const RegisterPage(),
                      transitionsBuilder: (_, anim, __, child) => SlideTransition(
                        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    )),
                  ),
                  const SizedBox(height: 44),
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 24),
                  const Text('Khi đăng nhập bạn sẽ có',
                      style: TextStyle(color: kSubText, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  ..._kFeatures.map((f) => _FeatureRow(icon: f.$1, label: f.$2, sub: f.$3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _kFeatures = [
  (Icons.favorite_rounded, 'Yêu thích bài hát', 'Lưu những bài hát bạn thích'),
  (Icons.queue_music_rounded, 'Tạo playlist', 'Sắp xếp nhạc theo ý muốn'),
  (Icons.download_rounded, 'Tải nhạc offline', 'Nghe không cần mạng'),
  (Icons.history_rounded, 'Lịch sử nghe', 'Xem lại những gì đã nghe'),
];

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _FeatureRow({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [
                kAccent.withValues(alpha: 0.25),
                kAccentPink.withValues(alpha: 0.25),
              ]),
            ),
            child: Icon(icon, color: kAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(color: kSubText, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Logged In ─────────────────────────────────────────────────────────────────

class _LoggedInProfile extends StatelessWidget {
  final String userName, userEmail;
  final String? userId; // Nhận userId
  final String? userAvatarUrl; // Nhận avatar
  final Future<void> Function() onLogout;
  final int favoriteCount;
  final int playlistCount;
  final int downloadCount;

  const _LoggedInProfile({
    required this.userName,
    required this.userEmail,
    this.userId,
    this.userAvatarUrl,
    required this.onLogout,
    required this.favoriteCount,
    required this.playlistCount,
    required this.downloadCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
              children: [
                _ProfileHeader(
                  userName: userName,
                  userEmail: userEmail,
                  userAvatarUrl: userAvatarUrl,
                  favoriteCount: favoriteCount,
                  playlistCount: playlistCount,
                  downloadCount: downloadCount,
                ),
                const SizedBox(height: 8),
                ..._kMenuItems.map((item) => _MenuItem(
                      icon: item.$1,
                      label: item.$2,
                      onTap: () async {
                        if (item.$2 == 'Chỉnh sửa hồ sơ' && userId != null) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(
                                currentName: userName,
                                currentAvatarUrl: userAvatarUrl,
                              ),
                            ),
                          );
                          // HomePage sẽ tự động lắng nghe AuthState nếu user update profile
                        } else if (item.$2 == 'Lịch sử bình luận' && userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommentHistoryPage(userId: userId!),
                            ),
                          );
                        } else if (item.$2 == 'Thông báo' && userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                        }
                      },
                    )),
                const SizedBox(height: 8),

                // ── Nhạc của tôi ─────────────────────────────────────
                _MyMusicSection(userId: userId),
                const SizedBox(height: 8),

                // ── Admin Panel button (only for admin/moderator) ───
                _AdminSection(),
                const SizedBox(height: 8),

                _LogoutButton(onLogout: onLogout),
              ],
            ),
          ),
          ),
          ),

          // ── FAB Upload ─────────────────────────────────────────────
          Positioned(
            bottom: 24,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () => showUploadMusicSheet(context),
              backgroundColor: kAccent,
              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
              label: const Text('Upload nhạc',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String userName, userEmail;
  final String? userAvatarUrl;
  final int favoriteCount;
  final int playlistCount;
  final int downloadCount;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
    required this.favoriteCount,
    required this.playlistCount,
    required this.downloadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kAccent, kAccentPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                )
              ],
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: userAvatarUrl!,
                    fit: BoxFit.cover,
                    width: 90,
                    height: 90,
                    placeholder: (context, url) => const CircularProgressIndicator(color: kAccent),
                    errorWidget: (context, url, error) => Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                    ),
                  )
                : Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                  ),
          ),
          const SizedBox(height: 16),
          Text(userName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(userEmail, style: const TextStyle(color: kSubText, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(label: 'Đã tải', value: downloadCount.toString()),
              _divider,
              _StatChip(label: 'Playlist', value: playlistCount.toString()),
              _divider,
              _StatChip(label: 'Yêu thích', value: favoriteCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget get _divider => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.1),
        margin: const EdgeInsets.symmetric(horizontal: 20),
      );
}

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kSubText, fontSize: 11)),
        ],
      );
}

const _kMenuItems = [
  (Icons.manage_accounts_outlined, 'Chỉnh sửa hồ sơ'),
  (Icons.history_rounded, 'Lịch sử nghe'),
  (Icons.comment_rounded, 'Lịch sử bình luận'),
  (Icons.notifications_outlined, 'Thông báo'),
  (Icons.settings_outlined, 'Cài đặt'),
  (Icons.help_outline_rounded, 'Trợ giúp & Phản hồi'),
];

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: kAccent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.25), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final Future<void> Function() onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF2A2A2E),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                content: const Text('Bạn có chắc muốn đăng xuất?', style: TextStyle(color: Colors.white)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await onLogout();
            }
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.red.withValues(alpha: 0.08),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                SizedBox(width: 16),
                Text('Đăng xuất',
                    style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Auth Button ───────────────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _AuthButton({required this.label, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: isPrimary
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kAccent, kAccentPink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kAccent.withValues(alpha: 0.5), width: 1.5),
                color: kAccent.withValues(alpha: 0.07),
              ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              color: isPrimary ? Colors.white : kAccent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            )),
      ),
    );
  }
}

// ── My Music Section ──────────────────────────────────────────────────────────

class _MyMusicSection extends StatefulWidget {
  final String? userId;
  const _MyMusicSection({this.userId});

  @override
  State<_MyMusicSection> createState() => _MyMusicSectionState();
}

class _MyMusicSectionState extends State<_MyMusicSection> {
  @override
  void initState() {
    super.initState();
    // Load ngay khi widget hiển thị
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userId != null) {
        context.read<UserSongsCubit>().loadMySongs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) return const SizedBox.shrink();

    return BlocBuilder<UserSongsCubit, List<UserSongModel>>(
      builder: (context, songs) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kAccent, kAccentPink]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nhạc của tôi',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('${songs.length} bài đã upload',
                            style: const TextStyle(color: kSubText, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: kSubText, size: 20),
                      onPressed: () => context.read<UserSongsCubit>().loadMySongs(),
                    ),
                  ],
                ),
              ),

              if (songs.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_off_rounded, color: Colors.white.withValues(alpha: 0.2), size: 20),
                      const SizedBox(width: 8),
                      Text('Bạn chưa upload bài nào',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
                    ],
                  ),
                )
              else
                ...songs.map((song) => _UserSongTile(song: song)),
            ],
          ),
        );
      },
    );
  }
}

class _UserSongTile extends StatelessWidget {
  final UserSongModel song;
  const _UserSongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song.artUrl != null
              ? Image.network(song.artUrl!, width: 48, height: 48, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        title: Text(song.title,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(song.artist,
              style: const TextStyle(color: kSubText, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(width: 6),
            _StatusBadge(status: song.status),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Phát nhạc (chỉ khi approved)
            if (song.isApproved)
              IconButton(
                icon: const Icon(Icons.play_circle_rounded, color: kAccent, size: 28),
                onPressed: () => _playUserSong(context, song),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              ),
            // Menu 3 chấm
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
              color: const Color(0xFF252530),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Xóa bài', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ]),
                ),
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF252530),
                      title: const Text('Xóa bài hát', style: TextStyle(color: Colors.white)),
                      content: Text('Xóa "${song.title}" khỏi danh sách của bạn?',
                        style: const TextStyle(color: kSubText)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy', style: TextStyle(color: kSubText))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Xóa', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    try {
                      await context.read<UserSongsCubit>().deleteSong(song);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã xóa "${song.title}"'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Xóa thất bại, thử lại sau'),
                            backgroundColor: Colors.orange),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [kAccent, kAccentPink]),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
  );

  void _playUserSong(BuildContext context, UserSongModel song) {
    final item = song.toMediaItem();
    context.read<PlayerBloc>().add(LoadPlaylistEvent(
      [item],
      startIndex: 0,
    ));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('✓ Đã duyệt', Colors.greenAccent),
      'rejected' => ('✗ Từ chối', Colors.redAccent),
      _ => ('⏳ Chờ duyệt', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Admin Section Widget ───────────────────────────────────
class _AdminSection extends StatelessWidget {
  const _AdminSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final supabase = Supabase.instance.client;
        final uid = supabase.auth.currentUser?.id;
        if (uid == null) return const SizedBox.shrink();

        // Load role from profiles if not yet loaded
        return FutureBuilder<String>(
          future: _getRole(uid),
          builder: (context, snap) {
            final role = snap.data ?? '';
            if (role != 'admin' && role != 'moderator') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AdminCubit>(),
                      child: const AdminDashboardPage(),
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kAccent.withValues(alpha: 0.15),
                        kAccentPink.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kAccent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kAccent, kAccentPink],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trang quản trị',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              role == 'admin' ? 'Admin • Toàn quyền' : 'Moderator • Kiểm duyệt nội dung',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            color: kAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white38, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getRole(String uid) async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      return res['role'] as String? ?? 'user';
    } catch (_) {
      return 'user';
    }
  }
}
