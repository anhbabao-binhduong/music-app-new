import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/local_music_data.dart';
import '../../../domain/entities/album_entity.dart';
import '../../../presentation/bloc/player/player_bloc.dart';
import '../../../presentation/bloc/player/player_event.dart';
import '../player/player_page.dart';

class AlbumDetailPage extends StatelessWidget {
  final AlbumEntity album;
  const AlbumDetailPage({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    // Map string IDs to MediaItem from local data
    final playableSongs = album.songIds
        .map(findSongById)
        .whereType<MediaItem>()
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // HEADER: Cover image, title, artist
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: album.coverUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: album.coverUrl!,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _buildFallbackCover(),
                                    )
                                  : _buildFallbackCover(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            album.title,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${album.artistName}${album.releaseYear != null ? ' • ${album.releaseYear}' : ''}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                          ),
                          if (album.description != null && album.description!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              album.description!,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // PLAY ALL BUTTON
                    if (playableSongs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InkWell(
                          onTap: () {
                            context.read<PlayerBloc>().add(
                              LoadPlaylistEvent(playableSongs, startIndex: 0),
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerPage(song: playableSongs[0]),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1DB954), Color(0xFF179B44)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  "Phát tất cả",
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // SONG LIST
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
                sliver: album.songIds.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Text("Album chưa có bài hát nào", style: TextStyle(color: Colors.grey))
                      )
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final songId = album.songIds[index];
                          final songIndex = playableSongs.indexWhere((s) => s.id == songId);
                          final song = songIndex != -1 ? playableSongs[songIndex] : null;

                          return _buildSongCard(
                            context: context,
                            index: index,
                            songId: songId,
                            song: song,
                            songIndex: songIndex,
                            playableSongs: playableSongs,
                          );
                        },
                        childCount: album.songIds.length,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey[800],
      child: const Icon(Icons.album, size: 80, color: Colors.white54),
    );
  }

  Widget _buildSongCard({
    required BuildContext context,
    required int index,
    required String songId,
    MediaItem? song,
    required int songIndex,
    required List<MediaItem> playableSongs,
  }) {
    if (song == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          key: ValueKey(songId),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_off_rounded, color: Colors.white54),
          ),
          title: const Text(
            'Bài hát không còn khả dụng',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'ID: $songId',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.read<PlayerBloc>().add(
              LoadPlaylistEvent(playableSongs, startIndex: songIndex),
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerPage(song: song),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.artUri?.toString() ?? '',
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 52, height: 52, color: Colors.white12,
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? 'Unknown',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
