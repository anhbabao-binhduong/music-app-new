import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local_music_data.dart';
import '../../presentation/bloc/player/player_bloc.dart';
import '../../presentation/bloc/player/player_event.dart';
import '../../widgets/mini_player_bar.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../player/player_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────

const _kBg      = Color(0xFF121212);
const _kCard    = Color(0xFF1C1C1E);
const _kAccent  = Colors.deepPurpleAccent;
const _kSubText = Color(0xFF9E9E9E);

// ─────────────────────────────────────────────────────────────────────────────
// HomePage
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  // ── Firebase Auth state ────────────────────────────────────────────────────
  User? _firebaseUser;
  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    // Lắng nghe thay đổi trạng thái đăng nhập realtime
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) setState(() => _firebaseUser = user);
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // Helpers đọc từ Firebase User
  bool get _isLoggedIn => _firebaseUser != null;
  String get _userName  => _firebaseUser?.displayName ?? '';
  String get _userEmail => _firebaseUser?.email ?? '';

  Future<void> _onLogout() async {
    await FirebaseAuth.instance.signOut();
    // _authSub tự cập nhật _firebaseUser = null → rebuild tự động
  }

  // ── Body builder ───────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _ExploreTab(isLoggedIn: _isLoggedIn);
      case 1:
        return const _PlaceholderTab(
            icon: Icons.radio_rounded, label: 'Radio');
      case 2:
        return const _PlaceholderTab(
            icon: Icons.library_music_rounded, label: 'Thư viện');
      case 3:
        return _ProfileTab(
          isLoggedIn: _isLoggedIn,
          userName: _userName,
          userEmail: _userEmail,
          onLogout: _onLogout,
        );
      default:
        return _ExploreTab(isLoggedIn: _isLoggedIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      extendBody: true,
      appBar: _currentNavIndex == 3 ? null : _buildAppBar(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_currentNavIndex),
          child: _buildBody(),
        ),
      ),
      bottomSheet: const MiniPlayerBar(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: const Text(
        'Khám phá',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 3),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _kAccent.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: _isLoggedIn
                  ? ClipOval(
                      child: Container(
                        color: const Color(0xFF4A148C),
                        alignment: Alignment.center,
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  : const Icon(Icons.person_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation Bar ───────────────────────────────────────────────────

  Widget _buildBottomNavBar() {
    const items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore_rounded),
        label: 'Khám phá',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.radio_outlined),
        activeIcon: Icon(Icons.radio_rounded),
        label: 'Radio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.library_music_outlined),
        activeIcon: Icon(Icons.library_music_rounded),
        label: 'Thư viện',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Cá nhân',
      ),
    ];

    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) => setState(() => _currentNavIndex = i),
      backgroundColor: const Color(0xFF1A1A1A),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _kAccent,
      unselectedItemColor: _kSubText,
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: items,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileTab  –  không cần onLoginSuccess nữa, Firebase tự xử lý
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final String userEmail;
  final Future<void> Function() onLogout;

  const _ProfileTab({
    required this.isLoggedIn,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return isLoggedIn
        ? _LoggedInProfile(
            userName: userName,
            userEmail: userEmail,
            onLogout: onLogout,
          )
        : const _GuestProfile();
  }
}

// ── Chưa đăng nhập ───────────────────────────────────────────────────────────

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 120),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCard,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 2),
              ),
              child: Icon(Icons.person_rounded,
                  size: 52, color: Colors.white.withValues(alpha: 0.25)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa đăng nhập',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Đăng nhập để lưu playlist,\ntheo dõi nghệ sĩ và nhiều hơn nữa',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSubText, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 36),

            _AuthNavButton(
              label: 'Đăng nhập',
              isPrimary: true,
              onTap: () => Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, anim, __) => const LoginPage(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween(
                          begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              )),
            ),
            const SizedBox(height: 14),

            _AuthNavButton(
              label: 'Tạo tài khoản mới',
              isPrimary: false,
              onTap: () => Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, anim, __) => const RegisterPage(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween(
                          begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              )),
            ),
            const SizedBox(height: 44),

            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 24),

            const Text(
              'Khi đăng nhập bạn sẽ có',
              style: TextStyle(
                  color: _kSubText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            ..._kGuestFeatures
                .map((f) => _FeatureRow(icon: f.$1, label: f.$2, sub: f.$3)),
          ],
        ),
      ),
    );
  }
}

