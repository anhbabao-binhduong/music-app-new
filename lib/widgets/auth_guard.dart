import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/player/player_page.dart';
import '../presentation/bloc/player/player_bloc.dart';
import '../presentation/bloc/player/player_event.dart';

/// Phát nhạc trực tiếp, không yêu cầu đăng nhập.
void playWithAuthGuard(
  BuildContext context, {
  required List<MediaItem> playlist,
  required int index,
}) {
  _navigateToPlayer(context, playlist: playlist, index: index);
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
