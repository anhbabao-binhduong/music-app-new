import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/pages/admin/admin_theme.dart';
import 'package:music_app/pages/admin/user_detail_page.dart';
import 'package:music_app/pages/admin/widgets/admin_widgets.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_state.dart';

class UserManagementPage extends StatefulWidget {
  final bool standalone;
  const UserManagementPage({super.key, this.standalone = true});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _search = '';
  int _filter = 0; // 0=Tất cả 1=Admin 2=Moderator 3=Banned

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
              title: const Text('Quản lý người dùng',
                  style: TextStyle(
                      color: kAWhite, fontWeight: FontWeight.w800, fontSize: 17)),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 12),
          // ── Search ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: kAWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc email...',
                hintStyle:
                    const TextStyle(color: kAMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: kAMuted, size: 20),
                filled: true,
                fillColor: kACard,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kABorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kABorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kAAccent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Filter chips ─────────────────────────────────────────────
          BlocBuilder<AdminCubit, AdminState>(
            builder: (context, state) {
              int admin = 0, mod = 0, banned = 0;
              if (state is AdminLoaded) {
                admin = state.users.where((u) => u.role == 'admin').length;
                mod = state.users.where((u) => u.role == 'moderator').length;
                banned = state.users.where((u) => u.isBanned).length;
              }
              return AFilterChips(
                labels: const ['Tất cả', 'Admin', 'Moderator', 'Banned'],
                counts: [null, admin, mod, banned],
                selected: _filter,
                onChanged: (i) => setState(() => _filter = i),
              );
            },
          ),
          const SizedBox(height: 12),
          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<AdminCubit, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) { return const ALoadingPage(); }
                if (state is AdminError) {
                  return AErrorPage(
                    message: state.message,
                    onRetry: () => context.read<AdminCubit>().loadAll(),
                  );
                }
                if (state is AdminLoaded) {
                  var list = state.users;

                  // role filter
                  list = switch (_filter) {
                    1 => list.where((u) => u.role == 'admin').toList(),
                    2 => list.where((u) => u.role == 'moderator').toList(),
                    3 => list.where((u) => u.isBanned).toList(),
                    _ => list,
                  };

                  // search filter
                  if (_search.isNotEmpty) {
                    list = list
                        .where((u) =>
                            (u.name?.toLowerCase().contains(_search) ??
                                false) ||
                            (u.email?.toLowerCase().contains(_search) ??
                                false))
                        .toList();
                  }

                  if (list.isEmpty) {
                    return AEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: _search.isNotEmpty
                          ? 'Không tìm thấy kết quả'
                          : 'Không có người dùng',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UserCard(user: list[i]),
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

class _UserCard extends StatelessWidget {
  final AdminUserItem user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kACardDecor(
        bg: user.isBanned
            ? kADanger.withValues(alpha: 0.04)
            : null,
        border: user.isBanned
            ? kADanger.withValues(alpha: 0.2)
            : null,
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailPage(user: user),
            ),
          );
        },
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        leading: _Avatar(user: user),
        title: Row(children: [
          Expanded(
            child: Text(
              user.name ?? 'Unnamed',
              style: TextStyle(
                color: user.isBanned
                    ? kAMuted
                    : kAWhite,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration:
                    user.isBanned ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(user.email ?? '',
                style: const TextStyle(color: kAMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              ARoleBadge(role: user.role),
              const SizedBox(width: 6),
              if (user.isBanned)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kADanger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: kADanger.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Đã ban',
                      style: TextStyle(
                          color: kADanger,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kASuccess.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: kASuccess.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Hoạt động',
                      style: TextStyle(
                          color: kASuccess,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ],
        ),
        trailing: _UserActionMenu(user: user),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AdminUserItem user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = (user.name?.isNotEmpty == true
            ? user.name![0]
            : user.email?.isNotEmpty == true
                ? user.email![0]
                : '?')
        .toUpperCase();
    return Stack(clipBehavior: Clip.none, children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: kAAccent.withValues(alpha: 0.15),
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Text(initials,
                style: const TextStyle(
                    color: kAAccent, fontWeight: FontWeight.w700, fontSize: 15))
            : null,
      ),
      if (user.isBanned)
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
                color: kADanger, shape: BoxShape.circle),
            child: const Icon(Icons.block_rounded,
                size: 9, color: Colors.white),
          ),
        ),
    ]);
  }
}

class _UserActionMenu extends StatelessWidget {
  final AdminUserItem user;
  const _UserActionMenu({required this.user});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: kAMuted, size: 20),
      color: kACardAlt,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kABorder)),
      onSelected: (value) => _handle(context, value),
      itemBuilder: (_) => [
        if (!user.isBanned)
          const PopupMenuItem(
            value: 'ban',
            child: Row(children: [
              Icon(Icons.block_rounded, color: kADanger, size: 16),
              SizedBox(width: 10),
              Text('Ban', style: TextStyle(color: kADanger)),
            ]),
          )
        else
          const PopupMenuItem(
            value: 'unban',
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: kASuccess, size: 16),
              SizedBox(width: 10),
              Text('Unban', style: TextStyle(color: kASuccess)),
            ]),
          ),
        const PopupMenuDivider(),
        _roleItem('user', Icons.person_rounded, 'User', user.role),
        _roleItem('moderator', Icons.shield_rounded, 'Moderator', user.role),
        _roleItem('admin', Icons.admin_panel_settings_rounded, 'Admin', user.role),
      ],
    );
  }

  PopupMenuItem<String> _roleItem(
      String value, IconData icon, String label, String currentRole) {
    final isActive = value == currentRole;
    return PopupMenuItem(
      value: 'role:$value',
      child: Row(children: [
        Icon(icon,
            color: isActive ? kAAccent : kAMuted, size: 16),
        const SizedBox(width: 10),
        Text('→ $label',
            style: TextStyle(
                color: isActive ? kAAccent : kAWhite70,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
        if (isActive) ...[
          const Spacer(),
          const Icon(Icons.check_rounded, color: kAAccent, size: 14),
        ],
      ]),
    );
  }

  void _handle(BuildContext context, String value) {
    if (value == 'ban') {
      _showBanDialog(context);
    } else if (value == 'unban') {
      context.read<AdminCubit>().unbanUser(user.id);
    } else if (value.startsWith('role:')) {
      final role = value.substring(5);
      if (role != user.role) {
        context.read<AdminCubit>().changeUserRole(user.id, role);
      }
    }
  }

  void _showBanDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kACardAlt,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: kABorder)),
        title: const Text('Ban người dùng?',
            style: TextStyle(
                color: kAWhite, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${user.name ?? 'User'} – ${user.email ?? ''}',
              style: const TextStyle(color: kAMuted, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: kAWhite, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Lý do ban...',
              hintStyle: const TextStyle(color: kAMuted),
              filled: true,
              fillColor: kACard,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kABorder),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ', style: TextStyle(color: kAMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final r = ctrl.text.trim();
              Navigator.pop(context);
              context.read<AdminCubit>().banUser(
                    user.id,
                    r.isEmpty ? 'Vi phạm quy định' : r,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kADanger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận Ban'),
          ),
        ],
      ),
    );
  }
}
