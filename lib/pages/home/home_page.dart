import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/bloc/search/search_page.dart';
import '../../widgets/mini_player_bar.dart';
import 'tabs/explore_tab.dart';
import 'tabs/chart_tab.dart';
import 'tabs/profile_tab.dart';
import '../library/library_page.dart';
import 'package:music_app/services/supabase_auth_service.dart';
import 'package:music_app/services/music_player_service.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import '../../presentation/bloc/category/category_cubit.dart';
import 'package:music_app/presentation/bloc/history/history_cubit.dart';

const kBg = Color(0xFF121212);
const kCard = Color(0xFF1C1C1E);
const kAccent = Colors.deepPurpleAccent;
const kSubText = Color(0xFF9E9E9E);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  final _supabase = Supabase.instance.client;

  User? _user;
  StreamSubscription<AuthState>? _authSub;

  void _openSearch() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => const SearchPage(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser;
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final newUser = data.session?.user;
      setState(() => _user = newUser);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  bool get _isLoggedIn => _user != null;
  String get _userName {
    final metadata = _user?.userMetadata;
    return (metadata?['name']?.toString().trim().isNotEmpty ?? false)
        ? metadata!['name'].toString()
        : (_user?.email?.split('@').first ?? '');
  }

  String get _userEmail => _user?.email ?? '';

  Future<void> _onLogout() async {
    final authService = SupabaseAuthService();
    await authService.signOut();
    context.read<PlayerBloc>().add(const ResetPlayerEvent());
    setState(() {});
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return ExploreTab(isLoggedIn: _isLoggedIn);
      case 1:
        return const ChartTab();
      case 2:
        return const LibraryPage();
      case 3:
        final totalFavorites = context.watch<FavoriteCubit>().state.length;
        final totalDownloads = context.watch<DownloadCubit>().state.length;
        return ProfileTab(
          isLoggedIn: _isLoggedIn,
          userName: _userName,
          userEmail: _userEmail,
          userId: _isLoggedIn ? _user?.id : null,
          favoriteCount: totalFavorites,
          followingCount: totalDownloads,
          onLogout: _onLogout,
        );
      default:
        return ExploreTab(isLoggedIn: _isLoggedIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CategoryCubit>(
          create: (context) => getIt<CategoryCubit>(),
        ),
      ],
      child: Scaffold(
        backgroundColor: kBg,
        extendBody: true,
        appBar: (_currentNavIndex == 1 || _currentNavIndex == 3) ? null : _buildAppBar(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_currentNavIndex),
            child: _buildBody(),
          ),
        ),
        bottomSheet: const MiniPlayerBar(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title = 'Khám phá';
    if (_currentNavIndex == 1) title = 'Radio';
    if (_currentNavIndex == 2) title = 'Thư viện';

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
          onPressed: _openSearch,
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
                  color: kAccent.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: _isLoggedIn
                  ? ClipOval(
                      child: Container(
                        color: const Color(0xFF4A148C),
                        alignment: Alignment.center,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  : const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    const items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore_rounded),
        label: 'Khám phá',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart_rounded),
        label: '#zingchart',
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
      selectedItemColor: kAccent,
      unselectedItemColor: kSubText,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: items,
    );
  }
}

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
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tính năng đang phát triển',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}