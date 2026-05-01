import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../../../services/recommendation_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../profile/edit_profile_page.dart';
import '../for_you_page.dart';

import '../widgets/album_card.dart';
import '../../library/album_detail_page.dart';
import '../../../../presentation/bloc/album/album_cubit.dart';
import '../../../../presentation/bloc/album/album_state.dart';
import '../../../../presentation/bloc/user_songs/user_songs_cubit.dart';
import '../../../../data/models/user_song_model.dart';

class ExploreTab extends StatefulWidget {
  final bool isLoggedIn;
  final int refreshToken;

  const ExploreTab({
    super.key,
    required this.isLoggedIn,
    this.refreshToken = 0,
  });

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  int _chartPage = 1;
  late Future<List<UserSongModel>> _approvedSongsFuture;
  late Future<RecommendationResult> _recommendationsFuture;
  final _supabase = Supabase.instance.client;
  final _recommendationService = RecommendationService();

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
    _recommendationsFuture = _recommendationService.getRecommendedSongs();
  }

  @override
  void didUpdateWidget(covariant ExploreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.isLoggedIn != widget.isLoggedIn) {
      setState(() {
        _recommendationsFuture = _recommendationService.getRecommendedSongs();
      });
    }
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
      // Tìm index trong validItems: nếu bài được tap không hợp lệ, tìm bài gần nhất
      int newIndex = validItems.indexWhere((s) => s.id == targetSong.id);
      if (newIndex == -1) {
        // Tìm bài hợp lệ tiếp theo sau index
        for (int i = index + 1; i < items.length; i++) {
          final next = validItems.indexWhere((s) => s.id == items[i].id);
          if (next != -1) { newIndex = next; break; }
        }
        // Nếu không tìm thấy phía sau, lấy bài đầu tiên hợp lệ
        if (newIndex == -1) newIndex = 0;
      }

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
      // Tìm index trong validSongs: nếu bài được tap không hợp lệ, tìm bài gần nhất
      int newIndex = validSongs.indexWhere((s) => s.id == targetSong.id);
      if (newIndex == -1) {
        for (int i = index + 1; i < songs.length; i++) {
          final next = validSongs.indexWhere((s) => s.id == songs[i].id);
          if (next != -1) { newIndex = next; break; }
        }
        if (newIndex == -1) newIndex = 0;
      }

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

  Future<void> _openProfileSettingsPrompt() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profileData = {
      'name': user.userMetadata?['name'],
      'avatar_url': user.userMetadata?['avatar_url'],
      'bio': user.userMetadata?['bio'],
      'location': user.userMetadata?['location'],
      'website': user.userMetadata?['website'],
    };

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(profileData: profileData),
      ),
    );

    if (mounted) {
      setState(() {
        _recommendationsFuture = _recommendationService.getRecommendedSongs();
      });
    }
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.4,
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

          // Personalized Recommendations Section
          SliverToBoxAdapter(
            child: _buildForYouSection(context),
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
                      child: Center(child: _SectionLoader()),
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
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                       child: Text(
                         'Khám phá theo tâm trạng',
                         style: GoogleFonts.plusJakartaSans(
                           color: Theme.of(context).colorScheme.onSurface,
                           fontSize: 22,
                           fontWeight: FontWeight.w800,
                           height: 1.2,
                           letterSpacing: -0.4,
                         ),
                       ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Mood Chips
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
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
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Category Content
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: _SectionLoader(),
                    ),
                  ),
                );
              }
                  if (state is CategoryLoaded) {
                final songs = state.songs;
                if (songs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                       child: Text(
                         'Không có bài hát nào',
                         style: GoogleFonts.dmSans(
                           color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                           fontSize: 13,
                           fontWeight: FontWeight.w500,
                           height: 1.4,
                         ),
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
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1500),
                            child: CompactSongTile(
                              item: _songEntityToMediaItem(song),
                              onTap: () => _playSongFromCategory(songs, i),
                              rank: i + 1,
                            ),
                          ),
                        );
                      },
                      childCount: songs.length.clamp(0, 20),
                    ),
                  ),
                );
              }
              if (state is CategoryError) {
                return SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Lỗi: ${state.message}',
                       style: GoogleFonts.dmSans(
                         color: Colors.redAccent,
                         fontSize: 12,
                         fontWeight: FontWeight.w500,
                         height: 1.4,
                       ),
                    ),
                  )),
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

  Widget _buildForYouSection(BuildContext context) {
    return FutureBuilder<RecommendationResult>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 220,
            child: Center(child: _SectionLoader()),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final result = snapshot.data;
        if (result == null) return const SizedBox.shrink();

        final songs = result.songs;
        final allItems = songs.map(_songEntityToMediaItem).toList();
        final displayItems = allItems.take(5).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dành cho bạn',
                              style: GoogleFonts.plusJakartaSans(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dựa trên sở thích của bạn',
                              style: GoogleFonts.dmSans(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.62),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (result.hasPreferences && allItems.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        SeeAllButton(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ForYouPage(items: allItems),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!result.hasPreferences)
                  _buildForYouPromptCard(context)
                else if (allItems.isEmpty)
                  const SizedBox.shrink()
                else
                  SizedBox(
                    height: 220,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayItems.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => HorizontalSongCard(
                          width: 160,
                          item: displayItems[index],
                          onTap: () => _playSongFromMediaItems(allItems, index),
                        ),
                      ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForYouPromptCard(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLight
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: isLight ? 0.08 : 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cập nhật sở thích âm nhạc để nhận gợi ý phù hợp',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      onPressed: widget.isLoggedIn ? _openProfileSettingsPrompt : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        'Cài đặt ngay',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildAlbumSection(BuildContext context, List<AlbumEntity> albums) {
    // Chỉ lấy đúng 5 item, ẩn phần còn lại
    final displayAlbums = albums.take(5).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: Column(
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
    ),
      ),
    );
  }

  Widget _buildSuggestionsSection(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading || state is CategoryInitial) {
          return const SizedBox(
            height: 220,
            child: Center(child: _SectionLoader()),
          );
        }
        if (state is! CategoryLoaded) return const SizedBox.shrink();
        final songs = state.allSongs; // Luôn dùng TẤT CẢ songs
        if (songs.isEmpty) return const SizedBox.shrink();

        final displayItems = songs.take(5).map(_songEntityToMediaItem).toList();
        final allItems = songs.map(_songEntityToMediaItem).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1800),
            child: Column(
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
                              onTap: () => _playSongFromMediaItems(allItems, i),
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
        ),
          ),
        );
      },
    );
  }

  Widget _buildCommunitySection(BuildContext context) {
    return FutureBuilder<List<UserSongModel>>(
      future: _approvedSongsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _CommunitySectionSkeleton();
        final approved = snapshot.data!;
        if (approved.isEmpty) return const SizedBox.shrink();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══ HERO HEADER ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                   Container(
                     width: 52,
                     height: 52,
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(18),
                       border: Border.all(
                         color: Colors.white.withValues(alpha: 0.14),
                       ),
                       boxShadow: [
                         BoxShadow(
                           color: const Color(0xFF9333EA).withValues(alpha: 0.34),
                           blurRadius: 18,
                           offset: const Offset(0, 8),
                         ),
                       ],
                     ),
                     child: const Icon(Icons.people_rounded, color: Colors.white, size: 26),
                   ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                          ).createShader(bounds),
                           child: Text(
                             'Nhạc từ cộng đồng',
                             style: GoogleFonts.plusJakartaSans(
                               color: Theme.of(context).colorScheme.onSurface,
                               fontSize: 24,
                               fontWeight: FontWeight.w800,
                               height: 1.2,
                               letterSpacing: -0.4,
                             ),
                           ),
                        ),
                        const SizedBox(height: 2),
                         Text(
                           '${approved.length} bài hát từ cộng đồng',
                           style: GoogleFonts.dmSans(
                             color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                             height: 1.3,
                           ),
                         ),
                      ],
                    ),
                  ),
                  // See all button
                     SeeAllButton(onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ═══ FEATURED + SCROLL ════════════════════════════════════════
            SizedBox(
              height: 260,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: approved.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return _CommunityFeaturedCard(
                      song: approved[i],
                      onTap: () => _playCommunitySong(approved, i),
                    );
                  }
                  return _CommunitySongCard(
                    song: approved[i],
                    rank: i + 1,
                    onTap: () => _playCommunitySong(approved, i),
                  );
                },
              ),
            ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _playCommunitySong(List<UserSongModel> songs, int index) async {
    Future.microtask(() async {
      // Dùng toMediaItem() để id = audioUrl, lưu userSongId trong extras
      // → playlist lookup sẽ hoạt động đúng khi thêm vào playlist
      final playlist = songs.map((s) => s.toMediaItem()).toList();
      await getIt<MusicPlayerService>().playPlaylist(playlist, startIndex: index);
    });
  }

  Widget _buildChartSection(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading || state is CategoryInitial) {
          return const SizedBox(
            height: 200,
            child: Center(child: _SectionLoader()),
          );
        }
        if (state is! CategoryLoaded) return const SizedBox.shrink();
        final songs = state.allSongs; // Luôn dùng TẤT CẢ songs

        if (songs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Bảng xếp hạng', () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SeeAllPage(title: 'Bảng xếp hạng'),
                ));
              }),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Chưa có bài hát nào',
                    style: GoogleFonts.dmSans(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final allItems = songs.map(_songEntityToMediaItem).toList();
        final totalItems = allItems.length;
        final totalPages = (totalItems / 8).ceil();
        // Reset page if songs changed (e.g. category filter)
        final safePage = _chartPage.clamp(1, totalPages);
        final startIdx = (safePage - 1) * 8;
        final pageItems = allItems.skip(startIdx).take(8).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
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
                      onTap: () => _playSongFromMediaItems(allItems, startIdx + i),
                    ),
                  );
                }),
                _buildPaginationRow(safePage, totalPages, (page) {
                  setState(() => _chartPage = page);
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: const Color(0xFF9333EA),
        backgroundColor: isLight
            ? const Color(0xFF6B5EA8).withValues(alpha: 0.14)
            : const Color(0xFF8B8AA8).withValues(alpha: 0.16),
      ),
    );
  }
}

