import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/pages/player/player_page.dart';

import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:music_app/data/local_music_data.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';

const _kAccentPink = Color(0xFFD81B60);

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  Future<void> _playSongs(List<MediaItem> items, int index) async {
    final validItems = items.where((s) {
      final url = s.extras?['url'] as String?;
      return url != null && url.isNotEmpty;
    }).toList();

    if (validItems.isEmpty) return;

    final targetSong = items[index];
    final newIndex = validItems.indexWhere((s) => s.id == targetSong.id);
    if (newIndex == -1) return;

    context.read<PlayerBloc>().add(LoadPlaylistEvent(validItems, startIndex: newIndex));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerPage(song: validItems[newIndex]),
      ),
    );
  }

  Widget _buildSongCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: _kAccentPink.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: BlocBuilder<FavoriteCubit, List<String>>(
        builder: (context, favoriteIds) {
          String normalize(String url) => url.split('/').last;

          final favoriteSongs = favoriteIds.isEmpty
              ? <MediaItem>[]
              : localPlaylist.where((song) {
                  final songFile = normalize(song.id);
                  return favoriteIds.any((id) => normalize(id) == songFile);
                }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    backgroundColor: bg,
                    elevation: 0,
                    iconTheme: IconThemeData(color: onSurface),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                      title: const Text(
                        'Bài hát yêu thích',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFFAD1457), const Color(0xFFD81B60), bg],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.55, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: onSurface.withValues(alpha: 0.1),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (favoriteSongs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.dividerColor,
                              ),
                              child: Icon(Icons.favorite_border_rounded,
                                  size: 64, color: onSurfaceDim),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Chưa có bài hát yêu thích nào',
                              style: TextStyle(
                                  color: onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Thả tim để thêm vào danh sách này',
                              style: TextStyle(color: onSurfaceDim, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = favoriteSongs[index];
                            return _buildSongCard(
                              context,
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: item.artUri != null
                                        ? Image.network(
                                            item.artUri.toString(),
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _placeholder(context),
                                          )
                                        : _placeholder(context),
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                      color: onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.artist ?? 'Unknown Artist',
                                    style: TextStyle(
                                        color: onSurfaceDim,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.more_vert_rounded,
                                      color: onSurfaceDim, size: 22),
                                  onPressed: () => _showSongOptions(context, item),
                                ),
                                onTap: () => _playSongs(favoriteSongs, index),
                              ),
                            );
                          },
                          childCount: favoriteSongs.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSongOptions(BuildContext context, MediaItem song) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: _kAccentPink),
              title: Text('Bỏ yêu thích',
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.read<FavoriteCubit>().toggleFavorite(song.id);
              },
            ),
            BlocBuilder<DownloadCubit, List<String>>(
              builder: (context, downloads) {
                final isDownloaded = downloads.contains(song.id);
                return ListTile(
                  leading: Icon(
                    isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                    color: isDownloaded ? const Color(0xFF2E7D32) : onSurfaceDim,
                  ),
                  title: Text(
                    isDownloaded ? 'Đã tải' : 'Tải nhạc',
                    style: TextStyle(
                      color: isDownloaded ? const Color(0xFF2E7D32) : onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await context.read<DownloadCubit>().toggleDownload(song);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.surfaceContainerHigh, theme.colorScheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 24),
    );
  }
}