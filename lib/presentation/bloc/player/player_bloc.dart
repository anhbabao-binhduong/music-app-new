import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'player_event.dart';
import 'player_state.dart';
import 'package:flutter/foundation.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioHandler _audioHandler;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _mediaSubscription;

  PlayerBloc(this._audioHandler) : super(const PlayerInitial()) {
    on<LoadPlaylistEvent>(_onLoadPlaylist);
    on<PlayEvent>((event, emit) => _audioHandler.play());
    on<PauseEvent>((event, emit) => _audioHandler.pause());
    on<NextEvent>((event, emit) => _audioHandler.skipToNext());
    on<PreviousEvent>((event, emit) => _audioHandler.skipToPrevious());
    on<SeekEvent>((event, emit) => _audioHandler.seek(event.position));
    on<SkipToIndexEvent>((event, emit) => _audioHandler.skipToQueueItem(event.index));
    on<PlayNextEvent>(_onPlayNext);
    on<InternalUpdateEvent>(_onInternalUpdate);
    
    // Đăng ký 2 sự kiện mới cho Queue
    on<RemoveFromQueueEvent>(_onRemoveFromQueue);
    on<PrioritizeSongEvent>(_onPrioritizeSong);

    _playerSubscription = _audioHandler.playbackState.listen((_) => add(const InternalUpdateEvent()));
    _mediaSubscription = _audioHandler.mediaItem.listen((_) => add(const InternalUpdateEvent()));
  }

  Future<void> _onLoadPlaylist(LoadPlaylistEvent event, Emitter<PlayerState> emit) async {
    await _audioHandler.updateQueue(event.playlist);
    await _audioHandler.skipToQueueItem(event.startIndex);
    await _audioHandler.play();
  }

  // --- 1. HÀM PHÁT TIẾP THEO (Chỉ thêm ngầm, KHÔNG reset nhạc) ---
  // --- 1. HÀM PHÁT TIẾP THEO (Chỉ thêm ngầm, KHÔNG reset nhạc) ---
  Future<void> _onPlayNext(PlayNextEvent event, Emitter<PlayerState> emit) async {
    final newItem = event.item;
    final queue = _audioHandler.queue.value;
    
    // Nếu bài đang hát trùng với bài muốn thêm thì bỏ qua
    if (_audioHandler.mediaItem.value?.id == newItem.id) return;

    // Tìm xem bài này đã có trong danh sách chưa, nếu có thì rút nó ra
    final existingIndex = queue.indexWhere((item) => item.id == newItem.id);
    if (existingIndex != -1) {
      await _audioHandler.removeQueueItemAt(existingIndex);
    }

    // GỌI HÀM ADD TRỰC TIẾP: Bài hát sẽ được nối vào đuôi mà nhạc vẫn chạy bình thường
    await _audioHandler.addQueueItem(newItem);

    // FIX CHÓT: Kích hoạt phát nhạc an toàn
    final isPlaying = _audioHandler.playbackState.value.playing;
    final isMediaItemNull = _audioHandler.mediaItem.value == null;

    if (!isPlaying || isMediaItemNull) {
      // Đợi 100ms để AudioSource kịp nạp bài hát vào bộ nhớ đệm
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (isMediaItemNull) {
        // Nếu là bài đầu tiên, ép nhảy tới vị trí 0
        await _audioHandler.skipToQueueItem(0);
      }
      await _audioHandler.play();
    }
  }

  // --- 2. HÀM XÓA BÀI HÁT (Rút ngầm, KHÔNG reset nhạc) ---
  Future<void> _onRemoveFromQueue(RemoveFromQueueEvent event, Emitter<PlayerState> emit) async {
    final queue = _audioHandler.queue.value;
    if (event.index >= 0 && event.index < queue.length) {
      // Chặn không cho xóa bài đang hát để tránh sập nhạc
      if (_audioHandler.mediaItem.value?.id == queue[event.index].id) return;
      
      // Gọi hàm rút bài trực tiếp
      await _audioHandler.removeQueueItemAt(event.index);
    }
  }

  // --- 3. HÀM ƯU TIÊN PHÁT BÀI HÁT ---
  Future<void> _onPrioritizeSong(PrioritizeSongEvent event, Emitter<PlayerState> emit) async {
    final queue = _audioHandler.queue.value;
    final currentMediaItem = _audioHandler.mediaItem.value;
    if (currentMediaItem == null) return;

    int currentPlayingIndex = queue.indexWhere((item) => item.id == currentMediaItem.id);
    
    if (event.index != currentPlayingIndex && event.index >= 0 && event.index < queue.length) {
      final itemToMove = queue[event.index];
      
      // B1: Rút bài đó ra khỏi danh sách
      await _audioHandler.removeQueueItemAt(event.index);
      
      // B2: Cập nhật lại vị trí bài đang hát (Vì rút 1 bài nên danh sách ngắn lại)
      int newCurrentIndex = _audioHandler.queue.value.indexWhere((item) => item.id == currentMediaItem.id);
      
      // B3: Chèn bài đó vào ngay sau bài đang hát
      await _audioHandler.insertQueueItem(newCurrentIndex + 1, itemToMove);
    }
  }

  void _onInternalUpdate(InternalUpdateEvent event, Emitter<PlayerState> emit) {
    final playbackState = _audioHandler.playbackState.value;
    final mediaItem = _audioHandler.mediaItem.value;
    final queue = _audioHandler.queue.value;

    if (mediaItem == null) return;

    final currentIndex = queue.indexWhere((item) => item.id == mediaItem.id);
    final duration = mediaItem.duration ?? Duration.zero;
    final position = playbackState.position;

    if (playbackState.playing) {
      emit(PlayerPlaying(
        song: mediaItem, position: position, duration: duration, queue: queue,
        currentIndex: currentIndex != -1 ? currentIndex : 0,
      ));
    } else {
      emit(PlayerPaused(
        song: mediaItem, position: position, duration: duration, queue: queue,
        currentIndex: currentIndex != -1 ? currentIndex : 0,
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