import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LyricLine {
  final Duration time;
  final String text;
  LyricLine({required this.time, required this.text});
}
/// Model chứa kết quả trả về: có thể là synced (karaoke) hoặc plain (tĩnh)
class LyricsData {
  final List<LyricLine>? syncedLyrics;
  final String? plainLyrics;

  LyricsData({this.syncedLyrics, this.plainLyrics});

  bool get isSynced => syncedLyrics != null && syncedLyrics!.isNotEmpty;
  bool get hasAnyLyrics =>
      isSynced || (plainLyrics != null && plainLyrics!.isNotEmpty);
}

class LyricsService {
  static const _baseUrl = 'https://lrclib.net/api';

  final Map<String, LyricsData?> _cache = {};

  // ── Public API ─────────────────────────────────────────────

  Future<LyricsData?> getLyrics({
    required String artist,
    required String title,
  }) async {
    final cleanArtist = _cleanArtist(artist);
    final cacheKey = '${cleanArtist.toLowerCase()}||${title.toLowerCase()}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final data = await _fetchFromApi(artist: cleanArtist, title: title);
    _cache[cacheKey] = data;
    return data;
  }

  void clearCache() => _cache.clear();

  // ── Private ────────────────────────────────────────────────

  Future<LyricsData?> _fetchFromApi({
    required String artist,
    required String title,
  }) async {
    try {
      final cleanTitle =
          title.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
      final cleanArt = artist.trim();

      final getResult =
          await _tryGetEndpoint(artist: cleanArt, title: cleanTitle);
      if (getResult != null) return getResult;

      return await _trySearchEndpoint(artist: cleanArt, title: cleanTitle);
    } catch (e) {
      debugPrint('[LyricsService] ❌ Error: $e');
      return null;
    }
  }

  Future<LyricsData?> _tryGetEndpoint({
    required String artist,
    required String title,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/get').replace(queryParameters: {
        'artist_name': artist,
        'track_name': title,
      });
      debugPrint('[LyricsService] GET: $url');

      final response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final item = json.decode(response.body);
        return _extractLyricsData(item, title);
      }
    } catch (_) {}
    return null;
  }

  Future<LyricsData?> _trySearchEndpoint({
    required String artist,
    required String title,
  }) async {
    try {
      final queries =
          artist.isNotEmpty ? ['$artist $title', title] : [title];

      for (final q in queries) {
        final url = Uri.parse('$_baseUrl/search')
            .replace(queryParameters: {'q': q});
        debugPrint('[LyricsService] SEARCH: $url');

        final response =
            await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;

        final List<dynamic> body = json.decode(response.body);
        if (body.isEmpty) continue;

        final scored = body
            .map((item) => (
                  item: item,
                  score: _scoreMatch(item, artist: artist, title: title),
                ))
            .where((e) => e.score > 0)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        for (final entry in scored) {
          final data = _extractLyricsData(entry.item, title);
          if (data != null) {
            debugPrint(
                '[LyricsService] ✅ score=${entry.score} "${entry.item['trackName']}"');
            return data;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  int _scoreMatch(dynamic item,
      {required String artist, required String title}) {
    final trackName = (item['trackName'] as String? ?? '').toLowerCase();
    final artistName = (item['artistName'] as String? ?? '').toLowerCase();
    final tLower = title.toLowerCase();
    final aLower = artist.toLowerCase();

    int score = 0;
    if (trackName == tLower) {
      score += 100;
    } else if (trackName.contains(tLower) || tLower.contains(trackName)) {
      score += 50;
    } else {
      return 0;
    }

    if (aLower.isNotEmpty) {
      if (artistName == aLower) {
        score += 50;
      } else if (artistName.contains(aLower) || aLower.contains(artistName)) {
        score += 20;
      }
    }

    if (item['syncedLyrics'] != null) score += 30;
    if (item['plainLyrics'] != null) score += 10;

    return score;
  }

  LyricsData? _extractLyricsData(dynamic item, String title) {
    final syncedRaw = item['syncedLyrics'] as String?;
    final plainRaw = item['plainLyrics'] as String?;

    if (syncedRaw != null && syncedRaw.trim().isNotEmpty) {
      debugPrint('[LyricsService] ✅ SYNCED "$title"');
      return LyricsData(
        syncedLyrics: _parseLrc(syncedRaw),
        plainLyrics: plainRaw,
      );
    }
    if (plainRaw != null && plainRaw.trim().isNotEmpty) {
      debugPrint('[LyricsService] ✅ PLAIN "$title"');
      return LyricsData(plainLyrics: _cleanLyrics(plainRaw));
    }
    return null;
  }

  List<LyricLine> _parseLrc(String lrc) {
    final lines = lrc.split('\n');
    final List<LyricLine> result = [];

    // Đọc [offset:xxx] nếu có
    int offsetMs = 0;
    final offsetRegex =
        RegExp(r'\[offset:\s*(-?\d+)\]', caseSensitive: false);
    for (final line in lines) {
      final m = offsetRegex.firstMatch(line.trim());
      if (m != null) {
        offsetMs = int.parse(m.group(1)!);
        break;
      }
    }

    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);

        String msStr = match.group(3)!;
        if (msStr.length == 2) msStr += '0';
        final milliseconds = int.parse(msStr);

        final text = match.group(4)!.trim();

        final rawMs = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        ).inMilliseconds;

        final adjustedMs =
            (rawMs + offsetMs).clamp(0, double.maxFinite.toInt());

        result.add(LyricLine(
          time: Duration(milliseconds: adjustedMs),
          text: text,
        ));
      }
    }
    return result;
  }

  String _cleanArtist(String artist) {
    if (artist.toLowerCase() == 'unknown') return '';
    return artist;
  }

  String _cleanLyrics(String raw) {
    return raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }
}