import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../domain/entities/news_article_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../models/news_article_model.dart';

class NewsRepositoryImpl implements NewsRepository {
  /// Map nguồn RSS âm nhạc / giải trí Việt N+am
  static const Map<String, String> rssSources = {
    'VnExpress': 'https://vnexpress.net/rss/giai-tri.rss',
    'Kenh14': 'https://kenh14.vn/star.rss',
    'Zing News': 'https://znews.vn/rss/giai-tri.rss',
    'Thanh Niên': 'https://thanhnien.vn/rss/giai-tri.rss',
  };

  @override
  Future<List<NewsArticleEntity>> fetchNews({String? source}) async {
    print('[REPO] fetchNews called, source: $source');
    if (source != null && rssSources.containsKey(source)) {
      return _fetchFromUrl(rssSources[source]!, source);
    }

    // Fetch from all sources
    final List<NewsArticleEntity> allArticles = [];
    for (final entry in rssSources.entries) {
      try {
        print('[RSS] Fetching ${entry.key}...');
        final articles = await _fetchFromUrl(entry.value, entry.key);
        print('[RSS] Done ${entry.key}: ${articles.length} items');
        allArticles.addAll(articles);
      } catch (e, stackTrace) {
        print('[RSS ERROR] ${entry.key}: $e');
        print(stackTrace);
      }
    }

    // Sort by pubDate descending (newest first)
    allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return allArticles;
  }

  Future<List<NewsArticleEntity>> _fetchFromUrl(
    String url,
    String sourceName,
  ) async {
    final response = await http.get(
      Uri.parse(url),
    ).timeout(Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load RSS from $url');
    }

    final xmlString = utf8.decode(response.bodyBytes);
    print('[$sourceName] Raw XML length: ${xmlString.length}');
    print('[$sourceName] Raw XML preview: ${xmlString.substring(0, xmlString.length.clamp(0, 300))}');

    final articles = NewsArticleModel.parseRssFeed(xmlString, sourceName);
    print('[$sourceName] Items count: ${articles.length}');
    return articles;
  }
}