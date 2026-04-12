import 'package:equatable/equatable.dart';
import '../../../domain/entities/chart_top_song.dart';
import '../../../domain/entities/chart_trend_point.dart';

enum ChartFilter { today, week, month }

abstract class ChartState extends Equatable {
  final ChartFilter filter;

  const ChartState(this.filter);

  @override
  List<Object?> get props => [filter];
}

class ChartLoading extends ChartState {
  const ChartLoading(super.filter);
}

class ChartLoaded extends ChartState {
  final List<ChartTopSong> topSongs;
  final List<ChartTrendPoint> trends;

  const ChartLoaded({
    required ChartFilter filter,
    required this.topSongs,
    required this.trends,
  }) : super(filter);

  @override
  List<Object?> get props => [filter, topSongs, trends];
}

class ChartError extends ChartState {
  final String message;

  const ChartError(super.filter, this.message);

  @override
  List<Object?> get props => [filter, message];
}
