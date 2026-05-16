import 'package:xml/xml.dart';
import '../../domain/entities/news_article_entity.dart';

class NewsArticleModel extends NewsArticleEntity {
  const NewsArticleModel({
    required super.title,
    required super.link,
    required super.pubDate,
    super.imageUrl,
    super.description,
    required super.source,
  });

  static List<NewsArticleEntity> parseRssFeed(
      String xmlString, String sourceName) {
    final document = XmlDocument.parse(xmlString);
    final items = document.findAllElements('item');
    return items.map((item) {
      final title = _decodeHtml(
        item.findElements('title').firstOrNull?.innerText ?? '',
      );
      final link = item.findElements('link').firstOrNull?.innerText ?? '';
      final pubDate =
          item.findElements('pubDate').firstOrNull?.innerText ?? '';
      final description = _decodeHtml(
        item.findElements('description').firstOrNull?.innerText ?? '',
      );

      String imageUrl = '';

      // 1. Try <enclosure url="..."/>
      final enclosure = item.findElements('enclosure').firstOrNull;
      if (enclosure != null) {
        imageUrl = enclosure.getAttribute('url') ?? '';
      }

      // 2. Try <media:content url="..."/>
      if (imageUrl.isEmpty) {
        final mediaContent =
            item.findAllElements('media:content').firstOrNull;
        imageUrl = mediaContent?.getAttribute('url') ?? '';
      }

      // 3. Try extracting <img src="..."> from description HTML
      if (imageUrl.isEmpty) {
        final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
        final imgMatch = imgRegex.firstMatch(description);
        imageUrl = imgMatch?.group(1) ?? '';
      }

      return NewsArticleModel(
        title: title,
        link: link,
        description: _decodeHtml(_stripHtml(description)),
        imageUrl: imageUrl,
        pubDate: pubDate,
        source: sourceName,
      );
    }).where((a) => a.title.isNotEmpty).toList();
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
  }

  static String _decodeHtml(String text) {
    return text
        .replaceAll('&' 'amp;', '&')
        .replaceAll('&' 'lt;', '<')
        .replaceAll('&' 'gt;', '>')
        .replaceAll('&' 'quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&' 'agrave;', 'à')
        .replaceAll('&' 'aacute;', 'á')
        .replaceAll('&' 'atilde;', 'ã')
        .replaceAll('&' 'acirc;', 'â')
        .replaceAll('&' 'eacute;', 'é')
        .replaceAll('&' 'egrave;', 'è')
        .replaceAll('&' 'ecirc;', 'ê')
        .replaceAll('&' 'iacute;', 'í')
        .replaceAll('&' 'igrave;', 'ì')
        .replaceAll('&' 'ocirc;', 'ô')
        .replaceAll('&' 'oacute;', 'ó')
        .replaceAll('&' 'ograve;', 'ò')
        .replaceAll('&' 'uacute;', 'ú')
        .replaceAll('&' 'ugrave;', 'ù')
        .replaceAll('&' 'ccedil;', 'ç');
  }
}