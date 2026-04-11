import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/presentation/bloc/history/history_cubit.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/pages/player/player_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<void> _playSongs(
      BuildContext context, List<MediaItem> items, int index) async {
    final target = items[index];

    // Lọc bài có URL hợp lệ
    final validItems = items.where((s) {
      final url = s.extras?['url'] as String?;
      return url != null && url.isNotEmpty;
    }).toList();
    if (validItems.isEmpty) return;

    final newIndex = validItems.indexWhere((s) => s.id == target.id);
    if (newIndex == -1) return;

    // Tải playlist & navigate đồng thời (microtask tránh jank)
    Future.microtask(() {
      getIt<PlayerBloc>().add(LoadPlaylistEvent(
        validItems,
        startIndex: newIndex,
      ));
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
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa khỏi lịch sử',
            style: TextStyle(color: Colors.white)),
        content: Text('Xóa "${item.title}" khỏi lịch sử nghe?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<HistoryCubit>().removeItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Lịch sử nghe',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          BlocBuilder<HistoryCubit, List<MediaItem>>(
            builder: (context, history) {
              if (history.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF2A2A2E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Xóa lịch sử',
                          style: TextStyle(color: Colors.white)),
                      content: const Text('Xóa toàn bộ lịch sử nghe?',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Xóa',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await context.read<HistoryCubit>().clearHistory();
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white54, size: 18),
                label: const Text('Xóa tất cả',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, List<MediaItem>>(
        builder: (context, history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  const Text('Chưa có lịch sử nghe',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Phát nhạc để bắt đầu theo dõi',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                key: ValueKey(item.id),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.artUri != null
                      ? CachedNetworkImage(
                          imageUrl: item.artUri.toString(),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.artist ?? '',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: Colors.white38, size: 20),
                  onPressed: () => _removeItem(context, item),
                ),
                onTap: () => _playSongs(context, history, index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: const Color(0xFF2A2A2E),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white24, size: 24),
      );
}
