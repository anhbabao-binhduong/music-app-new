import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import '../../presentation/bloc/search/search_page.dart';
import '../../widgets/mini_player_bar.dart';
import 'tabs/explore_tab.dart';
import 'tabs/profile_tab.dart';
import '../library/library_page.dart';


const kBg      = Color(0xFF121212);
const kCard    = Color(0xFF1C1C1E);
const kAccent  = Colors.deepPurpleAccent;
const kSubText = Color(0xFF9E9E9E);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  User? _firebaseUser;
  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (user) { if (mounted) setState(() => _firebaseUser = user); },
    );
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  bool   get _isLoggedIn => _firebaseUser != null;
  String get _userName   => _firebaseUser?.displayName ?? '';
  String get _userEmail  => _firebaseUser?.email ?? '';

  Future<void> _onLogout() => FirebaseAuth.instance.signOut();

  void _openSearch() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => const SearchPage(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim, child: child,
      ),
    ));
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:  return ExploreTab(isLoggedIn: _isLoggedIn);
      case 1:  return const _PlaceholderTab(icon: Icons.radio_rounded, label: 'Radio');
      
      // SỬA DÒNG NÀY:
      case 2:  return const LibraryPage(); // Thay vì trả về _PlaceholderTab
      
      case 3:  
        final totalFavorites = context.watch<FavoriteCubit>().state.length;
        final totalDownloads = context.watch<DownloadCubit>().state.length;
        return ProfileTab(
          isLoggedIn: _isLoggedIn,
          userName:   _userName,
          userEmail:  _userEmail,
          favoriteCount: totalFavorites,
          followingCount: totalDownloads,
          onLogout:   _onLogout,
        );
      default: return ExploreTab(isLoggedIn: _isLoggedIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      extendBody: true,
      appBar: _currentNavIndex == 3 ? null : _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_currentNavIndex), child: _buildBody()),
      ),
      bottomSheet: const MiniPlayerBar(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Tự động đổi tên theo Tab đang chọn
    String title = 'Khám phá';
    if (_currentNavIndex == 1) title = 'Radio';
    if (_currentNavIndex == 2) title = 'Thư viện';

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title, // Sử dụng biến title ở đây
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 26,
          fontWeight: FontWeight.w800, 
          letterSpacing: -0.5
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
          onPressed: _openSearch, // ← đã kết nối
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 3),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF1976D2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: Border.all(color: kAccent.withValues(alpha: 0.6), width: 1.5),
              ),
              child: _isLoggedIn
                  ? ClipOval(
                      child: Container(
                        color: const Color(0xFF4A148C),
                        alignment: Alignment.center,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800, fontSize: 15),
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
      BottomNavigationBarItem(icon: Icon(Icons.explore_outlined),       activeIcon: Icon(Icons.explore_rounded),       label: 'Khám phá'),
      BottomNavigationBarItem(icon: Icon(Icons.radio_outlined),         activeIcon: Icon(Icons.radio_rounded),         label: 'Radio'),
      BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), activeIcon: Icon(Icons.library_music_rounded), label: 'Thư viện'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded),        label: 'Cá nhân'),
    ];
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) => setState(() => _currentNavIndex = i),
      backgroundColor: const Color(0xFF1A1A1A),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kAccent,
      unselectedItemColor: kSubText,
      selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
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
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3),
              fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tính năng đang phát triển',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 13)),
        ],
      ),
    );
  }
}