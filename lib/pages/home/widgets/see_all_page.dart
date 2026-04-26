import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../data/local_music_data.dart';
import '../../../../widgets/auth_guard.dart';
import '../../../../core/di/service_locator.dart';
import 'chart_tile.dart';
import 'album_card.dart';
import '../../../domain/entities/album_entity.dart';
import '../../../presentation/bloc/album/album_cubit.dart';
import '../../../presentation/bloc/album/album_state.dart';
import '../../library/album_detail_page.dart';
import '../../../presentation/bloc/favorite/favorite_cubit.dart';
import '../../../presentation/bloc/playlist/playlist_cubit.dart';
import '../../../presentation/bloc/download/download_cubit.dart';

enum SeeAllType { songs, albums }

class SeeAllPage extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? description;
  final SeeAllType type;

  const SeeAllPage({
    super.key, 
    required this.title,
    this.imageUrl,
    this.description,
    this.type = SeeAllType.songs,
  });

  @override
  State<SeeAllPage> createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  final String fallbackImageUrl = 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80';
  final String fallbackDescription = 'Lời tựa: Danh sách ca khúc hot nhất hiện tại, được hệ thống tự động tổng hợp dựa trên số liệu lượt nghe và chia sẻ của bài hát trên mọi nền tảng. Dữ liệu sẽ được lấy trong 30 ngày gần nhất và được cập nhật liên tục.';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 750;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? theme.colorScheme.surface : const Color(0xFF170F23),
      appBar: _buildAppBar(context, isWide),
      body: _buildBody(context, isWide),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: !isWide
          ? Flexible(
              child: Text(
                widget.title,
                style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: onSurface, size: 24),
          onPressed: () => _showSearchDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isWide) {
    if (widget.type == SeeAllType.albums) {
      return _buildAlbumsLayout(context, isWide);
    }
    if (isWide) {
      return _buildSongsDesktopLayout(context);
    } else {
      return _buildSongsMobileLayout(context);
    }
  }

  // ── Albums Layout ────────────────────────────────────────────────────────────
  Widget _buildAlbumsLayout(BuildContext context, bool isWide) {
    if (isWide) {
      return BlocProvider(
        create: (_) => getIt<AlbumCubit>()..loadAlbums(),
        child: BlocBuilder<AlbumCubit, AlbumState>(
          builder: (context, state) {
            if (state is AlbumLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AlbumLoaded) {
              return _buildAlbumsDesktopGrid(state.albums);
            }
            return const Center(child: Text('Không có album', style: TextStyle(color: Colors.white54)));
          },
        ),
      );
    }
    return BlocProvider(
      create: (_) => getIt<AlbumCubit>()..loadAlbums(),
      child: BlocBuilder<AlbumCubit, AlbumState>(
        builder: (context, state) {
          if (state is AlbumLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AlbumLoaded) {
            return Column(
              children: [
                _buildAlbumMobileHeader(state.albums.length),
                Expanded(child: _buildAlbumsGrid(state.albums, crossAxisCount: 2)),
              ],
            );
          }
          return const Center(child: Text('Không có album', style: TextStyle(color: Colors.white54)));
        },
      ),
    );
  }

  Widget _buildAlbumMobileHeader(int totalAlbums) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isLight ? colorScheme.surface : const Color(0xFF170F23),
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? colorScheme.onSurface.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalAlbums album',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsDesktopGrid(List<AlbumEntity> albums) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title.toUpperCase(),
            style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${albums.length} album',
            style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 24,
                crossAxisSpacing: 20,
                childAspectRatio: 0.75,
              ),
              itemCount: albums.length,
              itemBuilder: (ctx, i) => AlbumCard(
                album: albums[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumDetailPage(album: albums[i]))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsGrid(List<AlbumEntity> albums, {required int crossAxisCount}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: albums.length,
      itemBuilder: (ctx, i) => AlbumCard(
        album: albums[i],
        width: double.infinity,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumDetailPage(album: albums[i]))),
      ),
    );
  }

  // ── Songs Desktop Layout ─────────────────────────────────────────────────────
  Widget _buildSongsDesktopLayout(BuildContext context) {
    final imgUrl = widget.imageUrl ?? fallbackImageUrl;
    final desc = widget.description ?? fallbackDescription;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final onSurface = colorScheme.onSurface;
    final panelColor = isLight
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.04);
    final panelBorder = isLight
        ? onSurface.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.06);

    // ignore: no_leading_underscores_for_local_identifiers
    final _headerStyle = TextStyle(
      color: onSurface.withValues(alpha: isLight ? 0.72 : 0.6),
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar 
          SizedBox(
            width: 300,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imgUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, err) => Container(
                      width: 300,
                      height: 300,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cập nhật: Hôm nay\nLượt nghe: 10M+',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       if (localPlaylist.isNotEmpty) {
                         playWithAuthGuard(context, playlist: localPlaylist, index: 0);
                       }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    label: const Text('PHÁT TẤT CẢ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9b4de0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                )
              ]
            )
          ),
          const SizedBox(width: 48),
          // Right Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: panelBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: isLight ? 0.82 : 0.72),
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Text('BÀI HÁT', style: _headerStyle)),
                        Expanded(flex: 3, child: Text('ALBUM', style: _headerStyle)),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('THỜI GIAN', style: _headerStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: onSurface.withValues(alpha: isLight ? 0.12 : 0.08),
                    height: 1,
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: localPlaylist.length,
                      itemBuilder: (ctx, i) {
                        return _ZingMusicTableRow(
                          item: localPlaylist[i],
                          index: i,
                          onTap: () => playWithAuthGuard(ctx, playlist: localPlaylist, index: i),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ]
      )
    );
  }

  // ── Songs Mobile Layout ─────────────────────────────────────────────────────
  Widget _buildSongsMobileLayout(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Header với thống kê
          _buildSongsMobileHeader(context),
          
          // Danh sách bài hát
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: localPlaylist.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.white.withValues(alpha: 0.06),
                height: 1,
                indent: 60,
              ),
              itemBuilder: (ctx, i) {
                final song = localPlaylist[i];
                return ChartTile(
                  item: song,
                  rank: i + 1,
                  onTap: () => playWithAuthGuard(ctx, playlist: localPlaylist, index: i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsMobileHeader(BuildContext context) {
    final totalSongs = localPlaylist.length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isLight ? colorScheme.surface : const Color(0xFF170F23),
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? colorScheme.onSurface.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalSongs bài hát',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (localPlaylist.isNotEmpty) {
                playWithAuthGuard(context, playlist: localPlaylist, index: 0);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9b4de0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.playlist_play, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Phát tất cả',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final isLight = theme.brightness == Brightness.light;

        return Dialog(
          backgroundColor: isLight ? colorScheme.surface : const Color(0xFF2A2A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bài hát...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isLight
                        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B4DE0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tìm kiếm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZingMusicTableRow extends StatefulWidget {
  final MediaItem item;
  final int index;
  final VoidCallback onTap;

  const _ZingMusicTableRow({required this.item, required this.index, required this.onTap});

  @override
  State<_ZingMusicTableRow> createState() => _ZingMusicTableRowState();
}

class _ZingMusicTableRowState extends State<_ZingMusicTableRow> {
  bool _isHovered = false;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final titleColor = colorScheme.onSurface;
    final subColor = colorScheme.onSurface.withValues(alpha: 0.62);
    final lineColor = isLight
        ? colorScheme.onSurface.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.05);
    final hoverColor = isLight
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.08);
    final thumbFallback = isLight
        ? colorScheme.surfaceContainerHighest
        : Colors.black26;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              bottom: BorderSide(color: _isHovered ? Colors.transparent : lineColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         if (_isHovered)
                            Icon(
                              Icons.music_note_rounded,
                              color: isLight ? colorScheme.primary : Colors.white70,
                              size: 16,
                            )
                         else
                            Icon(
                              Icons.music_note_rounded,
                              color: isLight ? subColor : Colors.white30,
                              size: 16,
                            ),
                      ],
                    )),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                           Container(
                             width: 48,
                             height: 48,
                             color: thumbFallback,
                             child: widget.item.artUri != null
                               ? CachedNetworkImage(
                                   imageUrl: widget.item.artUri.toString(),
                                   fit: BoxFit.cover,
                                   errorWidget: (c, u, e) => Icon(
                                     Icons.music_note,
                                     color: isLight ? Colors.black26 : Colors.white30,
                                   ),
                                 )
                               : Icon(
                                   Icons.music_note,
                                   color: isLight ? Colors.black26 : Colors.white30,
                                 ),
                           ),
                           if (_isHovered)
                             Container(
                               width: 48,
                               height: 48,
                               color: Colors.black.withValues(alpha: isLight ? 0.20 : 0.5),
                               child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                             )
                        ]
                      )
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                             widget.item.title,
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(
                               color: titleColor,
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                           const SizedBox(height: 6),
                           Text(
                             widget.item.artist ?? 'Unknown Artist',
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(color: subColor, fontSize: 12),
                           ),
                        ]
                      )
                    )
                  ]
                )
              ),
              Expanded(
                flex: 3,
                child: Text(
                  widget.item.album ?? 'Single',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subColor, fontSize: 13),
                )
              ),
              SizedBox(
                width: 60,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _isHovered 
                    ? SizedBox(
                        width: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                context.read<FavoriteCubit>().state.contains(widget.item.id)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border,
                                color: context.read<FavoriteCubit>().state.contains(widget.item.id)
                                    ? const Color(0xFFE91E8C)
                                    : (isLight ? subColor : Colors.white70),
                                size: 16,
                              ),
                              onPressed: () async {
                                final wasFav = context.read<FavoriteCubit>().state.contains(widget.item.id);
                                try {
                                  await context.read<FavoriteCubit>().toggleFavorite(widget.item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(wasFav ? 'Đã thêm vào yêu thích' : 'Đã bỏ khỏi yêu thích'),
                                        backgroundColor: wasFav ? const Color(0xFFE91E8C) : Colors.grey.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.more_horiz,
                                color: isLight ? subColor : Colors.white70,
                                size: 16,
                              ),
                              onPressed: () {
                                final pageContext = context;
                                showModalBottomSheet(
                                  context: pageContext,
                                  backgroundColor: Colors.transparent,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (ctx) {
                                    final sheetTheme = Theme.of(ctx);
                                    final sheetScheme = sheetTheme.colorScheme;
                                    final sheetIsLight =
                                        sheetTheme.brightness == Brightness.light;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: sheetIsLight
                                            ? sheetScheme.surface
                                            : const Color(0xFF1E1E28),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                        border: Border(
                                          top: BorderSide(
                                            color: sheetIsLight
                                                ? sheetScheme.onSurface.withValues(alpha: 0.08)
                                                : Colors.white.withValues(alpha: 0.12),
                                          ),
                                        ),
                                      ),
                                      child: SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 36, height: 4,
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: sheetIsLight
                                                  ? sheetScheme.onSurface.withValues(alpha: 0.18)
                                                  : Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          BlocBuilder<PlaylistCubit, PlaylistState>(
                                            bloc: context.read<PlaylistCubit>(),
                                            builder: (context, state) {
                                              bool isInAnyPlaylist = false;
                                              if (state is PlaylistLoaded) {
                                                isInAnyPlaylist = state.playlists.any((pl) => pl.songIds.contains(widget.item.id));
                                              }

                                              return ListTile(
                                                leading: Icon(
                                                  isInAnyPlaylist ? Icons.check_circle_rounded : Icons.queue_music_rounded,
                                                  color: isInAnyPlaylist
                                                      ? const Color(0xFF7C3AED)
                                                      : (sheetIsLight
                                                          ? sheetScheme.onSurface.withValues(alpha: 0.7)
                                                          : Colors.white70),
                                                ),
                                                title: Text(
                                                  isInAnyPlaylist ? 'Đã thêm vào playlist' : 'Thêm vào playlist',
                                                  style: TextStyle(
                                                    color: isInAnyPlaylist
                                                        ? const Color(0xFF7C3AED)
                                                        : sheetScheme.onSurface,
                                                  ),
                                                ),
                                                onTap: () {
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(pageContext).showSnackBar(
                                                    SnackBar(
                                                      content: Text(isInAnyPlaylist ? 'Bài hát đã có trong playlist' : 'Vui lòng chọn playlist từ mục Thư viện'),
                                                      backgroundColor: const Color(0xFF7C3AED),
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(
                                              Icons.share_rounded,
                                              color: sheetIsLight
                                                  ? sheetScheme.onSurface.withValues(alpha: 0.7)
                                                  : Colors.white70,
                                            ),
                                            title: Text(
                                              'Chia sẻ',
                                              style: TextStyle(color: sheetScheme.onSurface),
                                            ),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                            },
                                          ),
                                          BlocBuilder<DownloadCubit, List<String>>(
                                            builder: (context, downloadedIds) {
                                              final isDownloaded = downloadedIds.contains(widget.item.id);
                                              return ListTile(
                                                leading: Icon(
                                                  isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                                  color: isDownloaded
                                                      ? const Color(0xFF1DB954)
                                                      : (sheetIsLight
                                                          ? sheetScheme.onSurface.withValues(alpha: 0.7)
                                                          : Colors.white70),
                                                ),
                                                title: Text(
                                                  isDownloaded ? 'Đã tải' : 'Tải nhạc',
                                                  style: TextStyle(
                                                    color: isDownloaded
                                                        ? const Color(0xFF1DB954)
                                                        : sheetScheme.onSurface,
                                                  ),
                                                ),
                                                                                                onTap: () async {
                                                  Navigator.pop(ctx);
                                                  try {
                                                    final downloadCubit = pageContext.read<DownloadCubit>();
                                                    await downloadCubit.toggleDownload(widget.item);
                                                    final isNowDown = downloadCubit.state.contains(widget.item.id);
                                                    if (pageContext.mounted) {
                                                      ScaffoldMessenger.of(pageContext).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            isNowDown
                                                                ? 'Đã tải bài hát'
                                                                : 'Đã xóa khỏi tải về',
                                                          ),
                                                          backgroundColor:
                                                              const Color(0xFF1DB954),
                                                          behavior:
                                                              SnackBarBehavior.floating,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(12)),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (pageContext.mounted) {
                                                      ScaffoldMessenger.of(pageContext).showSnackBar(
                                                        SnackBar(
                                                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                                                          backgroundColor: Colors.red.shade700,
                                                          behavior: SnackBarBehavior.floating,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        _formatDuration(widget.item.duration),
                        style: TextStyle(color: subColor, fontSize: 13),
                      )
                )
              )
            ]
          )
        )
      )
    );
  }
}

// ── See All Button (cải thiện UI) ────────────────────────────────────────────

class SeeAllButton extends StatefulWidget {
  final VoidCallback onTap;
  const SeeAllButton({super.key, required this.onTap});

  @override
  State<SeeAllButton> createState() => _SeeAllButtonState();
}

class _SeeAllButtonState extends State<SeeAllButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.92)
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 28,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 9,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
