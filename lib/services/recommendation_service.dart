import 'package:music_app/domain/entities/song_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationResult {
  final List<SongEntity> songs;
  final bool hasPreferences;

  const RecommendationResult({
    required this.songs,
    required this.hasPreferences,
  });
}

class RecommendationService {
  RecommendationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<RecommendationResult> getRecommendedSongs() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      final songs = await _fetchLatestSongs();
      return RecommendationResult(songs: songs, hasPreferences: false);
    }

    final profile = await _supabase
        .from('profiles')
        .select('favorite_genres, listening_moods')
        .eq('id', user.id)
        .single();

    final genres = List<String>.from(profile['favorite_genres'] ?? []);
    final moods = List<String>.from(profile['listening_moods'] ?? []);

    // Debug: what is actually stored in profiles

    if (genres.isEmpty && moods.isEmpty) {
      final songs = await _fetchLatestSongs();
      return RecommendationResult(songs: songs, hasPreferences: false);
    }

    // NOTE: Postgres array overlap (ov) is case-sensitive.
    // The UI stores genres like "Pop", "Lo-fi" and moods like "🎧 Thư giãn",
    // while the songs table may store normalized values like "pop", "relax", etc.
    // To avoid empty results, we fetch a larger set and match locally with normalization.
    final prefGenreTokens = _expandGenreTokens(genres);
    final prefMoodTokens = _expandMoodTokens(moods);

    try {
      final response = await _supabase
          .from('songs')
          .select(
              'id, title, artist, album, art_url, audio_path, duration_seconds, genres, moods')
          .order('id', ascending: false)
          .limit(200);

      final rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Debug: what is coming back from songs query

      final matched = <SongEntity>[];
      for (final row in rows) {
        final songGenreTokens = _extractSongTokens(row['genres']);
        final songMoodTokens = _extractSongTokens(row['moods']);

        final genreMatch = songGenreTokens.any(prefGenreTokens.contains);
        final moodMatch = songMoodTokens.any(prefMoodTokens.contains);

        if (genreMatch || moodMatch) {
          matched.add(_mapSong(row));
        }
      }

      if (matched.isEmpty) {
        // Preferences exist but no matches due to data mismatch -> show latest instead of blank.
        final fallback = await _fetchLatestSongs();
        return RecommendationResult(songs: fallback, hasPreferences: true);
      }

      return RecommendationResult(
        songs: matched.take(20).toList(),
        hasPreferences: true,
      );
    } catch (e) {
      // Debug: catch RLS / query errors
      final fallback = await _fetchLatestSongs();
      return RecommendationResult(songs: fallback, hasPreferences: true);
    }
  }

  Set<String> _extractSongTokens(dynamic raw) {
    if (raw is! List) return const <String>{};
    return raw
        .map((e) => _compactToken(e?.toString() ?? ''))
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  Set<String> _expandGenreTokens(List<String> genres) {
    final tokens = <String>{};
    for (final g in genres) {
      tokens.addAll(_genreSynonyms(g));
    }
    return tokens;
  }

  Set<String> _expandMoodTokens(List<String> moods) {
    final tokens = <String>{};
    for (final m in moods) {
      tokens.addAll(_moodSynonyms(m));
    }
    return tokens;
  }

  Set<String> _genreSynonyms(String genre) {
    final raw = genre.trim();
    final key = _compactToken(raw);

    switch (key) {
      case 'lofi':
        return {'lofi', 'lo-fi', 'chill'};
      case 'vpop':
        return {'vpop', 'v-pop'};
      case 'rb':
      case 'rnb':
        return {'rb', 'r&b', 'rnb'};
      case 'hiphop':
        return {'hiphop', 'hip-hop'};
      default:
        if (key.isEmpty) return const <String>{};
        return {key};
    }
  }

  Set<String> _moodSynonyms(String mood) {
    // UI moods are like "🎧 Thư giãn" – strip the emoji prefix first.
    final raw = _stripLeadingEmojiToken(mood);
    final key = _compactToken(raw);

    switch (key) {
      case 'thugian':
        return {'thugian', 'relax', 'chill'};
      case 'tapluyen':
        return {'tapluyen', 'workout', 'gym'};
      case 'hoctap':
        return {'hoctap', 'study'};
      case 'dichuyen':
        return {'dichuyen', 'move', 'travel', 'commute'};
      case 'tiectung':
        return {'tiectung', 'party'};
      case 'truockhingu':
        return {'truockhingu', 'sleep'};
      case 'lamviec':
        return {'lamviec', 'work', 'focus'};
      case 'langman':
        return {'langman', 'romance', 'romantic'};
      default:
        if (key.isEmpty) return const <String>{};
        return {key};
    }
  }

  String _stripLeadingEmojiToken(String input) {
    final trimmed = input.trim();
    final firstSpace = trimmed.indexOf(' ');
    if (firstSpace <= 0) return trimmed;

    // Heuristic: if the first token is an emoji/symbol, drop it.
    final firstToken = trimmed.substring(0, firstSpace);
    if (firstToken.runes.length <= 3) {
      return trimmed.substring(firstSpace + 1).trim();
    }
    return trimmed;
  }

  String _compactToken(String input) {
    final lower = input.trim().toLowerCase();
    // Keep letters/numbers only, remove spaces/punctuation/hyphens, etc.
    return lower.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
  }

  Future<List<SongEntity>> _fetchLatestSongs() async {
    final response = await _supabase
        .from('songs')
        .select()
        .order('id', ascending: false)
        .limit(20);

    return (response as List)
        .map((json) => _mapSong(Map<String, dynamic>.from(json)))
        .toList();
  }

  SongEntity _mapSong(Map<String, dynamic> json) {
    return SongEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      album: json['album']?.toString() ?? '',
      artUrl: json['art_url']?.toString(),
      audioUrl: json['audio_path']?.toString(),
      durationMs: _secondsToMs(json['duration_seconds']),
    );
  }

  int _secondsToMs(dynamic value) {
    if (value is num) return value.toInt() * 1000;
    final seconds = int.tryParse(value?.toString() ?? '') ?? 0;
    return seconds * 1000;
  }
}