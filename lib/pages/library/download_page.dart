import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/pages/player/player_page.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/data/local_music_data.dart';

const _kAccentGreen = Color(0xFF2E7D32);

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  Future<void> _playSongs(List<MediaItem> items, int index) async {
    final validItems = items.where((s) {
      final url = s.extras?['url'] as String?;
      return url != null && url.isNotEmpty;
    }).toList();
    if (validItems.isEmpty) return;
    final target = items[index];
    final newIndex = validItems.indexWhere((s) => s.id == target.id);
    if (newIndex == -1) return;
    context.read<PlayerBloc>().add(LoadPlaylistEvent(validItems, startIndex: newIndex));
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerPage(song: validItems[newIndex])),
    );
  }

  Widget _buildSongCard({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: _kAccentGreen.withValues(alpha: 0.06),
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
      body: BlocBuilder<DownloadCubit, List<String>>(
        builder: (context, downloadIds) {
          String normalize(String url) => url.split('/').last;
          final downloadedSongs = downloadIds.isEmpty
              ? <MediaItem>[]
              : localPlaylist.where((song) {
                  final songFile = normalize(song.id);
                  return downloadIds.any((id) => normalize(id) == songFile);
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
                        'Nhạc đã tải',
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
                                colors: [const Color(0xFF1B5E20), const Color(0xFF2E7D32), bg],
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
                                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (downloadedSongs.isEmpty)
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
                              child: Icon(Icons.download_rounded,
                                  size: 64, color: onSurfaceDim),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Chưa có bài hát nào trong máy',
                              style: TextStyle(
                                  color: onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tải nhạc để nghe khi không có mạng',
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
                            final item = downloadedSongs[index];
                            return _buildSongCard(
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
                                            errorBuilder: (_, __, ___) => _placeholder(),
                                          )
                                        : _placeholder(),
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
                                  icon: const Icon(Icons.remove_circle_outline_rounded,
                                      color: Colors.redAccent, size: 22),
                                  onPressed: () => _confirmRemove(context, item),
                                ),
                                onTap: () => _playSongs(downloadedSongs, index),
                              ),
                            );
                          },
                          childCount: downloadedSongs.length,
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

  Future<void> _confirmRemove(BuildContext context, MediaItem item) async {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceDim = onSurface.withValues(alpha: 0.6);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa khỏi máy?',
            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa bài hát đã tải này không?',
            style: TextStyle(color: onSurfaceDim)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: onSurfaceDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<DownloadCubit>().toggleDownload(item);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ));
        }
      }
    }
  }

  Widget _placeholder() {
    final theme = Theme.of(context);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 24),
    );
  }
}