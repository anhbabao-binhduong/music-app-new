import '../entities/news_article_entity.dart';
import '../repositories/news_repository.dart';

class FetchNewsUsecase {
  final NewsRepository repository;
  FetchNewsUsecase(this.repository);

  Future<List<NewsArticleEntity>> call({String? source}) =>
      repository.fetchNews(source: source);
}