import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model chứa 1 dòng lyrics gồm thời gian và text
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
  bool get hasAnyLyrics => isSynced || (plainLyrics != null && plainLyrics!.isNotEmpty);
}

class LyricsService {
  static const _baseUrl = 'https://lrclib.net/api';

  // Sửa cache lại thành chứa LyricsData
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
      final cleanTitle = title.replaceAll(RegExp(r'\(.*\)'), '').trim();
      final query = artist.trim().isEmpty ? cleanTitle : '$cleanTitle $artist';

      final url = Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': query});
      debugPrint('[LyricsService] Fetching: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);

        if (body.isNotEmpty) {
          for (var item in body) {
            final syncedRaw = item['syncedLyrics'] as String?;
            final plainRaw = item['plainLyrics'] as String?;

            // Ưu tiên trả về synced lyrics nếu có
            if (syncedRaw != null && syncedRaw.trim().isNotEmpty) {
              debugPrint('[LyricsService] ✅ Found SYNCED lyrics for "$title"');
              return LyricsData(
                syncedLyrics: _parseLrc(syncedRaw),
                plainLyrics: plainRaw,
              );
            } 
            // Nếu không có synced, trả về plain
            else if (plainRaw != null && plainRaw.trim().isNotEmpty) {
              debugPrint('[LyricsService] ✅ Found PLAIN lyrics for "$title"');
              return LyricsData(plainLyrics: _cleanLyrics(plainRaw));
            }
          }
        }
      }

      debugPrint('[LyricsService] ❌ No lyrics for "$artist - $title" (${response.statusCode})');
      return null;
    } catch (e) {
      debugPrint('[LyricsService] ❌ Error: $e');
      return null;
    }
  }

  /// Hàm parse định dạng LRC [mm:ss.xx]
  List<LyricLine> _parseLrc(String lrc) {
    final lines = lrc.split('\n');
    final List<LyricLine> result = [];
    
    // Regex bắt [00:15.22] hoặc [00:15.222]
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        
        // Cắt string miliseconds cho chuẩn xác (phòng trường hợp 2 hoặc 3 số)
        String msStr = match.group(3)!;
        if (msStr.length == 2) msStr += '0'; 
        final milliseconds = int.parse(msStr);
        
        final text = match.group(4)!.trim();

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        result.add(LyricLine(time: duration, text: text));
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