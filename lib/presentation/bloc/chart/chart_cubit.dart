import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/music_repository.dart';
import 'chart_state.dart';

class ChartCubit extends Cubit<ChartState> {
  final MusicRepository repository;

  ChartCubit(this.repository) : super(const ChartLoading(ChartFilter.today)) {
    loadChart(ChartFilter.today);
  }

  Future<void> loadChart(ChartFilter filter) async {
    emit(ChartLoading(filter));

    int daysAgo = 1;
    if (filter == ChartFilter.week) daysAgo = 7;
    if (filter == ChartFilter.month) daysAgo = 30;

    final topSongsRes = await repository.getChartTopSongs(daysAgo);
    final topSongs = topSongsRes.fold((l) => null, (r) => r);

    if (topSongs == null) {
      emit(ChartError(filter, 'Failed to load top songs.'));
      return;
    }

    // Lấy đúng danh sách song_id từ top songs để truyền vào trends
    final songIds = topSongs.take(3).map((s) => s.song.id).toList();

    final trendsRes = await repository.getChartTrends(daysAgo, songIds);
    final trends = trendsRes.fold((l) => null, (r) => r);

    if (trends == null) {
      emit(ChartError(filter, 'Failed to load chart trends.'));
      return;
    }

    emit(ChartLoaded(
      filter: filter,
      topSongs: topSongs,
      trends: trends,
    ));
  }
}
