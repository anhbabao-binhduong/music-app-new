import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

void main() async {
  final rssSources = {
    'VnExpress': 'https://vnexpress.net/rss/giai-tri.rss',
    'Kenh14': 'https://kenh14.vn/am-nhac.rss',
    'Zing News': 'https://zingnews.vn/am-nhac.rss',
    'Thanh Niên': 'https://thanhnien.vn/rss/giai-tri.rss',
  };

  for (final entry in rssSources.entries) {
    print('Fetching from ${entry.key}...');
    try {
      final response = await http.get(Uri.parse(entry.value));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        print(' - Found ${items.length} items');
        
        if (items.isNotEmpty) {
          final item = items.first;
          final title = item.findElements('title').firstOrNull?.innerText ?? 'No title';
          print(' - First item: $title');
          
          // Debug image logic
          String? imageUrl;
          final descriptionHtml = item.findElements('description').firstOrNull?.innerText ?? '';
          
          try {
            imageUrl = item.findElements('enclosure').firstOrNull?.getAttribute('url');
          } catch (_) {}
          
          if (imageUrl == null) {
            imageUrl = item.findElements('media:content').firstOrNull?.getAttribute('url');
          }
          
          if (imageUrl == null && descriptionHtml.isNotEmpty) {
            final RegExp regExp = RegExp(r'<img[^>]+src="([^">]+)"');
            final match = regExp.firstMatch(descriptionHtml);
            if (match != null && match.groupCount >= 1) {
              imageUrl = match.group(1);
            }
          }
          print(' - Image URL: $imageUrl');
        }
      } else {
        print(' - Failed: ${response.statusCode}');
      }
    } catch (e) {
      print(' - Error: $e');
    }
    print('');
  }
}