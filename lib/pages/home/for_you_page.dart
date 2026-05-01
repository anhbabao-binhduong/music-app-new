import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/services/music_player_service.dart';

import 'widgets/song_cards.dart';

class ForYouPage extends StatelessWidget {
  final List<MediaItem> items;

  const ForYouPage({
    super.key,
    required this.items,
  });

  String _normalizeAudioUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url.trim();
    const base =
        'https://pdbkojvgjrvnzqmerwmz.supabase.co/storage/v1/object/public/songs/';
    return '$base${url.trim()}';
  }

  Future<void> _playSongFromMediaItems(
    List<MediaItem> items,
    int index,
  ) async {
    Future.microtask(() async {
      final musicService = getIt<MusicPlayerService>();

      final validItems = items.where((s) {
        final url = s.extras?['url'] as String?;
        return url != null && url.isNotEmpty;
      }).toList();

      if (validItems.isEmpty) return;

      final targetSong = items[index];

      int newIndex = validItems.indexWhere((s) => s.id == targetSong.id);
      if (newIndex == -1) {
        for (int i = index + 1; i < items.length; i++) {
          final next = validItems.indexWhere((s) => s.id == items[i].id);
          if (next != -1) {
            newIndex = next;
            break;
          }
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Dành cho bạn',
          style: GoogleFonts.plusJakartaSans(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Chưa có gợi ý phù hợp',
                  style: GoogleFonts.dmSans(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                color: cs.onSurface.withValues(alpha: isLight ? 0.08 : 0.06),
                height: 12,
                indent: 78,
              ),
              itemBuilder: (context, index) {
                return CompactSongTile(
                  item: items[index],
                  onTap: () => _playSongFromMediaItems(items, index),
                  rank: index + 1,
                );
              },
            ),
    );
  }
}