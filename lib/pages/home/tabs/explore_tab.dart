import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
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
import '../../../../presentation/bloc/download/download_cubit.dart';
import '../../../../presentation/bloc/playlist/playlist_cubit.dart';
import '../../../../data/models/playlist_model.dart';
import '../../../../presentation/bloc/favorite/favorite_cubit.dart';
import '../../../../presentation/bloc/player/player_bloc.dart';
import '../../../../presentation/bloc/player/player_event.dart';

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

  int _chartPage = 1;
  final Map<String, int> _categoryPageMap = {};

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

  /// Chuyển SongEntity → MediaItem để dùng chung với bottom sheet
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

  Widget _buildPaginationRow(int currentPage, int totalPages, Function(int) onPageChanged) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (index) {
            final page = index + 1;
            final isSelected = page == currentPage;
            return GestureDetector(
              onTap: () => onPageChanged(page),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border.all(color: Colors.white, width: isSelected ? 0 : 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
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
                    onTap: () => _playSongFromMediaItems(localPlaylist, i),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        ...(() {
          final totalItems = localPlaylist.length;
          final totalPages = (totalItems / 8).ceil();
          final startIdx = (_chartPage - 1) * 8;
          final pageItems = localPlaylist.skip(startIdx).take(8).toList();

          return [
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
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final isFirst = i == 0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isFirst)
                          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 72),
                        ChartTile(
                          item: pageItems[i],
                          rank: startIdx + i + 1,
                          onTap: () => _playSongFromMediaItems(localPlaylist, startIdx + i),
                        ),
                      ],
                    );
                  },
                  childCount: pageItems.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildPaginationRow(_chartPage, totalPages, (page) {
                setState(() => _chartPage = page);
              }),
            ),
          ];
        })(),
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

              final slug = state.selectedSlug ?? '';
              final totalItems = state.songs.length;
              final totalPages = (totalItems / 8).ceil();
              final currentPage = _categoryPageMap[slug] ?? 1;
              final startIdx = (currentPage - 1) * 8;
              final pageItems = state.songs.skip(startIdx).take(8).toList();

              return SliverMainAxisGroup(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _SongTile(
                        song: pageItems[i],
                        mediaItem: _songEntityToMediaItem(pageItems[i]),
                        onTap: () => _playSongFromCategory(state.songs, startIdx + i),
                      ),
                      childCount: pageItems.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildPaginationRow(currentPage, totalPages, (page) {
                      setState(() => _categoryPageMap[slug] = page);
                    }),
                  ),
                ],
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

// ---------------------------------------------------------------------------
// _SongTile – có nút 3 chấm với đầy đủ chức năng như ChartTile
// ---------------------------------------------------------------------------

class _SongTile extends StatelessWidget {
  final SongEntity song;
  final MediaItem mediaItem;
  final VoidCallback onTap;

  const _SongTile({
    required this.song,
    required this.mediaItem,
    required this.onTap,
  });

