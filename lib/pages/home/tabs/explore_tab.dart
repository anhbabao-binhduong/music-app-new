import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/local_music_data.dart';
import '../../../../widgets/auth_guard.dart';
import '../home_page.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/chart_tile.dart';
import '../widgets/see_all_page.dart';
import '../widgets/song_cards.dart';
import '../../../../presentation/bloc/category/category_cubit.dart';
import '../../../../presentation/bloc/category/category_state.dart';
import '../../../../widgets/category_chip_row.dart';
import '../../../../domain/entities/song_entity.dart';
import '../../../../services/music_player_service.dart';
import '../../../../core/di/service_locator.dart';

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
    BannerData(gradient: [Color(0xFF6A1B9A), Color(0xFF1565C0)], label: 'Nhạc Hot Tháng 5',  sub: 'Cập nhật mỗi ngày'),
    BannerData(gradient: [Color(0xFF00897B), Color(0xFF1B5E20)], label: 'V-Pop Trending',     sub: 'Bảng xếp hạng mới nhất'),
    BannerData(gradient: [Color(0xFFB71C1C), Color(0xFF4A148C)], label: 'Top Hits 2024',      sub: 'Những bài hát đình đám'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadAll();
    _pageController = PageController(viewportFraction: 0.88);
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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

  String _normalizeAudioUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url.trim();
    const base = 'https://pdbkojvgjrvnzqmerwmz.supabase.co/storage/v1/object/public/songs/';
    return '$base${url.trim()}';
  }

  Future<void> _playSongFromCategory(List<SongEntity> songs, int index) async {
    final musicService = getIt<MusicPlayerService>();

    final validSongs = songs
        .where((s) => s.audioUrl != null && s.audioUrl!.isNotEmpty)
        .toList();

    if (validSongs.isEmpty) return;

    final targetSong = songs[index];
    final newIndex = validSongs.indexWhere((s) => s.id == targetSong.id);
    if (newIndex == -1) return;

    // ✅ id = DB id, extras['url'] = audio URL — giống localPlaylist
    final playlist = validSongs.map((s) {
      final audioUrl = _normalizeAudioUrl(s.audioUrl);
      return MediaItem(
        id:       s.id,
        title:    s.title,
        artist:   s.artist,
        album:    s.album,
        artUri:   s.artUrl != null ? Uri.parse(s.artUrl!) : null,
        duration: Duration(milliseconds: s.durationMs),
        extras:   {'url': audioUrl},  // ✅ handler đọc extras['url']
      );
    }).toList();

    await musicService.handler.updateQueue(playlist);
    await musicService.handler.skipToQueueItem(newIndex);
    await musicService.handler.play();
  }

  Widget _buildCategoryHeader(String title, VoidCallback onSeeAll) {
    return Padding(
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
          SeeAllButton(onTap: onSeeAll),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        SliverToBoxAdapter(
          child: BannerCarousel(
            banners: _banners,
            controller: _pageController,
            currentIndex: _bannerIndex,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader('Gợi ý cho bạn', () =>
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SeeAllPage(title: 'Gợi ý cho bạn'),
                )),
              ),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader('Bảng xếp hạng', () =>
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SeeAllPage(title: 'Bảng xếp hạng'),
                )),
              ),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Khám phá theo tâm trạng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                )),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        SliverToBoxAdapter(
          child: Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoaded) {
                  return CategoryChipRow(
                    categories: state.categories,
                    selectedSlug: state.selectedSlug,
                    onTap: (slug) =>
                        context.read<CategoryCubit>().selectCategory(slug),
                  );
                }
                return const _CategoryChipSkeleton();
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
              );
            }
            if (state is CategoryError) {
              return SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(state.message,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center),
                )),
              );
            }
            if (state is CategoryLoaded) {
              if (state.songs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Chưa có bài hát trong danh mục này',
                        style: TextStyle(color: Colors.grey)),
                  )),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _SongTile(
                    song: state.songs[i],
                    onTap: () => _playSongFromCategory(state.songs, i),
                  ),
                  childCount: state.songs.length,
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongEntity song;
  final VoidCallback onTap;
  const _SongTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.artUrl != null
            ? Image.network(song.artUrl!,
                width: 48, height: 48, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon())
            : _placeholderIcon(),
      ),
      title: Text(song.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist,
          style: const TextStyle(color: Colors.white54),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.play_arrow, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _placeholderIcon() => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note, color: Colors.white54),
  );
}

class _CategoryChipSkeleton extends StatelessWidget {
  const _CategoryChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 88,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}