import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../home_page.dart';

class HorizontalSongCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  const HorizontalSongCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'art-${item.id}',
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ArtImage(uri: item.artUri, size: 120)),
            ),
            const SizedBox(height: 8),
            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(item.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kSubText, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class ArtImage extends StatelessWidget {
  final Uri? uri;
  final double size;
  const ArtImage({super.key, required this.uri, required this.size});

  @override
  Widget build(BuildContext context) {
    if (uri != null) {
      return CachedNetworkImage(
        imageUrl: uri.toString(),
        width: size, height: size, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => ArtPlaceholder(size: size),
      );
    }
    return ArtPlaceholder(size: size);
  }
}

class ArtPlaceholder extends StatelessWidget {
  final double size;
  const ArtPlaceholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
            colors: [Color(0xFF2A2A2E), Color(0xFF1C1C1E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(Icons.music_note_rounded,
          color: kAccent.withValues(alpha: 0.7), size: size * 0.42),
    );
  }
}