class _CategoryChipSkeleton extends StatelessWidget {
  const _CategoryChipSkeleton();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isLight ? const Color(0xFFECE6FF) : const Color(0xFF221C30),
        highlightColor: isLight ? const Color(0xFFF7F3FF) : const Color(0xFF2B2440),
        child: Container(
          width: 100,
          height: 36,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF4EEFF) : const Color(0xFF171624),
            borderRadius: BorderRadius.circular(999),
          ),
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
                ? const Color(0xFF9333EA)
                : (_isHovered
                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.12)),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF9333EA)
                  : const Color(0xFF8B8AA8).withValues(alpha: _isHovered ? 0.2 : 0.12),
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '${widget.page}',
            style: GoogleFonts.dmSans(
              color: widget.isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── COMMUNITY SECTION SKELETON ───────────────────────────────────────
class _CommunitySectionSkeleton extends StatelessWidget {
  const _CommunitySectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFFF4EEFF)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(18),
                      ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 180,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 80,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── FEATURED COMMUNITY CARD (Hero item) ──────────────────────────────
class _CommunityFeaturedCard extends StatefulWidget {
  final UserSongModel song;
  final VoidCallback onTap;

  const _CommunityFeaturedCard({required this.song, required this.onTap});

  @override
  State<_CommunityFeaturedCard> createState() => _CommunityFeaturedCardState();
}

class _CommunityFeaturedCardState extends State<_CommunityFeaturedCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 172,
          height: 252,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Album art — fixed 172x172 to avoid unbounded Stack
              SizedBox(
                width: 172,
                height: 172,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: widget.song.artUrl != null
                          ? Image.network(widget.song.artUrl!,
                              width: 172, height: 172,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _featuredPlaceholder())
                          : _featuredPlaceholder(),
                    ),
                    // Rank #1 badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              'TOP 1',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Play button
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              // Info section — SizedBox(height: 80) cố định tránh overflow
              SizedBox(
                height: 80,
                child: Container(
                  width: 172,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A0E2E), Color(0xFF2D1450)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Color(0xFFEC4899), size: 10),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.song.durationMs > 0)
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: Color(0xFF9333EA), size: 9),
                            const SizedBox(width: 3),
                            Text(
                              _formatDuration(Duration(milliseconds: widget.song.durationMs)),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.48),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featuredPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D1450), Color(0xFF1A0E2E)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 48),
        ),
      );
}

