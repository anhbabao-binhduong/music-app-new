import 'dart:convert';

import 'package:music_app/data/models/news_article_model.dart';
import 'package:http/http.dart' as http;

Future<void> checkSource(String source, String url) async {
  final response = await http.get(Uri.parse(url));
  final xmlString = utf8.decode(response.bodyBytes);
  final articles = NewsArticleModel.parseRssFeed(xmlString, source);

  print('$source => ${response.statusCode}');
  if (articles.isNotEmpty) {
    print('TITLE: ${articles.first.title}');
    print('DESC: ${articles.first.description}');
  }
  print('');
}

Future<void> main() async {
  await checkSource('Zing News', 'https://znews.vn/rss/giai-tri.rss');
  await checkSource('Thanh Niên', 'https://thanhnien.vn/rss/giai-tri.rss');
}