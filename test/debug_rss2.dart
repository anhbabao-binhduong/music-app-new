import 'package:http/http.dart' as http;

void main() async {
  final urls = {
    'kenh14/music.rss': 'https://kenh14.vn/music.rss',
    'kenh14/star.rss': 'https://kenh14.vn/star.rss',
    'kenh14/rss/home.rss': 'https://kenh14.vn/rss/home.rss',
    'zingnews/giai-tri.rss': 'https://zingnews.vn/giai-tri.rss',
    'zingnews/rss/giai-tri.rss': 'https://zingnews.vn/rss/giai-tri.rss',
    'znews/am-nhac.rss': 'https://znews.vn/am-nhac.rss',
  };

  for (final entry in urls.entries) {
    try {
      final r = await http.get(Uri.parse(entry.value));
      print('${entry.key} => ${r.statusCode}');
    } catch (e) {
      print('${entry.key} => ERROR: $e');
    }
  }
}