// ─── COMMUNITY SONG CARD ───────────────────────────────────────────────
class _CommunitySongCard extends StatefulWidget {
  final UserSongModel song;
  final VoidCallback onTap;
  final int? rank;

  const _CommunitySongCard({
    required this.song,
    required this.onTap,
    this.rank,
  });

  @override
  State<_CommunitySongCard> createState() => _CommunitySongCardState();
}

class _CommunitySongCardState extends State<_CommunitySongCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 150,
          height: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Album art — fixed 150x150
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      child: widget.song.artUrl != null
                          ? Image.network(widget.song.artUrl!,
                              width: 150, height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _cardPlaceholder())
                          : _cardPlaceholder(),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.5),
                            ],
                            stops: const [0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Rank badge
                    if (widget.rank != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getRankColor(widget.rank!).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.rank}',
                              style: TextStyle(
                                color: _getRankColor(widget.rank!),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Play button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // Info section — SizedBox(height: 70) cố định tránh overflow
              SizedBox(
                height: 70,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161626),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (widget.song.artist.isNotEmpty)
                        Text(
                          widget.song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFFC084FC),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      if (widget.song.durationMs > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.white.withValues(alpha: 0.35),
                              size: 9,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDuration(
                                Duration(milliseconds: widget.song.durationMs),
                              ),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.38),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardPlaceholder() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E1E30),
              const Color(0xFF161626),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: Colors.white12, size: 36),
        ),
      );

  Color _getRankColor(int rank) {
    if (rank == 2) return const Color(0xFF94A3B8); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.white.withValues(alpha: 0.7);
  }
}

String _formatDuration(Duration d) {
  final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$min:$sec';
}
