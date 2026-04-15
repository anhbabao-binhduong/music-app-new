import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/local_music_data.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/chart_tile.dart';
import '../widgets/see_all_page.dart';
import '../widgets/song_cards.dart';
import '../../../../presentation/bloc/category/category_cubit.dart';
import '../../../../presentation/bloc/category/category_state.dart';
import '../../../../widgets/category_chip_row.dart';
import '../../../../domain/entities/song_entity.dart';
import '../../../../domain/entities/album_entity.dart';
import '../../../../services/music_player_service.dart';
import '../../../../core/di/service_locator.dart';

import '../widgets/album_card.dart';
import '../../library/album_detail_page.dart';
import '../../../../presentation/bloc/album/album_cubit.dart';
import '../../../../presentation/bloc/album/album_state.dart';
import '../../../../presentation/bloc/user_songs/user_songs_cubit.dart';
import '../../../../data/models/user_song_model.dart';
import '../../../../core/constants/colors.dart';

class ExploreTab extends StatefulWidget {
  final bool isLoggedIn;
  const ExploreTab({super.key, required this.isLoggedIn});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  int _chartPage = 1;
  late Future<List<UserSongModel>> _approvedSongsFuture;

  final BannerData _banner = const BannerData(
    imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80',
    gradient: [Color(0xFF7C3AED), Color(0xFF4F46E5)], 
    label: 'Nhạc Hot Tháng 5',  
    sub: 'Tuyển tập những bài hát sôi động nhất',
  );

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadAll();
    _approvedSongsFuture = context.read<UserSongsCubit>().loadApprovedSongs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _playSongFromMediaItems(List<MediaItem> items, int index) async {
    Future.microtask(() async {
      final musicService = getIt<MusicPlayerService>();

      final validItems = items.where((s) {
        final url = s.extras?['url'] as String?;
        return url != null && url.isNotEmpty;
      }).toList();

      if (validItems.isEmpty) return;

      final targetSong = items[index];
      final newIndex = validItems.indexWhere((s) => s.id == targetSong.id);
      if (newIndex == -1) return;

      final playlist = validItems.map((s) {
        final urlStr = s.extras?['url'] as String?;
        final audioUrl = _normalizeAudioUrl(urlStr);
        return s.copyWith(
          extras: {...?s.extras, 'url': audioUrl},
        );
      }).toList();

      await musicService.handler.updateQueue(playlist);
      await musicService.handler.skipToQueueItem(newIndex);
      await musicService.handler.play();
    });
  }

