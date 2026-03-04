import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../domain/entities/song_entity.dart';
import '../../../domain/repositories/music_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final MusicRepository _repository;

  // BehaviorSubject acts as the debounce input stream
  final _querySubject = BehaviorSubject<String>();
  StreamSubscription? _searchSub;

  // In-memory song pool to search against
  // In a real app, inject a remote datasource here too
  List<SongEntity> _allSongs = [];

  SearchCubit(this._repository) : super(const SearchInitial()) {
    _initDebounce();
  }

  void _initDebounce() {
    _searchSub = _querySubject
        .distinct()                              // skip identical consecutive queries
        .debounceTime(const Duration(milliseconds: 350))  // wait 350ms after last keystroke
        .switchMap((query) => _performSearch(query))      // cancel in-flight on new query
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
      final favResult  = await _repository.getFavorites();
      final histResult = await _repository.getHistory(limit: 100);

      final pool = <SongEntity>{};
      favResult.fold( (_) {}, (songs) => pool.addAll(songs));
      histResult.fold((_) {}, (songs) => pool.addAll(songs));
      pool.addAll(_allSongs);

      final q = query.toLowerCase();
      final matched = pool.where((s) =>
          s.title.toLowerCase().contains(q)  ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q)
      ).toList();

      if (matched.isEmpty) {
        yield SearchEmpty(query);
      } else {
        yield SearchSuccess(matched, query);
      }
    } catch (e) {
      yield SearchError('Search failed: $e');
    }
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