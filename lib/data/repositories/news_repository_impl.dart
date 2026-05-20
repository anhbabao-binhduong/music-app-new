import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/news_article_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../models/news_article_model.dart';

class NewsRepositoryImpl implements NewsRepository {
  /// Giữ lại danh sách nguồn để UI đang dùng filter (nếu có).
  /// Backend Flask hiện trả về aggregate nhiều nguồn trong /api/news.
  static const Map<String, String> rssSources = {
    'VnExpress': 'https://vnexpress.net/rss/tin-moi-nhat.rss',
    'Thanh Niên': 'https://thanhnien.vn/rss/home.rss',
    'Tuổi Trẻ': 'https://tuoitre.vn/rss/tin-moi-nhat.rss',
  };

  static String get _backendBaseUrl {
    // Backend Flask (app.py) chạy port 5000.
    // - Web/Windows/macOS/Linux: dùng localhost
    // - Android emulator: localhost của emulator != localhost máy => dùng 10.0.2.2
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  @override
  Future<List<NewsArticleEntity>> fetchNews({String? source}) async {
    // Backend hiện chưa filter theo source, nên tạm ignore `source`.
    final uri = Uri.parse('$_backendBaseUrl/api/news');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load news from backend: ${response.statusCode}',
      );
    }

    final jsonMap = json.decode(utf8.decode(response.bodyBytes));
    final articles = (jsonMap is Map<String, dynamic>)
        ? (jsonMap['articles'] as List? ?? const [])
        : const [];

    return articles
        .whereType<Map>()
        .map((e) => NewsArticleModel.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.title.isNotEmpty)
        .toList();
  }
}