import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../presentation/bloc/search/search_page.dart';
import '../../widgets/mini_player_bar.dart';
import 'tabs/explore_tab.dart';
import 'tabs/chart_tab.dart';
import 'tabs/profile_tab.dart';
import '../library/library_page.dart';
import '../news/news_page.dart';
import 'package:music_app/services/supabase_auth_service.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/presentation/bloc/player/player_state.dart';

import 'package:music_app/core/constants/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  int _exploreRefreshToken = 0;
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
    _syncAvatarIfNeeded();
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final newUser = data.session?.user;
      setState(() => _user = newUser);
    });
  }

  Future<void> _syncAvatarIfNeeded() async {
    final user = _user;
    if (user == null) return;
    try {
      final profile = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (profile is Map<String, dynamic>) {
        final profileAvatarUrl = profile['avatar_url'] as String?;
        final authAvatarUrl = user.userMetadata?['avatar_url'] as String?;

        if (profileAvatarUrl != null && profileAvatarUrl != authAvatarUrl) {
          await _supabase.auth.updateUser(UserAttributes(
            data: {
              ...(user.userMetadata ?? {}),
              'avatar_url': profileAvatarUrl,
            },
          ));
        }
      }
    } catch (_) {}
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

  String? get _userAvatarUrl {
    final metadata = _user?.userMetadata;
    return metadata?['avatar_url']?.toString();
  }

  String get _userEmail => _user?.email ?? '';

  Future<void> _onLogout() async {
    final authService = SupabaseAuthService();
    await authService.signOut();
    if (!mounted) return;
    context.read<PlayerBloc>().add(const ResetPlayerEvent());
    setState(() {});
  }

  void _refreshExploreRecommendations() {
    if (!mounted) return;
    setState(() => _exploreRefreshToken++);
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return ExploreTab(
          isLoggedIn: _isLoggedIn,
          refreshToken: _exploreRefreshToken,
        );
      case 1:
        return ChartTab(userAvatarUrl: _userAvatarUrl);
      case 2:
        return const LibraryPage();
      case 3:
        return const NewsPage();
      case 4:
        final totalFavorites = context.watch<FavoriteCubit>().state.length;
        final totalDownloads = context.watch<DownloadCubit>().state.length;
        return ProfileTab(
          isLoggedIn: _isLoggedIn,
          userName: _userName,
          userEmail: _userEmail,
          userId: _isLoggedIn ? _user?.id : null,
          userAvatarUrl: _userAvatarUrl,
          favoriteCount: totalFavorites,
          downloadCount: totalDownloads,
          onLogout: _onLogout,
          onProfileUpdated: _refreshExploreRecommendations,
        );
      default:
        return ExploreTab(
          isLoggedIn: _isLoggedIn,
          refreshToken: _exploreRefreshToken,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final bgColor = isLight
        ? theme.colorScheme.surface
        : theme.colorScheme.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: (_currentNavIndex == 1 || _currentNavIndex == 3 || _currentNavIndex == 4) ? null : _buildAppBar(),
       body: BlocBuilder<PlayerBloc, PlayerState>(
         builder: (context, state) {
           final hasPlayer = state is PlayerPlaying || state is PlayerPaused;
           final bottomPad = hasPlayer ? 74.0 : 0.0;
           
            return Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: KeyedSubtree(
                key: ValueKey(_currentNavIndex),
                child: _buildBody(),
              ),
            );
         },
       ),
      bottomSheet: const MiniPlayerBar(),
      bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    String title = 'Khám phá';
    if (_currentNavIndex == 1) title = '#zingchart';
    if (_currentNavIndex == 2) title = 'Thư viện';

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          // Purple accent bar before title
          Container(
            width: 3,
            height: 22,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAccent, kAccentPink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
        ],
      ),
      actions: [
        // Search button with subtle background
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isLight
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72)
                : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: isLight ? 0.12 : 0.16),
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.onSurface,
              size: 22,
            ),
            onPressed: _openSearch,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 4),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [kAccent, kAccentPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kAccent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoggedIn
                  ? ClipOval(
                      child: _userAvatarUrl != null && _userAvatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _userAvatarUrl!,
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              placeholder: (context, url) =>
                                  Container(color: kAccent.withValues(alpha: 0.25)),
                              errorWidget: (context, url, error) => Container(
                                color: kAccent.withValues(alpha: 0.25),
                                alignment: Alignment.center,
                                child: Text(
                                  _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: kAccent.withValues(alpha: 0.25),
                              alignment: Alignment.center,
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  height: 1.0,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final activeColor = kAccent;
    final inactiveColor =
        isLight ? const Color(0xFF6B5EA8) : const Color(0xFF8B8AA8);

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
        icon: Icon(Icons.newspaper_outlined),
        activeIcon: Icon(Icons.newspaper_rounded),
        label: 'Tin tức',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Cá nhân',
      ),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isLight
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.92)
                : Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: isLight ? 0.16 : 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentNavIndex,
            onTap: (i) => setState(() => _currentNavIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            selectedLabelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
              height: 1.2,
            ),
            unselectedLabelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
              height: 1.2,
            ),
            items: items,
          ),
        ),
      ),
    );
  }
}