import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart'; // Thêm để dùng kIsWeb

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  MyAudioHandler() {
    _init();
  }

  void _init() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Chỉ gán playlist nếy nó có bài hát (Tránh lỗi Null trên Web)
    // AudioPlayer sẽ tự động nhận playlist khi ta nạp bài hát đầu tiên vào.
    _player.setAudioSource(_playlist);
  }

  @override
  Future<void> play() async {
    // BẢO VỆ: Nếu danh sách rỗng thì không làm gì cả, tránh Crash
    if (_playlist.length == 0) return;
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playlist.length == 0) return;
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.length == 0) return;
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.length == 0) return;
    await _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length || _playlist.length == 0) return;
    
    try {
      await _player.seek(Duration.zero, index: index);
    } catch (e) {
      print("Lỗi Seek Audio Web: $e");
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    final audioSources = newQueue.map(_mediaItemToAudioSource).toList();
    
    // Tạm dừng player trước khi dọn dẹp để an toàn
    if (_player.playing) await _player.pause();
    
    await _playlist.clear(); 
    await _playlist.addAll(audioSources);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSources = mediaItems.map(_mediaItemToAudioSource).toList();
    await _playlist.addAll(audioSources);
    final currentQueue = queue.value;
    queue.add([...currentQueue, ...mediaItems]);
  }

  // --- CÁC HÀM QUẢN LÝ QUEUE ---

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await _playlist.add(_mediaItemToAudioSource(mediaItem));
    final newQueue = List<MediaItem>.from(queue.value)..add(mediaItem);
    queue.add(newQueue);
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    await _playlist.insert(index, _mediaItemToAudioSource(mediaItem));
    final newQueue = List<MediaItem>.from(queue.value)..insert(index, mediaItem);
    queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
    final newQueue = List<MediaItem>.from(queue.value)..removeAt(index);
    queue.add(newQueue);
  }

  // ---------------------------------------------------------------

  AudioSource _mediaItemToAudioSource(MediaItem item) {
    // FIX: Đảm bảo URI hợp lệ. Nếu item.id rỗng hoặc bất thường, thay bằng 1 khoảng lặng (hoặc link dự phòng)
    final url = item.id.isNotEmpty ? item.id : 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

    if (url.startsWith('assets/')) {
      return AudioSource.asset(url, tag: item);
    }
    return AudioSource.uri(Uri.parse(url), tag: item);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
}