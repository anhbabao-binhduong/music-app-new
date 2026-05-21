import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain/entities/song_entity.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../../services/lyrics_service.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final MusicRepository _repository;
  final LyricsService _lyricsService;

  // BehaviorSubject acts as the debounce input stream
  final _querySubject = BehaviorSubject<String>();
  StreamSubscription? _searchSub;

  // In-memory song pool to search against
  // In a real app, inject a remote datasource here too
  List<SongEntity> _allSongs = [];

  // Cache lyrics plain text per "artist||title" to avoid repeated API calls.
  final Map<String, String> _lyricsPlainCache = {};

  SearchCubit(this._repository, this._lyricsService)
      : super(const SearchInitial()) {
    _initDebounce();
  }

  void _initDebounce() {
    _searchSub = _querySubject
        .distinct() // skip identical consecutive queries
        .debounceTime(
            const Duration(milliseconds: 350)) // wait 350ms after last keystroke
        .switchMap((query) =>
            _performSearch(query)) // cancel in-flight on new query
        .listen(
          (state) => emit(state),
          onError: (e) => emit(SearchError(e.toString())),
        );
  }

  /// Call this from the UI's TextField.onChanged
  void onQueryChanged(String query) {
    if (query.trim().isEmpty) {
      emit(const SearchInitial());
      return;
    }
    emit(const SearchLoading()); // immediate feedback
    _querySubject.add(query.trim());
  }

  Stream<SearchState> _performSearch(String query) async* {
    try {
      // Search favorites + history as local corpus
      final favResult = await _repository.getFavorites();
      final histResult = await _repository.getHistory(limit: 100);

      final pool = <SongEntity>{};
      favResult.fold((_) {}, (songs) => pool.addAll(songs));
      histResult.fold((_) {}, (songs) => pool.addAll(songs));
      pool.addAll(_allSongs);

      final q = query.toLowerCase();

      // 1) Fast metadata match (title/artist/album)
      final metaMatched = pool
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q))
          .toList();

      // 2) Lyrics match (when user types/pastes lyrics)
      // Heuristic: lyrics queries usually have spaces and are not too short.
      final shouldTryLyrics = _shouldTryLyricsSearch(query, metaMatchedCount: metaMatched.length);

      if (!shouldTryLyrics) {
        if (metaMatched.isEmpty) {
          yield SearchEmpty(query);
        } else {
          yield SearchSuccess(metaMatched, query);
        }
        return;
      }

      // Try lyrics search against a limited candidate set to keep it responsive.
      final candidates = _pickLyricsCandidates(
        pool: pool,
        metaMatched: metaMatched,
      );

      final lyricMatched = <SongEntity>[];
      for (final song in candidates) {
        final plain = await _getPlainLyricsCached(song);
        if (plain == null || plain.isEmpty) continue;

        if (plain.toLowerCase().contains(q)) {
          lyricMatched.add(song);
        }
      }

      final merged = <SongEntity>{
        ...metaMatched,
        ...lyricMatched,
      }.toList();

      if (merged.isEmpty) {
        yield SearchEmpty(query);
      } else {
        yield SearchSuccess(merged, query);
      }
    } catch (e) {
      yield SearchError('Search failed: $e');
    }
  }

  bool _shouldTryLyricsSearch(String query, {required int metaMatchedCount}) {
    final q = query.trim();
    if (q.length < 4) return false;

    // If metadata already returns many hits, avoid extra network calls.
    if (metaMatchedCount >= 15) return false;

    // Typical lyric fragments contain spaces.
    if (!q.contains(' ')) return false;

    return true;
  }

  List<SongEntity> _pickLyricsCandidates({
    required Set<SongEntity> pool,
    required List<SongEntity> metaMatched,
  }) {
    // Prefer meta matched (most likely), then fill from pool up to a cap.
    const cap = 30;

    final result = <SongEntity>[];
    for (final s in metaMatched) {
      if (result.length >= cap) break;
      result.add(s);
    }

    if (result.length >= cap) return result;

    for (final s in pool) {
      if (result.length >= cap) break;
      if (result.any((e) => e.id == s.id)) continue;
      result.add(s);
    }

    return result;
  }

  Future<String?> _getPlainLyricsCached(SongEntity song) async {
    final key = '${song.artist.toLowerCase()}||${song.title.toLowerCase()}';
    if (_lyricsPlainCache.containsKey(key)) {
      return _lyricsPlainCache[key];
    }

    // Fetch lyrics from lrclib (already used in LyricsPage).
    final data = await _lyricsService.getLyrics(
      artist: song.artist,
      title: song.title,
    );

    final plain = (data?.plainLyrics ?? '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (plain.isNotEmpty) {
      _lyricsPlainCache[key] = plain;
    } else {
      _lyricsPlainCache[key] = '';
    }

    return _lyricsPlainCache[key];
  }

  /// Pre-load a batch of songs into the search pool
  void loadSongPool(List<SongEntity> songs) {
    _allSongs = songs;
  }

  void clearSearch() {
    _querySubject.add('');
    emit(const SearchInitial());
  }

  @override
  Future<void> close() {
    _searchSub?.cancel();
    _querySubject.close();
    return super.close();
  }
}
