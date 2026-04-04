import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/local_music_data.dart';
import '../../../../widgets/auth_guard.dart';
import '../../player/player_page.dart';
import '../home_page.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/chart_tile.dart';
import '../widgets/see_all_page.dart';
import '../widgets/song_cards.dart';

class ExploreTab extends StatefulWidget {
  final bool isLoggedIn;
  const ExploreTab({super.key, required this.isLoggedIn});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  int _bannerIndex = 0;
  late final PageController _pageController;
  Timer? _bannerTimer;

  final List<BannerData> _banners = const [
    BannerData(gradient: [Color(0xFF6A1B9A), Color(0xFF1565C0)], label: 'Nhạc Hot Tháng 5',   sub: 'Cập nhật mỗi ngày'),
    BannerData(gradient: [Color(0xFF00897B), Color(0xFF1B5E20)], label: 'V-Pop Trending',      sub: 'Bảng xếp hạng mới nhất'),
    BannerData(gradient: [Color(0xFFB71C1C), Color(0xFF4A148C)], label: 'Top Hits 2024',       sub: 'Những bài hát đình đám'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPlayer(BuildContext ctx, MediaItem song, int index) {
    playWithAuthGuard(ctx, playlist: localPlaylist, index: index);
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
                  style: const TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              SeeAllButton(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SeeAllPage(title: title))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              BannerCarousel(
                banners: _banners,
                controller: _pageController,
                currentIndex: _bannerIndex,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
              ),
              const SizedBox(height: 32),
              _buildCategory(
                context, 'Gợi ý cho bạn',
                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: localPlaylist.length.clamp(0, 10),
                    itemBuilder: (ctx, i) => HorizontalSongCard(
                      item: localPlaylist[i],
                      onTap: () => _navigateToPlayer(ctx, localPlaylist[i], i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildCategory(
                context, 'Bảng xếp hạng',
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: localPlaylist.length.clamp(0, 10),
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withValues(alpha: 0.06),
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (ctx, i) => ChartTile(
                    item: localPlaylist[i],
                    rank: i + 1,
                    onTap: () => _navigateToPlayer(ctx, localPlaylist[i], i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}