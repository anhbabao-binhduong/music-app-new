import 'song_entity.dart';

enum ChartTrend { up, down, same }

class ChartTopSong {
  final SongEntity song;
  final int playCount;
  final ChartTrend trend;

  const ChartTopSong({
    required this.song,
    required this.playCount,
    this.trend = ChartTrend.same,
  });
}
