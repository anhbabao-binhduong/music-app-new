import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/pages/admin/admin_theme.dart';
import 'package:music_app/pages/admin/widgets/admin_widgets.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_state.dart';

class UserDetailPage extends StatelessWidget {
  final AdminUserItem user;

  const UserDetailPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kABg,
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const ALoadingPage();
          }

          if (state is AdminError) {
            return AErrorPage(
              message: state.message,
              onRetry: () => context.read<AdminCubit>().loadAll(),
            );
          }

          if (state is! AdminLoaded) {
            return const SizedBox.shrink();
          }

          final userIndex = state.users.indexWhere((u) => u.id == user.id);
          final currentUser = userIndex == -1 ? null : state.users[userIndex];

          if (currentUser == null) {
            return const AEmptyState(
              icon: Icons.person_off_rounded,
              title: 'Không tìm thấy người dùng',
              subtitle: 'Dữ liệu người dùng này không còn khả dụng.',
            );
          }

          final uploadedSongs = state.allUserSongs
              .where((song) => song.userId == currentUser.id)
              .length;
          final commentCount = state.comments
              .where((comment) => comment.userId == currentUser.id)
              .length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _UserDetailAppBar(user: currentUser),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: _HeroProfileCard(
                        user: currentUser,
                        uploadedSongs: uploadedSongs,
                        commentCount: commentCount,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ActionCard(user: currentUser),
                    const SizedBox(height: 16),
                    _InsightsSection(
                      user: currentUser,
                      uploadedSongs: uploadedSongs,
                      commentCount: commentCount,
                    ),
                    if (currentUser.isBanned &&
                        (currentUser.banReason?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 16),
                      _BanReasonCard(reason: currentUser.banReason!.trim()),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserDetailAppBar extends StatelessWidget {
  final AdminUserItem user;

  const _UserDetailAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: kABg,
      pinned: true,
      expandedHeight: 210,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: kAWhite,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF151528),
                    kABg,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -36,
              right: -12,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kAAccentPink.withValues(alpha: 0.24),
                      kAAccent.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: 12,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kAAccent.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 90, 20, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USER DETAIL',
                    style: GoogleFonts.dmSans(
                      color: kAWhite70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.name ?? 'Unnamed user',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.syne(
                      color: kAWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroProfileCard extends StatelessWidget {
  final AdminUserItem user;
  final int uploadedSongs;
  final int commentCount;

  const _HeroProfileCard({
    required this.user,
    required this.uploadedSongs,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kACardDecor(
        bg: kACardAlt,
        border: user.isBanned
            ? kADanger.withValues(alpha: 0.28)
            : kAAccent.withValues(alpha: 0.22),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _ProfileAvatar(user: user, radius: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Unnamed user',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.syne(
                        color: kAWhite,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email ?? 'Không có email',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: kAWhite70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ARoleBadge(role: user.role),
                        _StatusBadge(isBanned: user.isBanned),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.library_music_rounded,
                  label: 'Uploads',
                  value: '$uploadedSongs',
                  color: kAAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.mode_comment_rounded,
                  label: 'Comments',
                  value: '$commentCount',
                  color: kAInfo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final AdminUserItem user;

  const _ActionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kACardDecor(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản trị nhanh',
            style: GoogleFonts.syne(
              color: kAWhite,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thực hiện ban/unban hoặc đổi role trực tiếp trên hồ sơ người dùng.',
            style: GoogleFonts.dmSans(
              color: kAWhite70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _BanToggleButton(user: user)),
              const SizedBox(width: 12),
              Expanded(child: _RoleDropdown(user: user)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  final AdminUserItem user;
  final int uploadedSongs;
  final int commentCount;

  const _InsightsSection({
    required this.user,
    required this.uploadedSongs,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    final joinedAt = _formatDate(user.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin chi tiết',
          style: GoogleFonts.syne(
            color: kAWhite,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.calendar_month_rounded,
          label: 'Ngày tạo tài khoản',
          value: joinedAt,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.security_rounded,
          label: 'Vai trò hiện tại',
          value: _roleLabel(user.role),
          accentColor: _roleColor(user.role),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: user.isBanned
              ? Icons.block_rounded
              : Icons.verified_user_rounded,
          label: 'Trạng thái',
          value: user.isBanned ? 'Banned' : 'Active',
          accentColor: user.isBanned ? kADanger : kASuccess,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.upload_file_rounded,
          label: 'Số bài hát đã upload',
          value: '$uploadedSongs bài',
          accentColor: kAAccent,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.chat_bubble_rounded,
          label: 'Số comment',
          value: '$commentCount comment',
          accentColor: kAInfo,
        ),
      ],
    );
  }
}

class _BanReasonCard extends StatelessWidget {
  final String reason;

  const _BanReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kACardDecor(
        bg: kADanger.withValues(alpha: 0.05),
        border: kADanger.withValues(alpha: 0.25),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kADanger.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.report_gmailerrorred_rounded,
              color: kADanger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lý do ban',
                  style: GoogleFonts.syne(
                    color: kAWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: GoogleFonts.dmSans(
                    color: kAWhite70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final AdminUserItem user;
  final double radius;

  const _ProfileAvatar({
    required this.user,
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    final initials = (user.name?.isNotEmpty == true
            ? user.name![0]
            : user.email?.isNotEmpty == true
                ? user.email![0]
                : '?')
        .toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: kAGradient,
            boxShadow: [
              BoxShadow(
                color: kAAccent.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: kACard,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    initials,
                    style: GoogleFonts.syne(
                      color: kAWhite,
                      fontSize: radius * 0.75,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: user.isBanned ? kADanger : kASuccess,
              shape: BoxShape.circle,
              border: Border.all(color: kABg, width: 2),
            ),
            child: Icon(
              user.isBanned ? Icons.block_rounded : Icons.check_rounded,
              size: 9,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kABgAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kABorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.syne(
              color: kAWhite,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: kAMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BanToggleButton extends StatelessWidget {
  final AdminUserItem user;

  const _BanToggleButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final isBanned = user.isBanned;
    final color = isBanned ? kASuccess : kADanger;
    final icon = isBanned
        ? Icons.check_circle_rounded
        : Icons.block_rounded;
    final label = isBanned ? 'Unban user' : 'Ban user';

    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            if (isBanned) {
              context.read<AdminCubit>().unbanUser(user.id);
            } else {
              _showBanDialog(context, user);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon, size: 18, color: Colors.white),
          label: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showBanDialog(BuildContext context, AdminUserItem user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kACardAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kABorder),
        ),
        title: Text(
          'Ban người dùng?',
          style: GoogleFonts.syne(
            color: kAWhite,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${user.name ?? 'User'} – ${user.email ?? ''}',
              style: GoogleFonts.dmSans(
                color: kAMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.dmSans(
                color: kAWhite,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Lý do ban...',
                hintStyle: GoogleFonts.dmSans(color: kAMuted, fontSize: 13),
                filled: true,
                fillColor: kACard,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kABorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kABorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kADanger),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Huỷ',
              style: GoogleFonts.dmSans(
                color: kAMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = ctrl.text.trim();
              Navigator.pop(context);
              context.read<AdminCubit>().banUser(
                    user.id,
                    reason.isEmpty ? 'Vi phạm quy định' : reason,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kADanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Xác nhận Ban',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final AdminUserItem user;

  const _RoleDropdown({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kABgAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kABorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: user.role,
          dropdownColor: kACardAlt,
          iconEnabledColor: kAAccent,
          style: GoogleFonts.dmSans(
            color: kAWhite,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          items: const [
            DropdownMenuItem(
              value: 'user',
              child: Text('Role: User'),
            ),
            DropdownMenuItem(
              value: 'moderator',
              child: Text('Role: Moderator'),
            ),
            DropdownMenuItem(
              value: 'admin',
              child: Text('Role: Admin'),
            ),
          ],
          onChanged: (value) {
            if (value == null || value == user.role) return;
            context.read<AdminCubit>().changeUserRole(user.id, value);
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? kAAccent;

    return Container(
      decoration: kACardDecor(bg: kACardAlt),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: kAMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: kAWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isBanned;

  const _StatusBadge({required this.isBanned});

  @override
  Widget build(BuildContext context) {
    final color = isBanned ? kADanger : kASuccess;
    final icon = isBanned ? Icons.block_rounded : Icons.check_circle_rounded;
    final label = isBanned ? 'Banned' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Không rõ';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _roleLabel(String role) => switch (role) {
      'admin' => 'Admin',
      'moderator' => 'Moderator',
      _ => 'User',
    };

Color _roleColor(String role) => switch (role) {
      'admin' => kAAccent,
      'moderator' => kAWarning,
      _ => kAMuted,
    };