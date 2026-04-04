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
    final isWide = MediaQuery.of(context).size.width >= 700;
    
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, isWide),
      body: _buildBody(context, isWide),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isWide) {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
          onPressed: () {
            // TODO: Implement search functionality
            _showSearchDialog(context);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isWide) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 800 : double.infinity,
        ),
        child: Column(
          children: [
            // Header với thống kê
            _buildHeader(context, isWide),
            
            // Danh sách bài hát
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: isWide ? 16 : 12,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: localPlaylist.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                  indent: isWide ? 72 : 60,
                ),
                itemBuilder: (ctx, i) {
                  final song = localPlaylist[i];
                  return ChartTile(
                    item: song,
                    rank: i + 1,
                    onTap: () => playWithAuthGuard(ctx, playlist: localPlaylist, index: i),
                  );
                },
              ),
            ),
            
            // Footer với thông tin tổng số
            _buildFooter(context, isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWide) {
    final totalSongs = localPlaylist.length;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: isWide ? 20 : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7B1FA2).withValues(alpha: 0.3),
            const Color(0xFF1565C0).withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 24 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalSongs bài hát',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: isWide ? 14 : 12,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.playlist_play, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Tất cả',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 13 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: isWide ? 16 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Đã hiển thị ${localPlaylist.length} bài hát',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isWide ? 12 : 11,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Scroll to top
              // You can implement scroll to top functionality
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: isWide ? 500 : double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bài hát...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement search
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tìm kiếm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── See All Button (cải thiện UI) ────────────────────────────────────────────

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
    _scale = Tween<double>(begin: 1.0, end: 0.92)
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
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }
}