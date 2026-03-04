import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../bloc/player/player_bloc.dart';
import '../../bloc/player/player_event.dart';
import '../../bloc/player/player_state.dart';
import '../player/player_page.dart';
import '../../widgets/mini_player_bar.dart';

// Sample data — replace with real repository
final List<MediaItem> _samplePlaylist = List.generate(20, (i) => MediaItem(
  id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-${i + 1}.mp3',
  title: 'Track ${i + 1}',
  artist: ['Daft Punk', 'Portishead', 'Massive Attack', 'Bonobo'][i % 4],
  album: ['Discovery', 'Dummy', 'Mezzanine', 'Black Sands'][i % 4],
  artUri: Uri.parse('https://picsum.photos/seed/music$i/400/400'),
  duration: Duration(minutes: 3, seconds: 20 + i),
));

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── SliverAppBar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text('My Library', style: tt.displayMedium?.copyWith(
                fontSize: 24,
              )),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person_rounded),
                onPressed: () {},
              ),
            ],
          ),

          // ── Recently Played ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Recently Played', style: tt.titleLarge),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 148,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 6,
                itemBuilder: (ctx, i) =>
                    _HorizontalCard(item: _samplePlaylist[i]),
              ),
            ),
          ),

          // ── All Songs header ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Songs', style: tt.titleLarge),
                  TextButton(
                    onPressed: () {},
                    child: Text('See all',
                        style: TextStyle(color: cs.primary)),
                  ),
                ],
              ),
            ),
          ),

          // ── Song List — ListView.builder via SliverList ───
          SliverList.builder(
            itemCount: _samplePlaylist.length,
            itemBuilder: (ctx, index) => _SongTile(
              item: _samplePlaylist[index],
              index: index,
              onTap: () {
                context.read<PlayerBloc>().add(
                  LoadPlaylistEvent(_samplePlaylist, startIndex: index),
                );
                _navigateToPlayer(ctx, _samplePlaylist[index]);
              },
            ),
          ),

          // ── Bottom padding for mini player ────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // ── Mini Player (persistent bottom bar) ──────────────
      bottomSheet: const MiniPlayerBar(),
    );
  }

  void _navigateToPlayer(BuildContext ctx, MediaItem song) {
    Navigator.of(ctx).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => PlayerPage(song: song),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _HorizontalCard extends StatelessWidget {
  final MediaItem item;
  const _HorizontalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'album-art-${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.artUri.toString(),
                  width: 110, height: 110, fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final VoidCallback onTap;
  const _SongTile({required this.item, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: cs.primary.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Album thumb
              Hero(
                tag: 'song-thumb-${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.artUri.toString(),
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 52, height: 52,
                      color: cs.surfaceVariant,
                      child: Icon(Icons.music_note_rounded,
                          color: cs.primary, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: tt.titleLarge,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item.artist ?? '',
                        style: tt.titleMedium,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Duration
              Text(
                '3:${40 + index % 20}'.padLeft(4, '0'),
                style: tt.bodySmall,
              ),
              const SizedBox(width: 8),
              Icon(Icons.more_vert_rounded,
                  size: 20, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}