import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/presentation/bloc/history/history_cubit.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/pages/player/player_page.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';

const _kBg = Color(0xFFF3F4F8);
const _kCard = Colors.white;
const _kTextPrimary = Color(0xFF1A1A2E);
const _kTextSecondary = Color(0xFF6B7280);
const _kDivider = Color(0xFFEEEEF5);
const _kAccent = Color(0xFF0D47A1);

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<void> _playSongs(
      BuildContext context, List<MediaItem> items, int index) async {
    final target = items[index];
    final validItems = items.where((s) {
      final url = s.extras?['url'] as String?;
      return url != null && url.isNotEmpty;
    }).toList();
    if (validItems.isEmpty) return;
    final newIndex = validItems.indexWhere((s) => s.id == target.id);
    if (newIndex == -1) return;
    Future.microtask(() {
      getIt<PlayerBloc>().add(LoadPlaylistEvent(validItems, startIndex: newIndex));
    });
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerPage(song: target)),
    );
  }

  Future<void> _removeItem(BuildContext context, MediaItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa khỏi lịch sử',
            style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold)),
        content: Text('Xóa "${item.title}" khỏi lịch sử nghe?',
            style: const TextStyle(color: _kTextSecondary)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: _kTextSecondary)),
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
    if (confirmed == true && context.mounted) {
      await context.read<HistoryCubit>().removeItem(item.id);
    }
  }

  Widget _buildSongCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.06),
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
    return Scaffold(
      backgroundColor: _kBg,
      body: BlocBuilder<HistoryCubit, List<MediaItem>>(
        builder: (context, history) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    backgroundColor: _kBg,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: _kTextPrimary),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                      title: const Text(
                        'Lịch sử nghe',
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
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFFF3F4F8)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.0, 0.55, 1.0],
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
                                color: Colors.white.withValues(alpha: 0.15),
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
                    actions: [
                      if (history.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: _kCard,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: const Text('Xóa lịch sử',
                                    style: TextStyle(
                                        color: _kTextPrimary,
                                        fontWeight: FontWeight.bold)),
                                content: const Text('Xóa toàn bộ lịch sử nghe?',
                                    style: TextStyle(color: _kTextSecondary)),
                                actionsPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Hủy',
                                        style: TextStyle(color: _kTextSecondary)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.redAccent.withValues(alpha: 0.1),
                                      foregroundColor: Colors.redAccent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Xóa',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              await context.read<HistoryCubit>().clearHistory();
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 18),
                          label: const Text('Xóa tất cả',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  if (history.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: _kDivider),
                              child: const Icon(Icons.history_rounded,
                                  size: 64, color: _kTextSecondary),
                            ),
                            const SizedBox(height: 20),
                            const Text('Chưa có lịch sử nghe',
                                style: TextStyle(
                                    color: _kTextPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text('Phát nhạc để bắt đầu theo dõi',
                                style:
                                    TextStyle(color: _kTextSecondary, fontSize: 14)),
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
                            final item = history[index];
                            return _buildSongCard(
                              child: ListTile(
                                key: ValueKey(item.id),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
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
                                        ? CachedNetworkImage(
                                            imageUrl: item.artUri.toString(),
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                _placeholder(),
                                          )
                                        : _placeholder(),
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                      color: _kTextPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.artist ?? '',
                                    style: const TextStyle(
                                        color: _kTextSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert_rounded,
                                      color: _kTextSecondary, size: 22),
                                  onPressed: () => _showSongOptions(context, item),
                                ),
                                onTap: () => _playSongs(context, history, index),
                              ),
                            );
                          },
                          childCount: history.length,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
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
              decoration:
                  BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
            ),
            BlocBuilder<FavoriteCubit, List<String>>(
              builder: (context, favorites) {
                final isFav = favorites.contains(song.id);
                return ListTile(
                  leading: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? const Color(0xFFD81B60) : _kTextSecondary,
                  ),
                  title: Text(
                    isFav ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                    style: TextStyle(
                        color: isFav ? const Color(0xFFD81B60) : _kTextPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<FavoriteCubit>().toggleFavorite(song.id);
                  },
                );
              },
            ),
            BlocBuilder<DownloadCubit, List<String>>(
              builder: (context, downloads) {
                final isDownloaded = downloads.contains(song.id);
                return ListTile(
                  leading: Icon(
                    isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                    color: isDownloaded ? const Color(0xFF2E7D32) : _kTextSecondary,
                  ),
                  title: Text(
                    isDownloaded ? 'Đã tải' : 'Tải nhạc',
                    style: TextStyle(
                      color: isDownloaded ? const Color(0xFF2E7D32) : _kTextPrimary,
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
            const Divider(color: _kDivider, height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Xóa khỏi lịch sử',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _removeItem(context, song);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEEEF5), Color(0xFFDDDDEE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.music_note_rounded, color: _kTextSecondary, size: 24),
      );
}