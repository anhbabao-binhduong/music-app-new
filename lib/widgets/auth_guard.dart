import 'package:audio_service/audio_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/auth/login_page.dart';
import '../pages/player/player_page.dart';
import '../presentation/bloc/player/player_bloc.dart';
import '../presentation/bloc/player/player_event.dart';

/// Kiểm tra đăng nhập trước khi phát nhạc.
/// Nếu chưa đăng nhập → hiện dialog yêu cầu đăng nhập.
/// Nếu đã đăng nhập → phát nhạc và mở PlayerPage.
void playWithAuthGuard(
  BuildContext context, {
  required List<MediaItem> playlist,
  required int index,
}) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    _showLoginDialog(context, playlist: playlist, index: index);
  } else {
    _navigateToPlayer(context, playlist: playlist, index: index);
  }
}

void _navigateToPlayer(
  BuildContext context, {
  required List<MediaItem> playlist,
  required int index,
}) {
  context.read<PlayerBloc>().add(LoadPlaylistEvent(playlist, startIndex: index));
  Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (_, anim, __) => PlayerPage(song: playlist[index]),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ));
}

void _showLoginDialog(
  BuildContext context, {
  required List<MediaItem> playlist,
  required int index,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // ── thêm constraint để dialog không quá rộng trên web ──
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đăng nhập để nghe nhạc',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Bạn cần đăng nhập để phát nhạc và\ntrải nghiệm đầy đủ tính năng.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Nút đăng nhập
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (_, anim, __) => const LoginPage(),
                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                      position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  ));
                },
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.4),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  alignment: Alignment.center,
                  child: const Text('Đăng nhập ngay',
                      style: TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),

              // Nút huỷ
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('Để sau',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}