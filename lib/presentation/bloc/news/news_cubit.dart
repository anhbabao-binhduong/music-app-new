import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/fetch_news_usecase.dart';
import 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final FetchNewsUsecase fetchNewsUsecase;

  NewsCubit({required this.fetchNewsUsecase}) : super(const NewsInitial());

  Future<void> loadNews({String? source}) async {
    print('[Cubit] fetchNews called, source: $source');
    emit(const NewsLoading());
    try {
      final articles = await fetchNewsUsecase(source: source);
      print('[Cubit] Total articles: ${articles.length}');
      emit(NewsLoaded(articles: articles, activeSource: source));
    } catch (e) {
      print('[Cubit] Error: $e');
      emit(NewsError('Không thể tải tin tức. Vui lòng thử lại sau.'));
    }
  }
}