class ChartTrendPoint {
  final String songId;
  final String dateLabel; // raw string from DB e.g. "2026-04-11 08:00" or "2026-04-11"
  final int playCount;

  const ChartTrendPoint({
    required this.songId,
    required this.dateLabel,
    required this.playCount,
  });
}