const _kGuestFeatures = [
  (Icons.favorite_rounded, 'Yêu thích bài hát', 'Lưu những bài hát bạn thích'),
  (Icons.queue_music_rounded, 'Tạo playlist', 'Sắp xếp nhạc theo ý muốn'),
  (Icons.download_rounded, 'Tải nhạc offline', 'Nghe không cần mạng'),
  (Icons.history_rounded, 'Lịch sử nghe', 'Xem lại những gì đã nghe'),
];

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  const _FeatureRow(
      {required this.icon, required this.label, required this.sub});

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
                const Color(0xFF7B1FA2).withValues(alpha: 0.25),
                const Color(0xFF1565C0).withValues(alpha: 0.25),
              ]),
            ),
            child: Icon(icon, color: _kAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(sub,
                  style: const TextStyle(color: _kSubText, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Đã đăng nhập ─────────────────────────────────────────────────────────────

class _LoggedInProfile extends StatelessWidget {
  final String userName;
  final String userEmail;
  final Future<void> Function() onLogout;

  const _LoggedInProfile({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A0845), Color(0xFF121212)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B1FA2).withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(userEmail,
                      style: const TextStyle(color: _kSubText, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(label: 'Theo dõi', value: '12'),
                      _kDivider,
                      _StatChip(label: 'Playlist', value: '5'),
                      _kDivider,
                      _StatChip(label: 'Yêu thích', value: '84'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            ..._kMenuItems.map(
              (item) => _ProfileMenuItem(
                  icon: item.$1, label: item.$2, onTap: () {}),
            ),
            const SizedBox(height: 8),

            // Đăng xuất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await onLogout();
                    // Firebase authStateChanges tự cập nhật → không cần làm gì thêm
                  },
                  borderRadius: BorderRadius.circular(14),
                  splashColor: Colors.red.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: Colors.redAccent, size: 20),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Đăng xuất',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget get _kDivider => Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );

const _kMenuItems = [
  (Icons.manage_accounts_outlined, 'Chỉnh sửa hồ sơ'),
  (Icons.favorite_outline_rounded, 'Bài hát yêu thích'),
  (Icons.download_outlined, 'Nhạc đã tải'),
  (Icons.history_rounded, 'Lịch sử nghe'),
  (Icons.notifications_outlined, 'Thông báo'),
  (Icons.settings_outlined, 'Cài đặt'),
  (Icons.help_outline_rounded, 'Trợ giúp & Phản hồi'),
];

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _kSubText, fontSize: 11)),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileMenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: _kAccent.withValues(alpha: 0.08),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
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

// ─────────────────────────────────────────────────────────────────────────────
// _AuthNavButton
// ─────────────────────────────────────────────────────────────────────────────

class _AuthNavButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _AuthNavButton(
      {required this.label, required this.isPrimary, required this.onTap});

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
                  colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _kAccent.withValues(alpha: 0.5), width: 1.5),
                color: _kAccent.withValues(alpha: 0.07),
              ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : _kAccent,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlaceholderTab
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tính năng đang phát triển',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BannerData {
  final List<Color> gradient;
  final String label;
  final String sub;
  const _BannerData(
      {required this.gradient, required this.label, required this.sub});
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: data.gradient.first.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08))),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05))),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('NỔI BẬT',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
                const SizedBox(height: 8),
                Text(data.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(data.sub,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreTab extends StatefulWidget {
  final bool isLoggedIn;
  const _ExploreTab({required this.isLoggedIn});

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  int _bannerIndex = 0;
  late final PageController _pageController;
  Timer? _bannerTimer;

  final List<_BannerData> _banners = const [
    _BannerData(
        gradient: [Color(0xFF6A1B9A), Color(0xFF1565C0)],
        label: 'Nhạc Hot Tháng 5',
        sub: 'Cập nhật mỗi ngày'),
    _BannerData(
        gradient: [Color(0xFF00897B), Color(0xFF1B5E20)],
        label: 'V-Pop Trending',
        sub: 'Bảng xếp hạng mới nhất'),
    _BannerData(
        gradient: [Color(0xFFB71C1C), Color(0xFF4A148C)],
        label: 'Top Hits 2024',
        sub: 'Những bài hát đình đám'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPlayer(BuildContext ctx, MediaItem song, int index) {
    ctx.read<PlayerBloc>().add(
          LoadPlaylistEvent(localPlaylist, startIndex: index),
        );
    Navigator.of(ctx).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => PlayerPage(song: song),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildBanner(),
          const SizedBox(height: 32),
          _buildCategory(context, 'Gợi ý cho bạn', _buildHorizontalSongList()),
          const SizedBox(height: 32),
          _buildCategory(context, 'Bảng xếp hạng', _buildChartList()),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (_, i) => _BannerCard(data: _banners[i]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active
                    ? _kAccent
                    : Colors.white.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCategory(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  )),
              _SeeAllButton(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _SeeAllPage(title: title))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  Widget _buildHorizontalSongList() {
    return SizedBox(
      height: 178,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: localPlaylist.length.clamp(0, 10),
        itemBuilder: (ctx, i) => _HorizontalSongCard(
          item: localPlaylist[i],
          onTap: () => _navigateToPlayer(ctx, localPlaylist[i], i),
        ),
      ),
    );
  }

  Widget _buildChartList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: localPlaylist.length.clamp(0, 10),
      separatorBuilder: (_, __) => Divider(
          color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 72),
      itemBuilder: (ctx, i) => _ChartSongTile(
        item: localPlaylist[i],
        rank: i + 1,
        onTap: () => _navigateToPlayer(ctx, localPlaylist[i], i),
      ),
    );
  }
}

class _HorizontalSongCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  const _HorizontalSongCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'art-${item.id}',
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _ArtImage(uri: item.artUri, size: 120)),
            ),
            const SizedBox(height: 8),
            Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(item.artist ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kSubText, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ChartSongTile extends StatelessWidget {
  final MediaItem item;
  final int rank;
  final VoidCallback onTap;
  const _ChartSongTile(
      {required this.item, required this.rank, required this.onTap});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return _kSubText;
  }

  String get _durationText {
    final d = item.duration;
    if (d == null) return '';
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _rankColor,
                        fontSize: rank <= 3 ? 18 : 14,
                        fontWeight: rank <= 3
                            ? FontWeight.w900
                            : FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              Hero(
                tag: 'chart-${item.id}',
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ArtImage(uri: item.artUri, size: 52)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(item.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: _kSubText, fontSize: 13)),
                  ],
                ),
              ),
              if (_durationText.isNotEmpty) ...[
                Text(_durationText,
                    style: const TextStyle(color: _kSubText, fontSize: 12)),
                const SizedBox(width: 8),
              ],
              Icon(Icons.more_vert_rounded,
                  size: 20, color: Colors.white.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtImage extends StatelessWidget {
  final Uri? uri;
  final double size;
  const _ArtImage({required this.uri, required this.size});

  @override
  Widget build(BuildContext context) {
    if (uri != null) {
      return CachedNetworkImage(
          imageUrl: uri.toString(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _ArtPlaceholder(size: size));
    }
    return _ArtPlaceholder(size: size);
  }
}

class _ArtPlaceholder extends StatelessWidget {
  final double size;
  const _ArtPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
            colors: [Color(0xFF2A2A2E), Color(0xFF1C1C1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Icon(Icons.music_note_rounded,
          color: _kAccent.withValues(alpha: 0.7), size: size * 0.42),
    );
  }
}

class _SeeAllButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SeeAllButton({required this.onTap});

  @override
  State<_SeeAllButton> createState() => _SeeAllButtonState();
}

class _SeeAllButtonState extends State<_SeeAllButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.90)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Xem tất cả',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 11),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAllPage extends StatelessWidget {
  final String title;
  const _SeeAllPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 24),
              onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: localPlaylist.length,
        separatorBuilder: (_, __) => Divider(
            color: Colors.white.withValues(alpha: 0.06),
            height: 1,
            indent: 72),
        itemBuilder: (ctx, i) {
          final song = localPlaylist[i];
          return _ChartSongTile(
            item: song,
            rank: i + 1,
            onTap: () {
              ctx.read<PlayerBloc>().add(
                    LoadPlaylistEvent(localPlaylist, startIndex: i),
                  );
              Navigator.of(ctx).push(PageRouteBuilder(
                pageBuilder: (_, anim, __) => PlayerPage(song: song),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween(
                          begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ));
            },
          );
        },
      ),
    );
  }
}