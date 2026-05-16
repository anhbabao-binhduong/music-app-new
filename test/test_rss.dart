import 'package:http/http.dart' as http;

Future<http.Response> sendRequest(
  http.Client client,
  String url, {
  Map<String, String>? headers,
  bool followRedirects = false,
}) async {
  final request = http.Request('GET', Uri.parse(url))
    ..followRedirects = followRedirects;

  if (headers != null) {
    request.headers.addAll(headers);
  }

  final streamed = await client.send(request);
  return http.Response.fromStream(streamed);
}

String previewBody(String body) {
  if (body.isEmpty) return '';
  final normalized = body.replaceAll('\n', ' ').replaceAll('\r', ' ');
  return normalized.length <= 100
      ? normalized
      : normalized.substring(0, 100);
}

Future<void> testUrl(http.Client client, String source, String url) async {
  try {
    var response = await sendRequest(client, url);

    print('$source: ${response.statusCode} — ${previewBody(response.body)}');

    if (response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      print('$source redirect location: $redirectUrl');

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        final resolvedUrl = Uri.parse(url).resolve(redirectUrl).toString();
        response = await sendRequest(client, resolvedUrl);
        print(
          '$source after redirect ($resolvedUrl): ${response.statusCode} — ${previewBody(response.body)}',
        );
      }
    } else if (response.statusCode == 403) {
      response = await sendRequest(
        client,
        url,
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      print(
        '$source with User-Agent: ${response.statusCode} — ${previewBody(response.body)}',
      );
    }
  } catch (e) {
    print('$source: ERROR — $e');
  }

  print('');
}

Future<void> main() async {
  final urls = {
    'Kenh14': 'https://kenh14.vn/star.rss',
    'Zing News': 'https://zingnews.vn/rss/giai-tri.rss',
    'Thanh Nien': 'https://thanhnien.vn/rss/giai-tri.rss',
  };

  final client = http.Client();
  try {
    for (final entry in urls.entries) {
      await testUrl(client, entry.key, entry.value);
    }
  } finally {
    client.close();
  }
}