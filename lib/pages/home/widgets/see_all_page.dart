import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/local_music_data.dart';
import '../../../../widgets/auth_guard.dart';
import '../home_page.dart';
import 'chart_tile.dart';

// ── See All Page ──────────────────────────────────────────────────────────────

class SeeAllPage extends StatelessWidget {
  final String title;
  const SeeAllPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
              onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: localPlaylist.length,
        separatorBuilder: (_, __) =>
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 72),
        itemBuilder: (ctx, i) {
          final song = localPlaylist[i];
          return ChartTile( // <--- ĐỔI Ở ĐÂY (từ ChartSongTile thành ChartTile)
            item: song, 
            rank: i + 1,
            onTap: () => playWithAuthGuard(ctx, playlist: localPlaylist, index: i),
          );
        },
      ),
    );
  }
}

// ── See All Button ────────────────────────────────────────────────────────────

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
    _scale = Tween<double>(begin: 1.0, end: 0.90)
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: const Color(0xFF7B1FA2).withValues(alpha: 0.45),
              blurRadius: 10, offset: const Offset(0, 4),
            )],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Xem tất cả',
                  style: TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
            ],
          ),
        ),
      ),
    );
  }
}