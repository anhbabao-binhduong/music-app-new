import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/pages/admin/admin_theme.dart';
import 'package:music_app/pages/admin/admin_dashboard_page.dart';
import 'package:music_app/pages/admin/pending_review_page.dart';
import 'package:music_app/pages/admin/user_management_page.dart';
import 'package:music_app/pages/admin/reports_page.dart';
import 'package:music_app/pages/auth/login_page.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_state.dart';
import 'package:music_app/services/supabase_auth_service.dart';

/// Top-level admin navigator — completely separate from UserStack.
class AdminStack extends StatefulWidget {
  final String userRole;
  const AdminStack({super.key, required this.userRole});

  @override
  State<AdminStack> createState() => _AdminStackState();
}

class _AdminStackState extends State<AdminStack> {
  int _index = 0;
  bool get _isAdmin => widget.userRole == 'admin';

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAll();
  }

  void _onTap(int i) {
    if (i == 2 && !_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chức năng này chỉ dành cho Admin'),
          backgroundColor: Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _index = i);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kACardAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kABorder),
        ),
        title: const Text('Đăng xuất?',
            style: TextStyle(color: kAWhite, fontWeight: FontWeight.w800)),
        content: const Text('Bạn sẽ thoát khỏi trang quản trị.',
            style: TextStyle(color: kAMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: kAMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kADanger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await SupabaseAuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildPage() => switch (_index) {
        0 => const AdminDashboardPage(),
        1 => const PendingReviewPage(standalone: false),
        2 => const UserManagementPage(standalone: false),
        3 => const ReportsPage(standalone: false),
        _ => const AdminDashboardPage(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kABg,
      appBar: _AdminAppBar(
        tabIndex: _index,
        isAdmin: _isAdmin,
        onRefresh: () => context.read<AdminCubit>().loadAll(),
        onLogout: _logout,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(_index), child: _buildPage()),
      ),
      bottomNavigationBar: _AdminBottomNav(
        current: _index,
        isAdmin: _isAdmin,
        onTap: _onTap,
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────
class _AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int tabIndex;
  final bool isAdmin;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _AdminAppBar({
    required this.tabIndex,
    required this.isAdmin,
    required this.onRefresh,
    required this.onLogout,
  });

  static const _titles = ['Dashboard', 'Duyệt nhạc', 'Người dùng', 'Thống kê'];

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kABg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: kAGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.admin_panel_settings_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(_titles[tabIndex],
            style: const TextStyle(
                color: kAWhite, fontSize: 17, fontWeight: FontWeight.w800)),
      ]),
      actions: [
        // Role badge
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: isAdmin
                ? LinearGradient(colors: [
                    kAAccent.withValues(alpha: 0.25),
                    kAAccentPink.withValues(alpha: 0.15),
                  ])
                : null,
            color: isAdmin ? null : kAWarning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAdmin
                  ? kAAccent.withValues(alpha: 0.4)
                  : kAWarning.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            isAdmin ? 'ADMIN' : 'MOD',
            style: TextStyle(
              color: isAdmin ? kAAccent : kAWarning,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: kAMuted, size: 20),
          onPressed: onRefresh,
          tooltip: 'Làm mới',
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: kAMuted, size: 20),
          onPressed: onLogout,
          tooltip: 'Đăng xuất',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kABorder),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _AdminBottomNav extends StatelessWidget {
  final int current;
  final bool isAdmin;
  final ValueChanged<int> onTap;

  const _AdminBottomNav({
    required this.current,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final pending =
            state is AdminLoaded ? state.stats.pendingSongs : 0;
        return Container(
          decoration: const BoxDecoration(
            color: kABgAlt,
            border: Border(top: BorderSide(color: kABorder)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: current == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.queue_music_outlined,
                    activeIcon: Icons.queue_music_rounded,
                    label: 'Duyệt nhạc',
                    isActive: current == 1,
                    badge: pending,
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: isAdmin ? 'Users' : '🔒 Users',
                    isActive: current == 2,
                    locked: !isAdmin,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics_rounded,
                    label: 'Thống kê',
                    isActive: current == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badge;
  final bool locked;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badge = 0,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? kAWhite30
        : isActive
            ? kAAccent
            : kAMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator line
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 24 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                gradient: isActive ? kAGradient : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 22),
                if (badge > 0 && !locked)
                  Positioned(
                    top: -4,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                          color: kAWarning, shape: BoxShape.circle),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