  String _normalizeAudioUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url.trim();
    const base = 'https://pdbkojvgjrvnzqmerwmz.supabase.co/storage/v1/object/public/songs/';
    return '$base${url.trim()}';
  }

  Future<void> _playSongFromCategory(List<SongEntity> songs, int index) async {
    Future.microtask(() async {
      final musicService = getIt<MusicPlayerService>();

      final validSongs = songs
          .where((s) => s.audioUrl != null && s.audioUrl!.isNotEmpty)
          .toList();

      if (validSongs.isEmpty) return;

      final targetSong = songs[index];
      final newIndex = validSongs.indexWhere((s) => s.id == targetSong.id);
      if (newIndex == -1) return;

      final playlist = validSongs.map((s) {
        final audioUrl = _normalizeAudioUrl(s.audioUrl);
        return MediaItem(
          id:       s.id,
          title:    s.title,
          artist:   s.artist,
          album:    s.album,
          artUri:   s.artUrl != null ? Uri.parse(s.artUrl!) : null,
          duration: Duration(milliseconds: s.durationMs),
          extras:   {'url': audioUrl},
        );
      }).toList();

      await musicService.handler.updateQueue(playlist);
      await musicService.handler.skipToQueueItem(newIndex);
      await musicService.handler.play();
    });
  }

  MediaItem _songEntityToMediaItem(SongEntity s) {
    return MediaItem(
      id:       s.id,
      title:    s.title,
      artist:   s.artist,
      album:    s.album,
      artUri:   s.artUrl != null ? Uri.parse(s.artUrl!) : null,
      duration: Duration(milliseconds: s.durationMs),
      extras:   {'url': _normalizeAudioUrl(s.audioUrl)},
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          SeeAllButton(onTap: onSeeAll),
        ],
      ),
    );
  }

  Widget _buildPaginationRow(int currentPage, int totalPages, Function(int) onPageChanged) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (index) {
            final page = index + 1;
            return _PaginationButton(
              page: page,
              isSelected: page == currentPage,
              onTap: () => onPageChanged(page),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Hero Banner
          SliverToBoxAdapter(
            child: HeroBanner(data: _banner),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Album Section
          SliverToBoxAdapter(
            child: BlocProvider(
              create: (_) => getIt<AlbumCubit>()..loadAlbums(),
              child: BlocBuilder<AlbumCubit, AlbumState>(
                builder: (context, state) {
                  if (state is AlbumLoading) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
                    );
                  }
                  if (state is AlbumLoaded && state.albums.isNotEmpty) {
                    return _buildAlbumSection(context, state.albums);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Suggestions Section
          SliverToBoxAdapter(
            child: _buildSuggestionsSection(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Chart Section
          SliverToBoxAdapter(
            child: _buildChartSection(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Community Songs Section
          SliverToBoxAdapter(
            child: _buildCommunitySection(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Mood Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Khám phá theo tâm trạng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Mood Chips
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

          // Category Content
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoading) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  )),
                );
              }
                  if (state is CategoryLoaded) {
                final songs = state.songs;
                if (songs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Không có bài hát nào',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final song = songs[i];
                        return CompactSongTile(
                          item: _songEntityToMediaItem(song),
                          onTap: () => _playSongFromCategory(songs, i),
                          rank: i + 1,
                        );
                      },
                      childCount: songs.length.clamp(0, 20),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAlbumSection(BuildContext context, List<AlbumEntity> albums) {
    // Chỉ lấy đúng 5 item, ẩn phần còn lại
    final displayAlbums = albums.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Album mới phát hành', () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SeeAllPage(
              title: 'Album mới phát hành',
              type: SeeAllType.albums,
            ),
          ));
        }),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            const hPadding = 16.0;
            const gapCount = 4; // khoảng cách giữa 5 item
            const gap = 12.0;
            final totalWidth = constraints.maxWidth - hPadding * 2;
            final itemWidth = (totalWidth - gap * gapCount) / 5;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(displayAlbums.length, (index) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: AlbumCard(
                          album: displayAlbums[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlbumDetailPage(album: displayAlbums[index]),
                            ),
                          ),
                        ),
                      ),
                      if (index < displayAlbums.length - 1)
                        const SizedBox(width: gap),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionsSection(BuildContext context) {
    // Chỉ lấy đúng 5 item, ẩn phần còn lại
    final displayItems = localPlaylist.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Gợi ý cho bạn', () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SeeAllPage(title: 'Gợi ý cho bạn'),
          ));
        }),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            const hPadding = 16.0;
            const gapCount = 4;
            const gap = 12.0;
            final totalWidth = constraints.maxWidth - hPadding * 2;
            final itemWidth = (totalWidth - gap * gapCount) / 5;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(displayItems.length, (i) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: HorizontalSongCard(
                          width: itemWidth,
                          item: displayItems[i],
                          onTap: () => _playSongFromMediaItems(localPlaylist, i),
                        ),
                      ),
                      if (i < displayItems.length - 1)
                        const SizedBox(width: gap),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunitySection(BuildContext context) {
    return FutureBuilder<List<UserSongModel>>(
      future: _approvedSongsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final approved = snapshot.data!;
        if (approved.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Nhạc từ cộng đồng', () {}),
            const SizedBox(height: 16),
            SizedBox(
              height: 196,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: approved.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) => _CommunitySongCard(
                  song: approved[i],
                  onTap: () {
                    Future.microtask(() async {
                      final playlist = approved.map((s) => MediaItem(
                        id: s.id,
                        title: s.title,
                        artist: s.artist,
                        album: s.album,
                        artUri: s.artUrl != null ? Uri.parse(s.artUrl!) : null,
                        duration: Duration(milliseconds: s.durationMs),
                        extras: {'url': s.audioUrl},
                      )).toList();
                      await getIt<MusicPlayerService>().playPlaylist(
                        playlist,
                        startIndex: i,
                      );
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final totalItems = localPlaylist.length;
    final totalPages = (totalItems / 8).ceil();
    final startIdx = (_chartPage - 1) * 8;
    final pageItems = localPlaylist.skip(startIdx).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bảng xếp hạng', () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SeeAllPage(title: 'Bảng xếp hạng'),
          ));
        }),
        const SizedBox(height: 12),
        ...List.generate(pageItems.length, (i) {
          final isFirst = i == 0;
          return Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 6),
            child: ChartTile(
              item: pageItems[i],
              rank: startIdx + i + 1,
              onTap: () => _playSongFromMediaItems(localPlaylist, startIdx + i),
            ),
          );
        }),
        _buildPaginationRow(_chartPage, totalPages, (page) {
          setState(() => _chartPage = page);
        }),
      ],
    );
  }
}

class _CategoryChipSkeleton extends StatelessWidget {
  const _CategoryChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        width: 100,
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _PaginationButton extends StatefulWidget {
  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PaginationButton> createState() => _PaginationButtonState();
}

class _PaginationButtonState extends State<_PaginationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF7C3AED)
                : (_isHovered ? const Color(0xFF242424) : const Color(0xFF1A1A1A)),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${widget.page}',
            style: TextStyle(
              color: widget.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// -- Community Song Card --------------------------------------------------
class _CommunitySongCard extends StatelessWidget {
  final UserSongModel song;
  final VoidCallback onTap;
  const _CommunitySongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: song.artUrl != null
                        ? Image.network(
                            song.artUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 3),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF1E1E30),
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 36),
        ),
      );
}
