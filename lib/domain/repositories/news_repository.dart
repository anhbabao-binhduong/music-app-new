import '../entities/news_article_entity.dart';

abstract class NewsRepository {
  Future<List<NewsArticleEntity>> fetchNews({String? source});
}