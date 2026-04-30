// lib/widgets/progress_bar_widget.dart
import 'dart:math' as math;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final v = (details.localPosition.dx / width).clamp(0.0, 1.0);
                        final ms = (v * duration.inMilliseconds).round();
                        onSeek(Duration(milliseconds: ms));
                      },
                      onHorizontalDragUpdate: (details) {
                        final v = (details.localPosition.dx / width).clamp(0.0, 1.0);
                        final ms = (v * duration.inMilliseconds).round();
                        onSeek(Duration(milliseconds: ms));
                      },
                      child: SizedBox(
                        height: 24,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: (progress * width - 5).clamp(0.0, math.max(0.0, width - 10)),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF9333EA),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9333EA).withValues(alpha: 0.7),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _format(position),
                        style: tt.bodySmall?.copyWith(
                          color: isDark
                              ? null
                              : Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      Text(
                        _format(duration),
                        style: tt.bodySmall?.copyWith(
                          color: isDark
                              ? null
                              : Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
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