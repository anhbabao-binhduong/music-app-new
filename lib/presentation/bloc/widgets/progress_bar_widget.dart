import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/music_player_service.dart';

/// Isolated widget — only this rebuilds on position ticks.
/// PlayerPage is NOT rebuilt thanks to StreamBuilder scoping.
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

    // Combine position + duration into a single stream
    return StreamBuilder<_ProgressData>(
      stream: service.positionStream.asyncMap(
        (pos) async {
          final dur = await service.durationStream.first ?? Duration.zero;
          return _ProgressData(pos, dur);
        },
      ),
      builder: (context, snap) {
        final data = snap.data ?? _ProgressData(Duration.zero, Duration.zero);
        final progress = data.duration.inMilliseconds > 0
            ? (data.position.inMilliseconds /
               data.duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context),
              child: Slider(
                value: progress,
                onChanged: (v) {
                  final ms =
                      (v * data.duration.inMilliseconds).round();
                  onSeek(Duration(milliseconds: ms));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(data.position), style: tt.bodySmall),
                  Text(_format(data.duration), style: tt.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressData {
  final Duration position;
  final Duration duration;
  const _ProgressData(this.position, this.duration);
}