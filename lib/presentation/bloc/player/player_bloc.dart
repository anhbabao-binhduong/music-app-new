import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'player_event.dart';
import 'player_state.dart';
import 'package:flutter/foundation.dart';
import 'package:music_app/core/constants/hive_constants.dart';
import 'package:music_app/presentation/bloc/history/history_cubit.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioHandler _audioHandler;
  final HistoryCubit _historyCubit;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _mediaSubscription;

  PlayerBloc(this._audioHandler, this._historyCubit) : super(const PlayerInitial()) {
    on<LoadPlaylistEvent>(_onLoadPlaylist);
    on<PlayEvent>((event, emit) => _audioHandler.play());
    on<PauseEvent>((event, emit) => _audioHandler.pause());
    on<NextEvent>((event, emit) => _audioHandler.skipToNext());
    on<PreviousEvent>((event, emit) => _audioHandler.skipToPrevious());
    on<SeekEvent>((event, emit) => _audioHandler.seek(event.position));
    on<SkipToIndexEvent>(
        (event, emit) => _audioHandler.skipToQueueItem(event.index));
    on<PlayNextEvent>(_onPlayNext);
    on<InternalUpdateEvent>(_onInternalUpdate);
    on<RemoveFromQueueEvent>(_onRemoveFromQueue);
    on<PrioritizeSongEvent>(_onPrioritizeSong);
    on<ResetPlayerEvent>(_onResetPlayer);
    on<RestoreQueueEvent>(_onRestoreQueue);
    on<ToggleShuffleEvent>((event, emit) => _audioHandler.setShuffleMode(
        _audioHandler.playbackState.value.shuffleMode == AudioServiceShuffleMode.none
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none));
    on<CycleRepeatEvent>((event, emit) {
      final current = _audioHandler.playbackState.value.repeatMode;
      final next = current == AudioServiceRepeatMode.none
          ? AudioServiceRepeatMode.all
          : current == AudioServiceRepeatMode.all
              ? AudioServiceRepeatMode.one
              : AudioServiceRepeatMode.none;
      _audioHandler.setRepeatMode(next);
    });

    _playerSubscription = _audioHandler.playbackState
        .listen((_) => add(const InternalUpdateEvent()));
    _mediaSubscription = _audioHandler.mediaItem
        .listen((_) => add(const InternalUpdateEvent()));
  }

  // ─── Helper: lấy settings box ───────────────────────────────────────────────
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(HiveBoxes.settings);

  // ─── Helper: lưu queue vào Hive theo userId ─────────────────────────────────
  Future<void> _persistQueue(String userId) async {
    try {
      final queue = _audioHandler.queue.value;
      final currentItem = _audioHandler.mediaItem.value;
      final currentIndex = currentItem != null
          ? queue.indexWhere((i) => i.id == currentItem.id)
          : 0;

      final queueJson = queue.map((item) => {
        'id': item.id,
        'title': item.title,
        'artist': item.artist ?? '',
        'album': item.album ?? '',
        'artUri': item.artUri?.toString() ?? '',
        'duration': item.duration?.inMilliseconds ?? 0,
        'extras': item.extras ?? {},
      }).toList();

      await _settingsBox.put(
          '${HiveSettingsKeys.queuePrefix}$userId', jsonEncode(queueJson));
      await _settingsBox.put(
          '${HiveSettingsKeys.queueIndexPrefix}$userId',
          currentIndex < 0 ? 0 : currentIndex);
    } catch (e) {
      if (kDebugMode) print('Persist queue error: $e');
    }
  }

  // ─── Helper: đọc queue từ Hive theo userId ──────────────────────────────────
  Future<({List<MediaItem> queue, int index})> _loadPersistedQueue(
      String userId) async {
    try {
      final raw =
          _settingsBox.get('${HiveSettingsKeys.queuePrefix}$userId');
      final savedIndex = (_settingsBox.get(
              '${HiveSettingsKeys.queueIndexPrefix}$userId',
              defaultValue: 0) as num)
          .toInt();

      if (raw == null) return (queue: <MediaItem>[], index: 0);

      final List decoded = jsonDecode(raw as String);
      final queue = decoded.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return MediaItem(
          id: map['id'] as String,
          title: map['title'] as String,
          artist: (map['artist'] as String?)?.isNotEmpty == true
              ? map['artist'] as String
              : null,
          album: (map['album'] as String?)?.isNotEmpty == true
              ? map['album'] as String
              : null,
          artUri: (map['artUri'] as String).isNotEmpty
              ? Uri.tryParse(map['artUri'] as String)
              : null,
          duration:
              Duration(milliseconds: (map['duration'] as num).toInt()),
          extras:
              Map<String, dynamic>.from(map['extras'] as Map? ?? {}),
        );
      }).toList();

      final clampedIndex =
          savedIndex.clamp(0, queue.isEmpty ? 0 : queue.length - 1);
      return (queue: queue, index: clampedIndex);
    } catch (e) {
      if (kDebugMode) print('Load queue error: $e');
      return (queue: <MediaItem>[], index: 0);
    }
  }

  // ─── LoadPlaylist ────────────────────────────────────────────────────────────
  Future<void> _onLoadPlaylist(
      LoadPlaylistEvent event, Emitter<PlayerState> emit) async {
    await _audioHandler.updateQueue(event.playlist);
    await _audioHandler.skipToQueueItem(event.startIndex);
    await _audioHandler.play();

    if (event.userId != null) await _persistQueue(event.userId!);
  }

  // ─── PlayNext: chen bài vào NGAY SAU bài đang phát ──────────────────────────
  // FIX: cũ dùng addQueueItem → thêm vào CUỐI (sai)
  // Đúng: insertQueueItem tại currentIndex + 1
  Future<void> _onPlayNext(
      PlayNextEvent event, Emitter<PlayerState> emit) async {
    final newItem = event.item;
    final queue = _audioHandler.queue.value;
    final currentItem = _audioHandler.mediaItem.value;

    // Bài này đang phát → bỏ qua
    if (currentItem?.id == newItem.id) return;

    // Nếu đã có trong queue → xóa trước để tránh trùng
    final existingIndex =
        queue.indexWhere((item) => item.id == newItem.id);
    if (existingIndex != -1) {
      await _audioHandler.removeQueueItemAt(existingIndex);
    }

    final updatedQueue = _audioHandler.queue.value;

    if (currentItem == null) {
      // Chưa có bài nào → thêm vào đầu và phát luôn
      await _audioHandler.addQueueItem(newItem);
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioHandler.skipToQueueItem(0);
      await _audioHandler.play();
    } else {
      // ✅ Insert ngay sau vị trí bài đang phát
      final currentIndex =
          updatedQueue.indexWhere((item) => item.id == currentItem.id);
      final insertAt = (currentIndex != -1 ? currentIndex : 0) + 1;
      await _audioHandler.insertQueueItem(insertAt, newItem);
    }

    if (event.userId != null) await _persistQueue(event.userId!);
  }

  // ─── RemoveFromQueue ─────────────────────────────────────────────────────────
  Future<void> _onRemoveFromQueue(
      RemoveFromQueueEvent event, Emitter<PlayerState> emit) async {
    final queue = _audioHandler.queue.value;
    if (event.index >= 0 && event.index < queue.length) {
      if (_audioHandler.mediaItem.value?.id == queue[event.index].id) return;
      await _audioHandler.removeQueueItemAt(event.index);
    }
    if (event.userId != null) await _persistQueue(event.userId!);
  }

  // ─── PrioritizeSong ──────────────────────────────────────────────────────────
  Future<void> _onPrioritizeSong(
      PrioritizeSongEvent event, Emitter<PlayerState> emit) async {
    final queue = _audioHandler.queue.value;
    final currentMediaItem = _audioHandler.mediaItem.value;
    if (currentMediaItem == null) return;

    final currentPlayingIndex =
        queue.indexWhere((item) => item.id == currentMediaItem.id);

    if (event.index != currentPlayingIndex &&
        event.index >= 0 &&
        event.index < queue.length) {
      final itemToMove = queue[event.index];
      await _audioHandler.removeQueueItemAt(event.index);
      final newCurrentIndex = _audioHandler.queue.value
          .indexWhere((item) => item.id == currentMediaItem.id);
      await _audioHandler.insertQueueItem(newCurrentIndex + 1, itemToMove);
    }

    if (event.userId != null) await _persistQueue(event.userId!);
  }

  // ─── ResetPlayer (logout) ────────────────────────────────────────────────────
  // FIX: bỏ skipToQueueItem/seek sau updateQueue([]) → gây exception
  Future<void> _onResetPlayer(
      ResetPlayerEvent event, Emitter<PlayerState> emit) async {
    try {
      await _audioHandler.stop();
      await _audioHandler.updateQueue([]);
      emit(const PlayerInitial());
    } catch (e) {
      if (kDebugMode) print('Reset Player Error: $e');
      emit(const PlayerInitial());
    }
  }

  // ─── RestoreQueue (sau khi đăng nhập lại) ───────────────────────────────────
  Future<void> _onRestoreQueue(
      RestoreQueueEvent event, Emitter<PlayerState> emit) async {
    try {
      final (:queue, :index) = await _loadPersistedQueue(event.userId);
      if (queue.isEmpty) return;

      await _audioHandler.updateQueue(queue);
      await _audioHandler.skipToQueueItem(index);
      // Không tự play — chỉ khôi phục danh sách, user tự ấn play
    } catch (e) {
      if (kDebugMode) print('Restore queue error: $e');
    }
  }

  // ─── InternalUpdate ──────────────────────────────────────────────────────────
  void _onInternalUpdate(
      InternalUpdateEvent event, Emitter<PlayerState> emit) {
    final playbackState = _audioHandler.playbackState.value;
    final mediaItem = _audioHandler.mediaItem.value;
    final queue = _audioHandler.queue.value;

    if (mediaItem == null || queue.isEmpty) {
      emit(const PlayerInitial());
      return;
    }

    final currentIndex =
        queue.indexWhere((item) => item.id == mediaItem.id);
    final duration = mediaItem.duration ?? Duration.zero;
    final position = playbackState.position;

    // Lưu vào lịch sử khi bài đang phát (không lưu khi pause)
    if (playbackState.playing && mediaItem != null) {
      _historyCubit.addSong(mediaItem);
    }

    final isShuffle = playbackState.shuffleMode == AudioServiceShuffleMode.all;
    final repeatModeState = playbackState.repeatMode == AudioServiceRepeatMode.none
        ? RepeatMode.none
        : playbackState.repeatMode == AudioServiceRepeatMode.one
            ? RepeatMode.one
            : RepeatMode.all;

    if (playbackState.playing) {
      emit(PlayerPlaying(
        song: mediaItem,
        position: position,
        duration: duration,
        queue: queue,
        currentIndex: currentIndex != -1 ? currentIndex : 0,
        isShuffle: isShuffle,
        repeatMode: repeatModeState,
      ));
    } else {
      emit(PlayerPaused(
        song: mediaItem,
        position: position,
        duration: duration,
        queue: queue,
        currentIndex: currentIndex != -1 ? currentIndex : 0,
        isShuffle: isShuffle,
        repeatMode: repeatModeState,
      ));
    }
  }

  @override
  Future<void> close() {
    _playerSubscription?.cancel();
    _mediaSubscription?.cancel();
    return super.close();
  }
}