  // ── Snack bar helper ──────────────────────────────────────────────────────
  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: isError ? 2000 : 1500),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Playlist selection bottom sheet ──────────────────────────────────────
  void _showPlaylistSelection(BuildContext context) {
    final songId = mediaItem.id;
    final controller = TextEditingController();

    void showCreateDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2E),
          title: const Text('Tạo danh sách phát',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập tên playlist...',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final result = await context
                    .read<PlaylistCubit>()
                    .createPlaylistAndAddSong(name, songId);
                if (result == null) {
                  _showSnackBar(context, 'Đã tạo playlist "$name"');
                } else {
                  _showSnackBar(context, result, isError: true);
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: BlocBuilder<PlaylistCubit, PlaylistState>(
          builder: (context, state) {
            final playlists = state is PlaylistLoaded
                ? state.playlists
                : <PlaylistModel>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Thêm vào danh sách phát',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.white),
                  title: const Text('Tạo danh sách phát mới',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Future.microtask(() => showCreateDialog());
                  },
                ),
                const Divider(color: Colors.white12),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có playlist nào',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final p = playlists[index];
                        final isAdded = p.songIds.contains(songId);
                        return ListTile(
                          leading: Icon(
                            isAdded ? Icons.check_circle : Icons.playlist_play,
                            color: isAdded ? Colors.greenAccent : Colors.white70,
                          ),
                          title: Text(p.name,
                              style: const TextStyle(color: Colors.white)),
                          trailing: isAdded
                              ? const Text('Đã thêm',
                                  style: TextStyle(color: Colors.greenAccent))
                              : null,
                          onTap: () async {
                            if (isAdded) {
                              _showSnackBar(context, 'Bài hát đã có trong playlist');
                              Navigator.pop(context);
                              return;
                            }
                            final result = await context
                                .read<PlaylistCubit>()
                                .addSongToPlaylist(p.id, songId);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            if (result == null) {
                              _showSnackBar(context, 'Đã thêm vào "${p.name}"');
                            } else {
                              _showSnackBar(context, result, isError: true);
                            }
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Song info dialog ──────────────────────────────────────────────────────
  void _showSongInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Thông tin bài hát', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Tên bài hát', mediaItem.title),
            const SizedBox(height: 8),
            _infoRow('Nghệ sĩ', mediaItem.artist ?? 'Không rõ'),
            const SizedBox(height: 8),
            _infoRow('Album', mediaItem.album ?? 'Không rõ'),
            const SizedBox(height: 8),
            _infoRow('Thời lượng', _formatDuration(mediaItem.duration ?? Duration.zero)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ── Report dialog ─────────────────────────────────────────────────────────
  void _showReportDialog(BuildContext context) {
    const reasons = [
      'Nội dung không phù hợp',
      'Bản quyền',
      'Thông tin sai lệch',
      'Chất lượng âm thanh kém',
      'Lý do khác',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        title: const Text('Báo cáo bài hát',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map((reason) => ListTile(
                    title: Text(reason,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSnackBar(
                          context, 'Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét.');
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Main options bottom sheet ─────────────────────────────────────────────
  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: BlocBuilder<FavoriteCubit, List<String>>(
          builder: (_, favState) {
            final isFavorite = favState.contains(mediaItem.id);
            return BlocBuilder<DownloadCubit, List<String>>(
              builder: (_, downState) {
                final isDownloaded = downState.contains(mediaItem.id);
                return SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // ── Song header preview ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.artUrl != null
                                ? Image.network(song.artUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholderIcon())
                                : _placeholderIcon(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(song.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(song.artist,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 4),
                    // ── Actions ──────────────────────────────────────────
                    _MenuActionTile(
                      icon: Icons.playlist_play,
                      title: 'Phát tiếp theo',
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<PlayerBloc>().add(PlayNextEvent(mediaItem));
                        _showSnackBar(
                            context, 'Đã thêm "${mediaItem.title}" vào hàng chờ');
                      },
                    ),
                    _MenuActionTile(
                      icon: Icons.queue_music,
                      title: 'Thêm vào playlist',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showPlaylistSelection(context);
                      },
                    ),
                    _MenuActionTile(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      title: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                      iconColor: isFavorite ? Colors.redAccent : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await context
                              .read<FavoriteCubit>()
                              .toggleFavorite(mediaItem.id);
                          _showSnackBar(
                              context,
                              isFavorite
                                  ? 'Đã xóa khỏi yêu thích'
                                  : 'Đã thêm vào yêu thích');
                        } catch (e) {
                          _showSnackBar(context, e.toString(), isError: true);
                        }
                      },
                    ),
                    _MenuActionTile(
                      icon: isDownloaded ? Icons.download_done : Icons.download,
                      title: isDownloaded ? 'Đã tải' : 'Tải nhạc',
                      iconColor: isDownloaded ? Colors.greenAccent : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        if (isDownloaded) {
                          _showSnackBar(context, 'Bài hát đã được tải');
                        } else {
                          try {
                            await context
                                .read<DownloadCubit>()
                                .toggleDownload(mediaItem);
                            _showSnackBar(context, 'Đã tải xuống thành công');
                          } catch (e) {
                            _showSnackBar(context, e.toString(), isError: true);
                          }
                        }
                      },
                    ),
                    _MenuActionTile(
                      icon: Icons.share,
                      title: 'Chia sẻ',
                      onTap: () {
                        Navigator.pop(ctx);
                        Share.share(
                          'Nghe bài hát "${mediaItem.title}" - ${mediaItem.artist} trên Music App',
                          subject: 'Chia sẻ bài hát',
                        );
                      },
                    ),
                    _MenuActionTile(
                      icon: Icons.info_outline,
                      title: 'Thông tin bài hát',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showSongInfoDialog(context);
                      },
                    ),
                    _MenuActionTile(
                      icon: Icons.flag,
                      title: 'Báo cáo',
                      iconColor: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showReportDialog(context);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  ), // Column
                ); // SingleChildScrollView
              },
            );
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.artUrl != null
            ? Image.network(song.artUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon())
            : _placeholderIcon(),
      ),
      title: Text(song.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist,
          style: const TextStyle(color: Colors.white54),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white70),
        onPressed: () => _showOptionsBottomSheet(context),
      ),
      onTap: onTap,
    );
  }

  Widget _placeholderIcon() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.white54),
      );
}

// ---------------------------------------------------------------------------
// Shared menu tile (identical to ChartTile's _MenuActionTile)
// ---------------------------------------------------------------------------

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip skeleton (unchanged)
// ---------------------------------------------------------------------------

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