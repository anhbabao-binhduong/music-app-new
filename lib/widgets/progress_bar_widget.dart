// lib/widgets/progress_bar_widget.dart
import 'package:flutter/material.dart';
import '../services/music_player_service.dart';

/// Isolated widget — only this rebuilds on position ticks.
/// Parent page is NOT rebuilt thanks to StreamBuilder scoping.
class ProgressBarWidget extends StatelessWidget {
  final MusicPlayerService service;
  final ValueChanged<Duration> onSeek;

  const ProgressBarWidget({
    super.key,
    required this.service,
    required this.onSeek,
  });

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, posSnap) {
        return StreamBuilder<Duration?>(
          stream: service.durationStream,
          builder: (context, durSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = durSnap.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0;

            return Column(
              children: [
                Slider(
                  value: progress,
                  onChanged: (v) {
                    final ms =
                        (v * duration.inMilliseconds).round();
                    onSeek(Duration(milliseconds: ms));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(position), style: tt.bodySmall),
                      Text(_format(duration),  style: tt.bodySmall),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}