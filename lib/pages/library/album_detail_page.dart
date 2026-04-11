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
      body: Column(
        children: [
          // HEADER: Cover image, title, artist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 16),
                Text(
                  album.title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${album.artistName}${album.releaseYear != null ? ' • ${album.releaseYear}' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                if (album.description != null && album.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    album.description!,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.play_circle_fill_rounded, color: Colors.greenAccent, size: 36),
                    SizedBox(width: 8),
                    Text(
                      "Phát tất cả",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // SONG LIST
          Expanded(
            child: album.songIds.isEmpty
              ? const Center(child: Text("Album chưa có bài hát nào", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: album.songIds.length,
                  itemBuilder: (context, index) {
                    final songId = album.songIds[index];
                    
                    final songIndex = playableSongs.indexWhere((s) => s.id == songId);
                    final song = songIndex != -1 ? playableSongs[songIndex] : null;

                    if (song == null) {
                      return ListTile(
                        key: ValueKey(songId),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.music_off_rounded, color: Colors.white54),
                        ),
                        title: const Text(
                          'Bài hát không còn khả dụng',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: $songId',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }

                    return ListTile(
                      key: ValueKey(songId),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: song.artUri?.toString() ?? '',
                          width: 50, height: 50, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 50, height: 50, color: Colors.white12,
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                      ),
                      title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.artist ?? 'Unknown', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text('${index + 1}', style: const TextStyle(color: Colors.white24, fontSize: 14)),
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
                    );
                  },
                ),
          ),
        ],
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
}
